class_name MatchManager
extends RefCounted

signal match_connected(match_id: String, rival_name: String)
signal match_ready
signal match_started
signal match_ended(result: String, reason: String) # result: "VICTORY", "DEFEAT", "DRAW"
signal game_data_received(data: Dictionary)
signal attack_received(data: Dictionary)
signal opponent_left

var match_id: String = ""
var rival_name: String = ""
var is_host: bool = false # Not strictly host, but maybe useful
var _network: Node # NetworkClient

func _init(network: Node):
	_network = network
	_network.message_received.connect(_on_message_received)

func connect_to_match(p_match_id: String, p_rival_name: String):
	match_id = p_match_id
	rival_name = p_rival_name
	_network.send("connect-match", {"matchId": match_id})

func send_ping():
	_network.send("ping-match", {"matchId": match_id})

func send_game_data(data: Dictionary):
	_network.send("send-game-data", {"payload": data})

func leave_match():
	"""Sale de la partida sin enviar señales de victoria/derrota"""
	_network.send("quit-match", {"matchId": match_id})
	match_id = ""
	rival_name = ""

func _on_message_received(event: String, payload: Dictionary):
	var data = payload.get("data", {})
	
	match event:
		"connect-match":
			if payload.get("status") == "OK":
				match_connected.emit(match_id, rival_name)
				
		"players-ready":
			match_ready.emit()
			
		"match-start":
			match_started.emit()
			
		"receive-game-data":
			var content = data.get("payload", {})
			game_data_received.emit(content)
			
			# Check for attack
			if content.get("type") == "attack":
				attack_received.emit(content)
			
			# Check for custom defeat signal from opponent
			if content.get("type") == "defeat":
				print("🏆 [MATCH] ¡Oponente se rindió! Victoria")
				match_ended.emit("VICTORY", "opponent_surrendered")
			
		"game-ended":
			# Server dice que el juego terminó (el oponente ganó)
			print("💀 [MATCH] El oponente ganó la partida")
			match_ended.emit("DEFEAT", "opponent_won")
			
		"close-match":
			# Oponente se desconectó o abandonó
			print("🏆 [MATCH] ¡Oponente se desconectó! Victoria")
			opponent_left.emit()
			match_ended.emit("VICTORY", "opponent_disconnected")
			
		"match-accepted":
			# This might be handled in Lobby, but sometimes it flows here?
			# In original script, match-accepted sets match_id and connects.
			pass
