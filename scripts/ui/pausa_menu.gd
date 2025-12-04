extends CanvasLayer


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pausa()

func toggle_pausa():
	get_tree().paused = !get_tree().paused

	if get_tree().paused:
		$AnimationPlayer.play("blur")
		visible = true
	else:
		$AnimationPlayer.play_backwards("blur")
		await $AnimationPlayer.animation_finished
		visible = false


func _on_jugar_pressed():
	toggle_pausa()


func _on_reiniciar_pressed():
	await toggle_pausa()
	get_tree().reload_current_scene()


func _on_salir_pressed():
	Global.reset_player_data()
	toggle_pausa()
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
