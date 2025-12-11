extends CanvasLayer

@export var show_time: float = 2.5
@export var victory_text: String = "VICTORIA"
@export var defeat_text: String = "DERROTA"
@export var neutral_text: String = "PARTIDA"

@onready var label: Label = $CenterContainer/ColorRect/MarginContainer/VBoxContainer/Label

func show_result(result: String):
	var txt := neutral_text
	match result.to_upper():
		"VICTORY":
			txt = victory_text
			label.modulate = Color(0.2, 0.8, 0.2)
		"DEFEAT":
			txt = defeat_text
			label.modulate = Color(0.9, 0.2, 0.2)
		_:
			label.modulate = Color(0.9, 0.9, 0.9)
	label.text = txt
	_create_timer()

func _create_timer():
	var t := Timer.new()
	t.wait_time = show_time
	t.one_shot = true
	t.timeout.connect(_on_timer_timeout)
	add_child(t)
	t.start()

func _on_timer_timeout():
	# Al cerrar el popup de resultado, marcar al jugador como disponible
	# para que pueda enviar/recibir nuevas solicitudes de partida
	if has_node("/root/Network"):
		var network = get_node("/root/Network")
		if network.has_method("leave_match"):
			network.leave_match()  # Primero salir de la match
			await get_tree().create_timer(0.3).timeout
		if network.has_method("set_player_available"):
			network.set_player_available()  # Luego marcarse disponible
			print("✅ [MATCH_RESULT] Jugador marcado como disponible para nuevas partidas")
	queue_free()
