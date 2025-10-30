extends Control

@onready var left_button = $left
@onready var right_button = $right
@onready var jump_button = $jump
@onready var joystick = $joystick_attack

func _ready():
	_resize_ui()
	# inicial transparencia
	left_button.modulate = Color(1,1,1,0.5)
	right_button.modulate = Color(1,1,1,0.5)
	jump_button.modulate = Color(1,1,1,0.5)

func _resize_ui():
	var screen = get_viewport_rect().size
	var w = screen.x
	var h = screen.y
	var aspect = w / h

	# Márgenes dinámicos según relación de aspecto
	var margin_x : float
	var margin_y : float
	var spacing : float

	if aspect < 2.05: # ~18:9
		margin_x = h * 0.1
		margin_y = h * 0.12
		spacing = h * 0.05
	elif aspect < 2.25: # ~19.5:9–20:9
		margin_x = h * 0.12
		spacing = h * 0.065
		margin_y = h * 0.1
	else: # 21:9+
		margin_x = h * 0.13
		spacing = h * 0.075
		margin_y = h * 0.09


	# ----------------- POSICIONES (TouchScreenButton usa position) -----------------

	# LEFT
	left_button.position = Vector2(
		margin_x,
		h - left_button.texture_normal.get_height() - margin_y
	)

	# RIGHT
	right_button.position = Vector2(
		left_button.position.x + left_button.texture_normal.get_width() + spacing,
		left_button.position.y
	)

	_position_joystick()
	_position_jump()

func _position_joystick():
	var base = joystick.get_node("base") as TextureRect
	var base_size = base.size * joystick.scale  # tamaño real en pantalla

	var screen = get_viewport_rect().size
	var w = screen.x
	var h = screen.y
	var margin = h * 0.06  

	joystick.position = Vector2(
		w - base_size.x - margin,
		h - base_size.y - margin
	)

func _position_jump():
	var base = joystick.get_node("base") as TextureRect
	var base_size = base.size * joystick.scale
	var jump_tex = jump_button.texture_normal.get_size() * jump_button.scale

	var screen = get_viewport_rect().size
	var w = screen.x
	var h = screen.y

	var margin = h * 0.06 # mismo margen usado en joystick.position

	# Obtener el centro real del joystick en X
	var joystick_center_x = w - (base_size.x / 2) - margin
	var joystick_top_y = h - base_size.y - margin

	
	jump_button.position = Vector2(
		joystick_center_x - (jump_tex.x / 2),
		joystick_top_y - (jump_tex.y*1.4)
	)
	
# Eventos de transparencia
func _on_left_pressed(): 
	left_button.modulate = Color(1,1,1,1)
func _on_left_released(): 
	left_button.modulate = Color(1,1,1,0.5)

func _on_right_pressed(): 
	right_button.modulate = Color(1,1,1,1)
func _on_right_released(): 
	right_button.modulate = Color(1,1,1,0.5)

func _on_jump_pressed(): 
	jump_button.modulate = Color(1,1,1,1)
func _on_jump_released(): 
	jump_button.modulate = Color(1,1,1,0.5)
