extends Node

# Estado de combate
var player_current_attack = false

# Persistencia del jugador (sesión actual)
var player_health: int = 200
var player_max_health: int = 200
var player_coins: int = 0
var player_last_position: Vector2 = Vector2.ZERO

# Récords permanentes
var best_coins_record: int = 0
var total_enemies_killed: int = 0

# === GESTIÓN DE NIVELES ===
const FIRST_LEVEL := "res://scenes/levels/nicooo_level2.tscn"

var levels: Array = [
	"res://scenes/levels/angel_level.tscn",
	"res://scenes/levels/nicooo_level2.tscn",
	"res://scenes/levels/nivelbosque.tscn",
	"res://scenes/levels/test_level.tscn"
]

var _recent_levels: Array = []
const MAX_RECENT_HISTORY := 3

const STATS_SAVE_PATH := "user://player_stats.cfg"
var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	load_stats()
	randomize() # Asegurar aleatoriedad


func get_random_level() -> String:
	return _get_unique_random_scene(levels, _recent_levels)

func get_first_level() -> String:
	return FIRST_LEVEL


func _get_unique_random_scene(source_list: Array, history_list: Array) -> String:
	if source_list.is_empty():
		return ""
	
	# Si hay menos opciones que el historial + 1, no podemos evitar repeticiones estrictas
	# así que simplemente limpiamos el historial para evitar bucles infinitos
	if source_list.size() <= MAX_RECENT_HISTORY:
		history_list.clear()
	
	var available_scenes = []
	for scene in source_list:
		if not scene in history_list:
			available_scenes.append(scene)
	
	# Si por alguna razón nos quedamos sin opciones (caso borde), reseteamos historial
	if available_scenes.is_empty():
		history_list.clear()
		available_scenes = source_list.duplicate()
	
	var selected = available_scenes.pick_random()
	
	# Actualizar historial
	history_list.append(selected)
	if history_list.size() > MAX_RECENT_HISTORY:
		history_list.pop_front() # Eliminar el más antiguo
		
	return selected



func save_player_data(health: int, coins: int, position: Vector2) -> void:
	player_health = health
	player_coins = coins
	player_last_position = position


func reset_player_data() -> void:
	player_health = player_max_health
	player_coins = 0
	player_last_position = Vector2.ZERO


func update_stats_on_death(coins: int, enemies_killed: int) -> void:
	if coins > best_coins_record:
		best_coins_record = coins
	
	if enemies_killed > total_enemies_killed:
		total_enemies_killed = enemies_killed
	
	save_stats()


func get_stats() -> Dictionary:
	return {
		"best_coins": best_coins_record,
		"total_enemies_killed": total_enemies_killed
	}


func save_stats() -> void:
	_config.set_value("stats", "best_coins", best_coins_record)
	_config.set_value("stats", "total_enemies_killed", total_enemies_killed)
	
	var error := _config.save(STATS_SAVE_PATH)
	if error != OK:
		push_error("Error al guardar estadísticas: " + str(error))


func load_stats() -> void:
	var error := _config.load(STATS_SAVE_PATH)
	
	if error == OK:
		best_coins_record = _config.get_value("stats", "best_coins", 0)
		total_enemies_killed = _config.get_value("stats", "total_enemies_killed", 0)
