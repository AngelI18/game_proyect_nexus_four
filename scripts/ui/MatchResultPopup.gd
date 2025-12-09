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
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()
