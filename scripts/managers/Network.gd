extends Node2D

var ws := WebSocketPeer.new()
var conectado := false
var ping_timer := 0.0
const PING_INTERVAL := 10.0

var player_name := ""
var game_id := ""
var game_key := ""

signal mensaje_recibido(msg)
signal conectado_servidor()

func iniciar(nombre, gameId, gameKey):
	player_name = nombre
	game_id = gameId
	game_key = gameKey
	_conectar()

func _process(delta):
	if not conectado:
		return

	# Mantener viva la conexión
	ping_timer += delta
	if ping_timer >= PING_INTERVAL:
		ping_timer = 0.0
		_enviar({"event": "ping"})
		print("📡 [NETWORK] Ping keep-alive")

	ws.poll()
	while ws.get_available_packet_count() > 0:
		var msg := ws.get_packet().get_string_from_utf8()
		emit_signal("mensaje_recibido", msg)

	if ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		print("⚠️ [NETWORK] WebSocket cerrado. Reintentando...")
		conectado = false
		_reconectar()

func _conectar():
	var url := "ws://cross-game-ucn.martux.cl:4010/?gameId=%s&playerName=%s" % [game_id, player_name]
	print("🌐 [NETWORK] Conectando a:", url)
	var err := ws.connect_to_url(url)
	if err == OK:
		conectado = true
		emit_signal("conectado_servidor")
	else:
		print("❌ Error conectando. Reintento en 1 segundo…")
		await get_tree().create_timer(1).timeout
		_conectar()

func _reconectar():
	await get_tree().create_timer(1).timeout
	_conectar()

func _enviar(dic: Dictionary):
	if not conectado:
		return
	ws.send_text(JSON.stringify(dic))

func apagar():
	print("🛑 [NETWORK] Apagando conexión…")

	# detener ping/reintentos
	conectado = false
	ping_timer = 0.0

	# si el socket sigue abierto → cierre limpio
	if ws and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		print("📤 [NETWORK] Cerrando WebSocket con código 1000 (cierre limpio)")
		ws.close(1000, "User exit")
	else:
		print("⚠️ [NETWORK] Socket ya estaba cerrado")

	# 🔥 recrear el WebSocket tal como hacía Godot al destruir el nodo
	ws = WebSocketPeer.new()
