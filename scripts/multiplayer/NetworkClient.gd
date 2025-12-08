class_name NetworkClient
extends Node

signal connected_to_server
signal connection_closed
signal message_received(event: String, data: Dictionary)
signal error_occurred(msg: String)

var _ws: WebSocketPeer = WebSocketPeer.new()
var _url: String = ""
var _connected: bool = false
var _ping_timer: float = 0.0
const PING_INTERVAL: float = 10.0

func connect_to_url(url: String) -> void:
	_url = url
	var err = _ws.connect_to_url(_url)
	if err != OK:
		error_occurred.emit("No se pudo conectar a " + url)
		return
	_connected = true
	set_process(true)

func disconnect_from_server() -> void:
	_ws.close()
	_connected = false
	connection_closed.emit()
	set_process(false)

func send(event: String, data: Dictionary = {}) -> void:
	if not _connected or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	
	var payload = {
		"event": event,
		"data": data
	}
	_ws.send_text(JSON.stringify(payload))

func _process(delta):
	if not _connected:
		return

	_ws.poll()
	var state = _ws.get_ready_state()
	
	if state == WebSocketPeer.STATE_CLOSED:
		_connected = false
		connection_closed.emit()
		set_process(false)
		return

	while _ws.get_available_packet_count() > 0:
		var msg = _ws.get_packet().get_string_from_utf8()
		_handle_message(msg)
		
	# Keep-alive
	_ping_timer += delta
	if _ping_timer >= PING_INTERVAL:
		_ping_timer = 0.0
		send("ping")

func _handle_message(msg: String) -> void:
	var parsed = JSON.parse_string(msg)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("event"):
		return
	
	var event = parsed["event"]
	# Some events wrap data in "data", others might be flat. 
	# The server seems to consistently use "data".
	var data = parsed.get("data", {})
	
	# Special handling for initial connection event if needed, 
	# but generally just emit.
	if event == "connected-to-server":
		connected_to_server.emit()
	
	message_received.emit(event, parsed) # Pass full parsed object or just data? 
	# The original script used `data` sometimes as the full object and sometimes `data["data"]`.
	# Let's pass the full parsed object to be safe, or normalize it.
	# The original script did: `var data = JSON.parse_string(msg)` then `match data["event"]`.
