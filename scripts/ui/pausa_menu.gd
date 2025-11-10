# pausa_menu.gd.
extends CanvasLayer

# Esta función se llama automáticamente cuando ocurre una entrada
# que no fue manejada por otros elementos del juego.
# Es perfecta para el botón "Atrás" de Android.
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		# Si se presiona "Atrás" o "Escape", alternamos la pausa.
		toggle_pausa()

# Una función única para pausar y reanudar. Es más limpio.
func toggle_pausa():
	# Invertimos el estado de pausa actual.
	get_tree().paused = !get_tree().paused

	if get_tree().paused:
		# Si ahora está en pausa, mostramos el menú.
		$AnimationPlayer.play("blur")
		visible = true
	else:
		# Si ya no está en pausa, ocultamos el menú.
		$AnimationPlayer.play_backwards("blur")
		# Esperamos a que la animación termine antes de ocultarlo.
		await $AnimationPlayer.animation_finished
		visible = false

## --- SEÑALES DE LOS BOTONES ---

func _on_jugar_pressed():
	# El botón de jugar/reanudar simplemente llama a nuestra función principal.
	toggle_pausa()


func _on_reiniciar_pressed(): # Cambié el nombre para que coincida con tu escena
	# Primero, nos aseguramos de quitar la pausa del juego.
	get_tree().paused = false
	# Luego, recargamos la escena actual.
	get_tree().reload_current_scene()


func _on_salir_pressed():
	# IMPORTANTE: No usamos get_tree().quit() en móviles.
	# En su lugar, volvemos al menú principal.
	# Asegúrate de que la ruta a tu escena del menú sea correcta.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
