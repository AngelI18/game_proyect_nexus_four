class_name MultiplayerController
extends Node

# Singleton instance if needed, or just a node in the scene tree.
# For now, let's assume it's a node added to the scene or autoload.

signal connection_status_changed(connected: bool)
signal error_occurred(msg: String)

# Lobby Signals
signal player_list_updated(players: Dictionary)
signal invitation_received(invitation: Dictionary)
signal match_started(rival_name: String)

# Game Signals
signal game_message_received(data: Dictionary)
signal game_over(result: String, reason: String) # result: VICTORY, DEFEAT

var network: NetworkClient
var lobby: LobbyManager
var match_manager: MatchManager

var _game_id: String = "A"
var _game_key: String = "5NLQK3EMIZ"
var _player_name: String = "Player"

func _ready():
	network = NetworkClient.new()
	add_child(network)
	
	network.connected_to_server.connect(_on_connected)
	network.connection_closed.connect(_on_disconnected)
	network.error_occurred.connect(func(msg): error_occurred.emit(msg))
	
	# Initialize managers
	# We need player name before init lobby? 
	# Let's wait for setup.

func setup(player_name: String, game_id: String = "A", game_key: String = "5NLQK3EMIZ"):
	_player_name = player_name
	_game_id = game_id
	_game_key = game_key
	
	lobby = LobbyManager.new(network, _player_name)
	match_manager = MatchManager.new(network)
	
	# Connect Lobby Signals
	lobby.player_list_updated.connect(func(p): player_list_updated.emit(p))
	lobby.invitation_received.connect(func(i): invitation_received.emit(i))
	lobby.invitation_accepted.connect(_on_invitation_accepted)
	lobby.match_request_sent.connect(_on_match_request_sent)
	
	# Connect Match Signals
	match_manager.match_connected.connect(_on_match_connected)
	match_manager.match_ready.connect(_on_match_ready)
	match_manager.match_started.connect(_on_match_started)
	match_manager.match_ended.connect(_on_match_ended)
	match_manager.game_data_received.connect(func(d): game_message_received.emit(d))
	
	# Also listen for match-accepted in network directly if Lobby doesn't catch it?
	# Lobby handles invitations. MatchManager handles active match.
	# There is a bridge: when invitation is accepted (or sent and accepted by other), we get match_id.
	# We need to tell MatchManager to connect.
	
	network.message_received.connect(_on_global_message)

func connect_to_server():
	var url = "ws://cross-game-ucn.martux.cl:4010/?gameId=%s&playerName=%s" % [_game_id, _player_name.uri_encode()]
	network.connect_to_url(url)

func disconnect_from_server():
	network.disconnect_from_server()

# === Lobby Actions ===
func refresh_players():
	if lobby: lobby.refresh_players()

func send_invitation(player_id: String):
	if lobby: lobby.send_invitation(player_id)

func accept_invitation(match_id: String):
	if lobby: lobby.accept_invitation(match_id)

func reject_invitation(match_id: String):
	if lobby: lobby.reject_invitation(match_id)

# === Match Actions ===
func send_ready_ping():
	if match_manager: match_manager.send_ping()

func send_game_data(data: Dictionary):
	if match_manager: match_manager.send_game_data(data)

func notify_player_died():
	# Send defeat signal to opponent so they can claim victory
	if match_manager:
		match_manager.send_game_data({"type": "defeat"})
		match_manager.forfeit_match() # Or just forfeit?

func notify_player_won():
	if match_manager: match_manager.claim_victory()

func leave_match():
	if match_manager: match_manager.leave_match()

# === Internal Handlers ===
func _on_connected():
	# Auto login
	network.send("login", {"gameKey": _game_key})
	connection_status_changed.emit(true)

func _on_disconnected():
	connection_status_changed.emit(false)

func _on_global_message(event: String, payload: Dictionary):
	# Handle events that bridge Lobby and Match
	if event == "match-accepted":
		var data = payload.get("data", {})
		var match_id = data.get("matchId", "")
		var rival_name = data.get("playerName", "")
		
		# If we sent the invite, we get match-accepted.
		# We need to find rival name if missing.
		if rival_name == "" and data.has("playerId"):
			var pid = str(data["playerId"])
			if lobby and lobby.players.has(pid):
				rival_name = lobby.players[pid].get("name", "")
		
		_start_match_process(match_id, rival_name)

func _on_invitation_accepted(match_id: String, rival_name: String):
	_start_match_process(match_id, rival_name)

func _on_match_request_sent(match_id: String):
	# We wait for match-accepted
	pass

func _start_match_process(match_id: String, rival_name: String):
	match_manager.connect_to_match(match_id, rival_name)

func _on_match_connected(match_id: String, rival_name: String):
	# UI should show lobby/ready screen
	pass

func _on_match_ready():
	# Both connected. UI should enable "Ready" button or auto-ready.
	pass

func _on_match_started():
	match_started.emit(match_manager.rival_name)

func _on_match_ended(result: String, reason: String):
	game_over.emit(result, reason)
