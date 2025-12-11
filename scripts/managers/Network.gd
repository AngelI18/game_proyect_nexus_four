extends Node

# Replaces the old Network.gd with a SOLID implementation using helper classes.

signal connected_to_server
signal connection_closed
signal message_received(msg) # Legacy signal for compatibility if needed, but better use specific ones
signal error_occurred(msg: String)

# Lobby Signals
signal player_list_updated(players: Dictionary)
signal invitation_received(invitation: Dictionary)
signal match_started(rival_name: String)
signal match_connected(match_id: String, rival_name: String)
signal match_ready
signal opponent_left

# Game Signals
signal game_message_received(data: Dictionary)
signal game_over(result: String, reason: String) # result: VICTORY, DEFEAT
signal ataque_recibido(data: Dictionary)

const NetworkClientScript = preload("res://scripts/multiplayer/NetworkClient.gd")
const LobbyManagerScript = preload("res://scripts/multiplayer/LobbyManager.gd")
const MatchManagerScript = preload("res://scripts/multiplayer/MatchManager.gd")
var MatchResultScene = load("res://scenes/ui/match_result_popup.tscn")

var client # : NetworkClient
var lobby # : LobbyManager
var match_manager # : MatchManager

# Legacy variables for compatibility
var ws: WebSocketPeer:
	get: return client._ws if client else null
var my_id: String = ""
var match_id: String:
	get: return match_manager.match_id if match_manager else ""
	set(v): if match_manager: match_manager.match_id = v

var _game_id: String = "A"
var _game_key: String = "5NLQK3EMIZ"
var _player_name: String = ""
var _is_initialized: bool = false

# Sistema de ataques
var enemy_points: float = 0.0  # Puntos acumulados (pueden ser decimales)
const POINTS_FOR_ATTACK: int = 5  # Puntos necesarios para enviar ataque

func _ready():
	client = NetworkClientScript.new()
	add_child(client)
	
	client.connected_to_server.connect(_on_connected)
	client.connection_closed.connect(_on_disconnected)
	client.error_occurred.connect(func(msg): error_occurred.emit(msg))
	client.message_received.connect(_on_global_message)

func iniciar(nombre, gameId, gameKey):
	# Evitar múltiples inicializaciones
	if _is_initialized:
		print("[Network] Ya está inicializado, reconectando...")
		apagar()
		await get_tree().create_timer(0.5).timeout
	
	_player_name = nombre
	_game_id = gameId
	_game_key = gameKey
	
	lobby = LobbyManagerScript.new(client, _player_name, func(): return match_manager.match_id if match_manager else "")
	match_manager = MatchManagerScript.new(client)
	
	# Connect Lobby Signals
	lobby.player_list_updated.connect(func(p): player_list_updated.emit(p))
	lobby.invitation_received.connect(func(i): invitation_received.emit(i))
	lobby.invitation_accepted.connect(_on_invitation_accepted)
	lobby.match_request_sent.connect(_on_match_request_sent)
	
	# Connect Match Signals
	match_manager.match_connected.connect(func(mid, rname): match_connected.emit(mid, rname))
	match_manager.match_ready.connect(func(): match_ready.emit())
	match_manager.match_started.connect(_on_match_started)
	match_manager.match_ended.connect(_on_match_ended)
	match_manager.game_data_received.connect(func(d): game_message_received.emit(d))
	match_manager.attack_received.connect(_on_attack_received)
	match_manager.opponent_left.connect(func(): opponent_left.emit())
	
	_is_initialized = true
	_conectar()

func _conectar():
	var url = "ws://cross-game-ucn.martux.cl:4010/?gameId=%s&playerName=%s" % [_game_id, _player_name.uri_encode()]
	client.connect_to_url(url)

func apagar():
	print("[Network] Apagando conexión...")
	
	# Rechazar todas las invitaciones pendientes
	if lobby:
		lobby.reject_all_pending_invitations()
	
	# Resetear puntos de enemigos
	enemy_points = 0.0
	
	# Desconectar del servidor
	if client:
		client.disconnect_from_server()
	
	# Limpiar referencias
	if match_manager:
		match_manager.match_id = ""
		match_manager.rival_name = ""
	
	_is_initialized = false
	print("[Network] Conexión cerrada correctamente")

# === Legacy / Wrapper Methods ===
func _enviar(dic: Dictionary):
	# Legacy support for direct sending if needed, but prefer specific methods
	client.send(dic.get("event", ""), dic.get("data", {}))

# === Lobby Actions ===
func refresh_players():
	if lobby: lobby.refresh_players()

func send_invitation(player_id: String):
	if lobby: lobby.send_invitation(player_id)

func reject_invitation(p_match_id: String):
	if lobby: lobby.reject_invitation(p_match_id)

func reject_all_pending_invitations():
	"""Rechaza todas las invitaciones pendientes"""
	if lobby: lobby.reject_all_pending_invitations()

func accept_invitation(p_match_id: String):
	if lobby: lobby.accept_invitation(p_match_id)

# === Match Actions ===
func send_ready_ping():
	if match_manager: match_manager.send_ping()

func send_game_data(data: Dictionary):
	if match_manager and match_manager.match_id != "":
		match_manager.send_game_data(data)
	else:
		print("[NETWORK] No se puede enviar datos: no hay match activa")

func notify_player_died():
	"""Envía señal de derrota al oponente (NO abandona la match ni desmarca disponibilidad)"""
	if match_manager:
		print("[NETWORK] Enviando señal de derrota al oponente...")
		match_manager.send_game_data({"type": "defeat"})
		print("[NETWORK] Señal de derrota enviada")

func leave_match():
	if match_manager: match_manager.leave_match()

func set_player_available():
	if lobby: lobby.set_player_available()

# === Sistema de Ataques ===
func send_attack(damage: int = 10):
	"""Envía un ataque al oponente"""
	var payload := {
		"type": "attack",
		"player": _player_name,
		"damage": damage
	}
	
	print("[ATTACK] Enviando ataque:", payload)
	send_game_data(payload)

func add_enemy_points(points: int):
	"""Agrega puntos por enemigo muerto y envía ataque si llega al límite"""
	# Verificar que hay una partida activa
	if not match_manager or match_manager.match_id == "":
		print("💠 [NETWORK] No hay partida activa, puntos no acumulados")
		return
	
	enemy_points += points
	print("💠 [NETWORK] Puntos de enemigos: ", enemy_points, "/", POINTS_FOR_ATTACK)
	
	if enemy_points >= POINTS_FOR_ATTACK:
		print("⚔️ [NETWORK] ¡5 PUNTOS ALCANZADOS! Enviando ataque...")
		send_attack()
		enemy_points = 0.0  # Resetear puntos

func enemy_killed():
	"""Método legacy - usar add_enemy_points() en su lugar"""
	add_enemy_points(1)

# === Internal Handlers ===
func _on_connected():
	client.send("login", {"gameKey": _game_key})
	connected_to_server.emit()

func _on_disconnected():
	# Si se desconecta, limpiamos la match activa
	if match_manager:
		match_manager.match_id = ""
		match_manager.rival_name = ""

	connection_closed.emit()

func _on_global_message(event: String, payload: Dictionary):
	# Emit legacy signal
	message_received.emit(JSON.stringify(payload))
	
	if event == "connected-to-server":
		if payload.has("data") and payload["data"].has("playerId"):
			my_id = str(payload["data"]["playerId"])

	if event == "match-accepted":
		var data = payload.get("data", {})
		var m_id = data.get("matchId", "")
		var rival_name = data.get("playerName", "")
		
		# Si no viene el nombre, buscarlo en invitaciones
		if rival_name == "" and lobby:
			for inv in lobby.invitations:
				if inv.get("matchId") == m_id:
					rival_name = inv.get("name", "")
					break
		
		# Fallback: buscar en players
		if rival_name == "" and data.has("playerId"):
			var pid = str(data["playerId"])
			if lobby and lobby.players.has(pid):
				rival_name = lobby.players[pid].get("name", "")
		
		print("[NETWORK] match-accepted - Match: ", m_id, ", Rival: ", rival_name)
		_start_match_process(m_id, rival_name)

func _on_invitation_accepted(p_match_id: String, rival_name: String):
	_start_match_process(p_match_id, rival_name)

func _on_match_request_sent(_match_id: String):
	pass

func _start_match_process(p_match_id: String, rival_name: String):
	match_manager.connect_to_match(p_match_id, rival_name)

func _on_match_started():
	match_started.emit(match_manager.rival_name)

func _on_attack_received(attack_data: Dictionary):
	# Validar que sigue habiendo match activa
	if not match_manager or match_manager.match_id == "":
		print("[NETWORK] Ataque ignorado: no hay match activa")
		return
	
	print("[NETWORK] ATAQUE RECIBIDO")
	print("[NETWORK] Jugador: ", attack_data.get("player", "desconocido"))
	print("[NETWORK] Daño: ", attack_data.get("damage", 0))
	print("[NETWORK] Datos completos: ", attack_data)
	ataque_recibido.emit(attack_data)

func _on_match_ended(result: String, reason: String):
	print("[NETWORK] Partida terminada: ", result, " - ", reason)
	_show_match_result_popup(result)
	game_over.emit(result, reason)
	
	# Solo salir de la match (NO marcar disponible automáticamente)
	leave_match()

func _show_match_result_popup(result: String):
	if not MatchResultScene:
		return
	var popup = MatchResultScene.instantiate()
	if popup and get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(popup)
		if popup.has_method("show_result"):
			popup.show_result(result)
