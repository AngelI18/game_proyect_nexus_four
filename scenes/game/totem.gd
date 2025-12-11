extends Area2D

# --- CONFIGURACIÓN ---
@export var boss_scene: PackedScene 
@export var spawn_marker_path: NodePath 

# NUEVO: Aquí pondrás la ruta del siguiente nivel (ej: "res://scenes/levels/level_2.tscn")
@export_file("*") var next_level_path: String 

@onready var ui_panel = $Invocar/PanelContainer
@onready var btn_invocar = $Invocar/PanelContainer/VBoxContainer/BtnInvocar
@onready var animation = $AnimatedSprite2D

var boss_summoned = false 
var spawn_point_node = null

func _ready():
	ui_panel.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if btn_invocar:
		btn_invocar.pressed.connect(_on_invocar_pressed)
		
	if animation: animation.play("idle")

func _on_body_entered(body):
	if body.is_in_group("player") and not boss_summoned:
		ui_panel.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		ui_panel.visible = false

func _on_invocar_pressed():
	if boss_summoned: return
	spawn_boss()
	ui_panel.visible = false
	boss_summoned = true
	if animation: animation.play("deactivated")
	modulate = Color(0.5, 0.5, 0.5)

func spawn_boss():
	if not boss_scene:
		print("ERROR: ¡No has asignado la escena del Boss!")
		return
		
	var new_boss = boss_scene.instantiate()
	
	# Posicionar al Boss
	var spawn_pos = global_position 
	if spawn_marker_path:
		spawn_point_node = get_node_or_null(spawn_marker_path)
		if spawn_point_node:
			spawn_pos = spawn_point_node.global_position
	
	new_boss.global_position = spawn_pos
	
	# --- NUEVO: CONECTAR LA SEÑAL DE MUERTE ---
	# Cuando el boss emita "enemy_died", ejecutamos _on_boss_defeated en este script
	new_boss.enemy_died.connect(_on_boss_defeated)
	
	get_parent().call_deferred("add_child", new_boss)
	print("¡BOSS INVOCADO!")

# --- NUEVA FUNCIÓN PARA CAMBIAR NIVEL ---
func _on_boss_defeated(coins_reward):
	print("¡Boss derrotado! Cambiando de nivel en 4 segundos...")
	
	# 1. Esperamos un poco para ver la animación de muerte y agarrar las monedas
	await get_tree().create_timer(4.0).timeout
	
	# 2. Verificamos si hay un nivel asignado
	if next_level_path != "":
		# Opcional: Guardar partida antes de cambiar
		# Global.save_game() 
		
		get_tree().change_scene_to_file(next_level_path)
	else:
		print("ERROR: No has asignado el 'next_level_path' en el Inspector del Tótem")
