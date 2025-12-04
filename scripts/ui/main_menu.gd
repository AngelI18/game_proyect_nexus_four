extends Control

# Referencias a labels de estadísticas (conecta estos nodos en el editor)
@onready var best_coins_label: Label = $Container/GridContainer/BestCoinValue
@onready var deaths_label: Label = $StatsPanel/StatsVBox/DeathsValue if has_node("StatsPanel/StatsVBox/DeathsValue") else null
@onready var enemies_label: Label = $Container/GridContainer/deaths_enemy_label


func _ready() -> void:
	_update_stats_display()


func _update_stats_display() -> void:
	"""Actualiza la UI con las estadísticas desde Global"""
	var stats = Global.get_stats()
	
	if best_coins_label:
		best_coins_label.text = str(stats.get("best_coins", 0))
	
	if deaths_label:
		deaths_label.text = str(stats.get("total_deaths", 0))
	
	if enemies_label:
		enemies_label.text = str(stats.get("total_enemies_killed", 0))


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/angel_level.tscn")


func _on_multi_player_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Multijugador.tscn")


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/opciones.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
