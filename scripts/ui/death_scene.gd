extends CanvasLayer

# Configuración de cámara del jugador
var camera_zoom: Vector2 = Vector2(2, 2)
var camera_limit_left: int = -425
var camera_limit_top: int = -197
var camera_limit_right: int = 0
var camera_limit_bottom: int = 312
var camera_position: Vector2 = Vector2.ZERO

@onready var camera = $Camera2D
@onready var death_label = $death_label
@onready var bg = $BG
@onready var vbox_container = $VBoxContainer

func _ready():
	# Configurar cámara
	_setup_camera()
	
	# Iniciar elementos invisibles
	bg.color = Color(0, 0, 0, 0)
	death_label.modulate.a = 0
	
	# Ocultar botones hasta que termine la animación
	vbox_container.visible = false
	
	
	_animate_death()

func setup_camera_data(zoom: Vector2, limit_l: int, limit_t: int, limit_r: int, limit_b: int, pos: Vector2):
	camera_zoom = zoom
	camera_limit_left = limit_l
	camera_limit_top = limit_t
	camera_limit_right = limit_r
	camera_limit_bottom = limit_b
	camera_position = pos
	
	if camera:
		_setup_camera()

func _setup_camera():
	if not camera:
		return
	
	camera.enabled = true
	camera.zoom = camera_zoom
	camera.limit_left = camera_limit_left
	camera.limit_top = camera_limit_top
	camera.limit_right = camera_limit_right
	camera.limit_bottom = camera_limit_bottom
	camera.global_position = camera_position
	camera.limit_smoothed = true

func _animate_death():
	# Crear tween para la animación
	var tween = create_tween()
	tween.set_parallel(true)
	
	# BG aparece gradualmente hasta 70% de opacidad en 3 segundos
	tween.tween_property(bg, "color", Color(0, 0, 0, 0.7), 3.0)
	
	# DEATH label aparece gradualmente hasta opacidad total en 3 segundos
	tween.tween_property(death_label, "modulate:a", 1.0, 3.0)
	
	# Esperar a que termine la animación
	await tween.finished
	
	# Mostrar botones después de la animación
	_show_buttons()

func _show_buttons():
	"""Muestra los botones con una animación de fade in"""
	vbox_container.modulate.a = 0
	vbox_container.visible = true
	
	var tween = create_tween()
	tween.tween_property(vbox_container, "modulate:a", 1.0, 0.5)

func _hide_death_scene():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out de todos los elementos
	tween.tween_property(bg, "color", Color(0, 0, 0, 0), 0.5)
	tween.tween_property(death_label, "modulate:a", 0.0, 0.5)
	tween.tween_property(vbox_container, "modulate:a", 0.0, 0.5)
	
	# Esperar a que termine la animación
	await tween.finished
	
	# Ocultar completamente
	visible = false


func off_camera() -> void:
	if camera:
		camera.enabled = false	


func _on_reiniciar_pressed() -> void:
	# Reiniciar datos del jugador ANTES de recargar
	Global.reset_player_data()
	# Ocultar la escena con animación
	await _hide_death_scene()
	off_camera()
	# Recargar la escena actual
	get_tree().reload_current_scene()

func _on_menu_principal_pressed() -> void:
	# Reiniciar datos del jugador ANTES de cambiar escena
	Global.reset_player_data()
	# Ocultar la escena con animación
	await _hide_death_scene()
	off_camera()
	# Ir al menú principal
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
