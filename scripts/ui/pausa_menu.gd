extends CanvasLayer
@onready var bg = $ColorRect
@onready var btn_reiniciar = $Panel/Reiniciar  # Referencia al botón reiniciar

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


func _is_in_multiplayer_match() -> bool:
	"""Verifica si el jugador está en una partida multijugador activa"""
	if has_node("/root/Network"):
		var network = get_node("/root/Network")
		if network.match_id != "":
			return true
	return false


func _hide_hud():
	"""Oculta el HUD del juego"""
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = false
		print("👁️ [PAUSE] HUD ocultado")


func _show_hud():
	"""Muestra el HUD del juego"""
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = true
		print("👁️ [PAUSE] HUD mostrado")

func toggle_pausa():
	# Comportamiento normal de pausa (tanto single como multiplayer)
	get_tree().paused = !get_tree().paused
	
	if get_tree().paused:
		_hide_hud()
		# Deshabilitar reiniciar si estamos en multiplayer
		if _is_in_multiplayer_match() and btn_reiniciar:
			btn_reiniciar.disabled = true
			btn_reiniciar.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			if btn_reiniciar:
				btn_reiniciar.disabled = false
				btn_reiniciar.modulate = Color(1, 1, 1, 1)
		$AnimationPlayer.play("blur")
		visible = true
	else:
		_show_hud()
		$AnimationPlayer.play_backwards("blur")
		await $AnimationPlayer.animation_finished
		visible = false


func _on_jugar_pressed():
	bg.visible = false
	# Siempre mostrar el HUD al presionar Jugar
	_show_hud()
	toggle_pausa()


func _on_reiniciar_pressed():
	# Reiniciar datos del jugador ANTES de recargar
	Global.reset_player_data()
	# Siempre mostrar HUD antes de recargar (se verá en la nueva escena)
	_show_hud()
	await toggle_pausa()
	bg.visible = false
	get_tree().reload_current_scene()


func _on_salir_pressed():
	# Si estamos en multijugador, enviar señal de derrota y salir
	if _is_in_multiplayer_match():
		print("🏳️ [PAUSE] Abandonando partida - Enviando señal de derrota")
		if has_node("/root/Network"):
			var network = get_node("/root/Network")
			if network.has_method("notify_player_died"):
				network.notify_player_died()  # Envía defeat al oponente
				await get_tree().create_timer(0.3).timeout
			if network.has_method("leave_match"):
				network.leave_match()  # Sale de la match
				await get_tree().create_timer(0.3).timeout
			if network.has_method("set_player_available"):
				network.set_player_available()  # Se marca disponible
				print("✅ [PAUSE] Jugador marcado como disponible")
		_show_hud()
	
	Global.reset_player_data()
	# Despausar
	if get_tree().paused:
		get_tree().paused = false
	toggle_pausa()
	bg.visible = false
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
