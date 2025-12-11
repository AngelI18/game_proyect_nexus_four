extends Area2D

# --- CONFIGURACIÓN ---
# Aquí arrastrarás tu escena "pig_boss.tscn" en el Inspector
@export var boss_scene: PackedScene

# Aquí asignarás el Marker2D que creaste en el nivel
# Nota: Como el Marker está fuera del Totem, lo buscaremos de forma especial o lo asignaremos
@export var spawn_marker_path: NodePath 

@onready var ui_panel = $Invocar/PanelContainer
@onready var btn_invocar = $Invocar/PanelContainer/VBoxContainer/BtnInvocar # Asegúrate de la ruta
@onready var animation = $AnimatedSprite2D # Si tienes animación de tótem brillando

var boss_summoned = false # Para que no lo invoques dos veces
var spawn_point_node = null

func _ready():
	ui_panel.visible = false
	
	# Conectamos las señales del área (si no lo hiciste en el editor)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Conectar el botón
	if btn_invocar:
		btn_invocar.pressed.connect(_on_invocar_pressed)
		
	# Iniciar animación idle del totem
	animation.play("idle")

func _on_body_entered(body):
	if body.is_in_group("player") and not boss_summoned:
		ui_panel.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		ui_panel.visible = false

func _on_invocar_pressed():
	if boss_summoned: return
	
	spawn_boss()
	
	# Ocultar UI y desactivar totem
	ui_panel.visible = false
	boss_summoned = true

func spawn_boss():
	if not boss_scene:
		print("ERROR: ¡No has asignado la escena del Boss en el Inspector!")
		return
		
	# Instanciar al Boss
	var new_boss = boss_scene.instantiate()
	
	# Encontrar dónde ponerlo
	var spawn_pos = global_position # Por defecto: en el totem
	
	if spawn_marker_path:
		spawn_point_node = get_node_or_null(spawn_marker_path)
		if spawn_point_node:
			spawn_pos = spawn_point_node.global_position
	
	new_boss.global_position = spawn_pos
	
	# Agregar al Boss al NIVEL (no al tótem, o se moverá con él)
	# 'get_parent()' suele ser el Nivel donde pusiste el Tótem
	get_parent().call_deferred("add_child", new_boss)
	
	print("¡LA CALAMIDAD HA DESPERTADO!")
