extends CanvasLayer
@onready var bg = $ColorRect

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		# Evitar pausar en menús (Main Menu, Multijugador, Opciones)
		if not get_tree().current_scene:
			return
			
		var scene_path = get_tree().current_scene.scene_file_path.to_lower()
		if "main_menu.tscn" in scene_path or \
		   "multijugador.tscn" in scene_path or \
		   "opciones.tscn" in scene_path:
			return

		bg.visible = true
		toggle_pausa()

func toggle_pausa():
	# Si estamos en multijugador, no pausar el juego, solo mostrar el menú
	var is_multiplayer = false
	if "Network" in get_tree().get_nodes_in_group("singleton"):
		is_multiplayer = Network.match_id != ""
	elif Engine.has_singleton("Network"):
		is_multiplayer = Engine.get_singleton("Network").match_id != ""
	else:
		is_multiplayer = false

	if is_multiplayer:
		# Solo mostrar el menú, no pausar
		$AnimationPlayer.play("blur")
		visible = !visible
		bg.visible = visible
	else:
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			$AnimationPlayer.play("blur")
			visible = true
		else:
			$AnimationPlayer.play_backwards("blur")
			await $AnimationPlayer.animation_finished
			visible = false


func _on_jugar_pressed():
	bg.visible = false
	toggle_pausa()


func _on_reiniciar_pressed():
	# Reiniciar datos del jugador ANTES de recargar
	Global.reset_player_data()
	await toggle_pausa()
	bg.visible = false
	get_tree().reload_current_scene()


func _on_salir_pressed():
	Global.reset_player_data()
	toggle_pausa()
	bg.visible = false
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
