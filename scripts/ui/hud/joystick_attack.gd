extends Control

signal attack_triggered(direction: Vector2)
signal direction_changed(direction: Vector2)

@onready var base = $base
@onready var stick = $stick

var is_pressed := false
var center_pos := Vector2.ZERO
var max_distance := 0 #radio de la base, en _ready() se define
var current_direction := Vector2.ZERO
var dead_zone :=0.15 #para la presiciond el la gente

func _ready() -> void:
	base.position = Vector2.ZERO
	var base_texture_size = base.texture.get_size()
	#joystick toma tamaño de la base
	custom_minimum_size = base.size
	size = base.size
	
	center_pos = center_pos + (base.size/2)
	#transparencia para stick y base
	stick.modulate = Color(1,1,1,0.5)
	base.modulate = Color(1,1,1,0.5)
	
	#radio maximo que usara el stick
	max_distance = (base.size.x/2)*0.95 #uso del 95 porciento de la base
	
	await get_tree().process_frame
	var tween = create_tween()
	tween.tween_property(stick, "position", center_pos - (stick.size / 2), 0.0)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and _is_point_inside(event.position):
			_on_touch_start(event.position)
		elif !event.pressed and is_pressed:
			_on_touch_end()
			
	if event is InputEventScreenDrag and is_pressed:
		_on_touch_drag(event.position)

func _on_touch_start(touch_pos : Vector2):
	is_pressed = true
	stick.modulate = Color(1,1,1,1)
	base.modulate = Color(1,1,1,1)
	_update_stick_position(touch_pos)

func _on_touch_drag(touch_pos: Vector2):
	_update_stick_position(touch_pos)
	
func _on_touch_end():
	is_pressed = false
	
	if current_direction.length() > dead_zone:
		emit_signal("attack_triggered", current_direction)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(stick, "position",center_pos-(stick.size/2),0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_property(stick, "modulate", Color(1, 1, 1, 0.5), 0.15)
	tween.tween_property(base, "modulate", Color(1, 1, 1, 0.5), 0.15)
	
	current_direction = Vector2.ZERO
	emit_signal("direction_changed",Vector2.ZERO)

func _update_stick_position(touch_pos: Vector2):
	
	var local_touch = touch_pos - global_position
	
	var offset = local_touch - center_pos
	var distance = offset.length()
	
	if distance > max_distance:
		offset = offset.normalized()
		distance = max_distance
	
	stick.position = center_pos + offset - (stick.size/2)
	
	var normalized_distance = distance / max_distance
	
	if normalized_distance > dead_zone:
		current_direction = offset.normalized()
		emit_signal("direction_changed", Vector2.ZERO)

func _is_point_inside(point: Vector2) -> bool:
	var rect = Rect2(global_position, size)
	return rect.has_point(point)

func get_direction() -> Vector2:
	return current_direction

func get_flip_direction() -> int:
	if current_direction.x < -0.3:
		return -1
	elif current_direction.x > 0.3:
		return 1
	return 0
