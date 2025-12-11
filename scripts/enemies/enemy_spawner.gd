extends Node2D

@export var enemy_scene: PackedScene 
@export var enemy_types: Array[PackedScene]

var max_enemies = 10
var current_enemies = 0

# Referencia a nuestra caja visual
@onready var zona = $ZonaAparicion

# Array de escenas de enemigos regulares (sin bosses)
var regular_enemy_scenes = [
	preload("res://scenes/charactes/enemies/buitre.tscn"),
	preload("res://scenes/charactes/enemies/buoh.tscn"),
	preload("res://scenes/charactes/enemies/jabali_carga.tscn"),
	preload("res://scenes/charactes/enemies/nutria.tscn")
]

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	# Cuenta solo enemigos de scenes/charactes/enemies que no terminen en _boss
	var all_enemies = get_tree().get_nodes_in_group("enemigos")
	var regular_enemies = []
	
	for enemy in all_enemies:
		if enemy != null and enemy.scene_file_path.find("scenes/charactes/enemies") != -1:
			if not enemy.scene_file_path.ends_with("_boss.tscn"):
				regular_enemies.append(enemy)
	
	current_enemies = regular_enemies.size()
	if current_enemies >= max_enemies:
		return 
	spawn_enemy()

func spawn_enemy():
	var new_enemy
	
	# Prioriza el array de escenas regulares si está disponible
	if regular_enemy_scenes.size() > 0:
		new_enemy = regular_enemy_scenes.pick_random().instantiate()
	elif enemy_types.size() > 0:
		new_enemy = enemy_types.pick_random().instantiate()
	elif enemy_scene:
		new_enemy = enemy_scene.instantiate()
	else:
		return

	# --- AQUÍ ESTÁ LA MAGIA ALEATORIA ---
	# 1. Obtenemos el tamaño y posición de la caja
	var rect_pos = zona.position
	var rect_size = zona.size
	
	# 2. Elegimos una X y una Y al azar dentro de ese tamaño
	var random_x = randf_range(0, rect_size.x)
	var random_y = randf_range(0, rect_size.y)
	
	# 3. Calculamos la posición final (Posición de la caja + Coordenada al azar)
	var spawn_pos = rect_pos + Vector2(random_x, random_y)
	
	new_enemy.position = spawn_pos
	# ------------------------------------

	add_child(new_enemy) 
	# OJO: Si prefieres que sean independientes del spawner usa:
	# get_parent().add_child(new_enemy)
	# new_enemy.global_position = global_position + spawn_pos
