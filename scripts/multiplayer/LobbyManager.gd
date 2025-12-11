class_name LobbyManager
extends RefCounted

signal player_list_updated(players: Dictionary)
signal invitation_received(invitation: Dictionary)
signal invitation_accepted(match_id: String, rival_name: String)
signal match_request_sent(match_id: String)

var players: Dictionary = {}
var invitations: Array = []
var _network: Node # NetworkClient
var _my_player_name: String
var _get_match_id_callback: Callable  # Callback para verificar si hay match activa

func _init(network: Node, my_player_name: String, get_match_id_callback: Callable = Callable()):
	_network = network
	_my_player_name = my_player_name
	_get_match_id_callback = get_match_id_callback
	_network.message_received.connect(_on_message_received)

func refresh_players():
	_network.send("online-players")

func send_invitation(player_id: String):
	_network.send("send-match-request", {"playerId": player_id})

func accept_invitation(match_id: String):
	_network.send("accept-match", {"matchId": match_id}) 
	_network.send("accept-match")

func reject_invitation(match_id: String):
	_network.send("reject-match")

func set_player_available():
	# Notificar al servidor que el jugador está disponible nuevamente
	_network.send("player-status", {"status": "AVAILABLE"})

func reject_all_pending_invitations():
	"""Rechaza todas las invitaciones pendientes antes de desconectar"""
	for inv in invitations:
		var match_id = inv.get("matchId", "")
		if match_id != "":
			_network.send("reject-match", {"matchId": match_id})
			print("[LOBBY] Rechazando invitación de: ", inv.get("name", "desconocido"))
	invitations.clear()

func _on_message_received(event: String, payload: Dictionary):
	var data = payload.get("data", {})
	
	# Ignorar eventos de conectados/desconectados si hay match activa
	if event in ["player-connected", "player-disconnected"]:
		if _get_match_id_callback.is_valid() and _get_match_id_callback.call() != "":
			return
	
	match event:
		"online-players":
			if payload.get("status") == "OK":
				_update_players(data)
		
		"player-connected":
			_add_player(data)
			
		"player-disconnected":
			_remove_player(data)
			
		"player-status-changed":
			_update_player_status(data)
			
		"match-request-received":
			_handle_invitation(data)
			
		"send-match-request":
			if payload.get("status") == "OK":
				match_request_sent.emit(data.get("matchId", ""))
				
		"accept-match":
			if payload.get("status") == "OK":
				var match_id = data.get("matchId", "")
				var rival_name = data.get("playerName", "")
				
				# Si no viene el nombre, buscarlo en las invitaciones guardadas
				if rival_name == "":
					for inv in invitations:
						if inv.get("matchId") == match_id:
							rival_name = inv.get("name", "")
							break
				
				# Fallback: buscar en players por playerId
				if rival_name == "" and data.has("playerId"):
					var pid = str(data["playerId"])
					if players.has(pid):
						rival_name = players[pid].get("name", "")
				
				print("[LOBBY] Aceptando invitación - Match: ", match_id, ", Rival: ", rival_name)
				invitation_accepted.emit(match_id, rival_name)

func _update_players(server_list: Array):
	players.clear()
	var my_name_lower = _my_player_name.to_lower()
	
	for j in server_list:
		var p_name = str(j.get("name", ""))
		if p_name.to_lower() == my_name_lower:
			continue
			
		var id = str(j.get("id", ""))
		if id == "": continue
		
		players[id] = {
			"name": p_name,
			"status": j.get("status", "UNKNOWN"),
			"game_name": j.get("game", {}).get("name", "Unknown")
		}
	player_list_updated.emit(players)

func _add_player(info: Dictionary):
	if info.has("id"):
		players[info["id"]] = {
			"name": info.get("name", "Desconocido"),
			"status": info.get("status", "UNKNOWN")
		}
		player_list_updated.emit(players)

func _remove_player(info: Dictionary):
	if info.has("id"):
		players.erase(info["id"])
		player_list_updated.emit(players)

func _update_player_status(info: Dictionary):
	var pid = info.get("playerId")
	if pid and players.has(pid):
		players[pid]["status"] = info.get("playerStatus", "UNKNOWN")
		player_list_updated.emit(players)

func _handle_invitation(data: Dictionary):
	var pid = str(data.get("playerId", ""))
	var mid = str(data.get("matchId", ""))
	var p_name = str(data.get("playerName", ""))
	
	print("[LOBBY] Invitación recibida - payload playerName: '", p_name, "', playerId: ", pid)
	
	# Si no viene el nombre en el payload, buscarlo en players
	if p_name == "" or p_name == "Desconocido":
		if players.has(pid):
			p_name = players[pid].get("name", "")
			print("[LOBBY] Nombre encontrado en players cache: '", p_name, "'")
		
		# Si aún no está en cache, hacer refresh y esperar
		if p_name == "" or p_name == "Desconocido":
			print("[LOBBY] Nombre no encontrado, haciendo refresh de jugadores...")
			refresh_players()
			# Esperar un momento para que llegue la respuesta
			await _network.get_tree().create_timer(0.3).timeout
			# Intentar de nuevo
			if players.has(pid):
				p_name = players[pid].get("name", "Jugador desconocido")
			else:
				p_name = "Jugador " + pid.substr(0, 4)
	
	var inv = {"playerId": pid, "matchId": mid, "name": p_name}
	invitations.append(inv)
	
	print("[LOBBY] Invitación guardada - Match: ", mid, ", Nombre: '", p_name, "'")
	invitation_received.emit(inv)
