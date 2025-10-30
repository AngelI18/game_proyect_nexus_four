extends Control

signal attack_triggered(direction: Vector2)
signal direction_changed(direction: Vector2)

@export var tolerance_zone: float = 50.0 
@export var dead_zone: float = 0.5

@onready var base = $base
@onready var stick = $stick

var active_touch_index := -1
var current_direction := Vector2.ZERO
var center_pos := Vector2.ZERO
var max_stick_radius := 0.0
var base_rect: Rect2

func _ready() -> void:
	custom_minimum_size = base.size
	size = base.size
	
	center_pos = base.size / 2
	
	max_stick_radius = (base.size.x / 2) * 0.95
	
	stick.modulate = Color(1, 1, 1, 0.5)
	base.modulate = Color(1, 1, 1, 0.5)
	
	await get_tree().process_frame
	
	base_rect = Rect2(global_position, size)


func _input(event: InputEvent) -> void:
	
	if event is InputEventScreenTouch:
		
		if event.pressed and active_touch_index == -1 and base_rect.has_point(event.position):
			active_touch_index = event.index
			_on_touch_start(event.position)
		
		elif not event.pressed and event.index == active_touch_index:
			active_touch_index = -1
			_on_touch_end()
			
	if event is InputEventScreenDrag and event.index == active_touch_index:
		
		var tolerant_rect = base_rect.grow(tolerance_zone)
		
		if tolerant_rect.has_point(event.position):
			_on_touch_drag(event.position)
		else:
			active_touch_index = -1
			_on_touch_end()


func _on_touch_start(touch_pos : Vector2):
	stick.modulate = Color(1, 1, 1, 1)
	base.modulate = Color(1, 1, 1, 1)
	_update_stick_position(touch_pos)

func _on_touch_drag(touch_pos: Vector2):
	_update_stick_position(touch_pos)
	
func _on_touch_end():

	if current_direction.length() > dead_zone:
		emit_signal("attack_triggered", current_direction)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(stick, "position", center_pos - (stick.size / 2), 0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_property(stick, "modulate", Color(1, 1, 1, 0.5), 0.15)
	tween.tween_property(base, "modulate", Color(1, 1, 1, 0.5), 0.15)
	
	current_direction = Vector2.ZERO
	emit_signal("direction_changed", Vector2.ZERO)

func _update_stick_position(touch_pos: Vector2):
	
	var local_touch = touch_pos - global_position
	var offset = local_touch - center_pos
	var distance = offset.length()
	
	var clamped_offset = offset
	if distance > max_stick_radius:
		clamped_offset = offset.normalized() * max_stick_radius
	
	stick.position = center_pos + clamped_offset - (stick.size / 2)
	
	var normalized_distance = clamped_offset.length() / max_stick_radius
	
	if normalized_distance > dead_zone:
		current_direction = clamped_offset.normalized()
		emit_signal("direction_changed", current_direction)
	else:
		current_direction = Vector2.ZERO
		emit_signal("direction_changed", Vector2.ZERO)


func get_direction() -> Vector2:
	return current_direction

func get_flip_direction() -> int:
	if current_direction.x < -0.3:
		return -1
	elif current_direction.x > 0.3:
		return 1
	return 0
