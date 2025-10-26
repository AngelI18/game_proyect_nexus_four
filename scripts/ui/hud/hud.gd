extends CanvasLayer

#iniciar algunas variable para evitar uso continuo de $
@onready var left_button = $Control/left
@onready var right_button = $Control/right
@onready var jump_button = $Control/jump
@onready var joystick = $Control/joystick_attack

#obtener informacion de resolucion
@onready var viewport_size = get_viewport().get_visible_rect().size

func _ready() -> void:
	#iniciar con transparencia
	left_button.modulate = Color(1,1,1,0.5)
	right_button.modulate = Color(1,1,1,0.5)
	jump_button.modulate = Color(1,1,1,0.5)
	#iniciar posiciones de botones
	_position_controls()

#definir posicion de botones por porcentaje en pantalla para compatibilidad en distintas pantallas
func _position_controls():
	var screen_width = viewport_size.x
	var screen_height = viewport_size.y
	
	left_button.position = Vector2(screen_width * 0.047, screen_height * 0.833)
	right_button.position = Vector2(screen_width * 0.14, screen_height * 0.833)
	jump_button.position = Vector2(screen_width*0.879,screen_height*0.6)
	joystick.position = Vector2(screen_width*0.86,screen_height*0.77)

#quitar transparencia de left_button
func _on_left_pressed() -> void:
	left_button.modulate =  Color(1,1,1,1)

#poner transparencia de left_button
func _on_left_released() -> void:
	left_button.modulate = Color(1,1,1,0.5)

#quitar transparencia de right_button
func _on_right_pressed() -> void:
	right_button.modulate = Color(1,1,1,1)

#poner transparencia de left_button
func _on_right_released() -> void:
	right_button.modulate = Color(1,1,1,0.5)

#quitar transparencia de jump_button
func _on_jump_pressed() -> void:
	jump_button.modulate = Color(1,1,1,1)

#poner transparencia de jump_button
func _on_jump_released() -> void:
	jump_button.modulate = Color(1,1,1,0.5)
