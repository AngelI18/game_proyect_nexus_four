extends CanvasLayer

@onready var bg = $ColorRect
@onready var btn_reiniciar = $PanelContainer/VBoxContainer/reiniciar
@onready var panel = $PanelContainer

func _ready() -> void:
	# 1. CORRECCIÓN IMPORTANTE: Asegurarnos de que el menú arranque oculto y despausado
	visible = false
	panel.modulate.a = 0.0
	bg.visible = false
	panel.visible = false
	# Aseguramos que este nodo siempre procese input, incluso en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS 

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		# 2. LÓGICA MÁS ROBUSTA:
		# En lugar de chequear nombres de archivos (que pueden fallar si cambias carpetas),
		# chequeamos si existe un nodo en el grupo "player".
		# Si NO hay jugador (estamos en menús), no hacemos nada.
		if get_tree().get_nodes_in_group("player").is_empty():
			return

		toggle_pausa()

func _is_in_multiplayer_match() -> bool:
	if has_node("/root/Network"):
		var network = get_node("/root/Network")
		# Aseguramos que match_id existe antes de comprobarlo para evitar errores
		if "match_id" in network and network.match_id != "":
			return true
	return false

func _hide_hud():
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = false

func _show_hud():
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = true

func toggle_pausa():
	var tree = get_tree()
	tree.paused = !tree.paused
	
	if tree.paused:
		_hide_hud()
		if _is_in_multiplayer_match() and btn_reiniciar:
			btn_reiniciar.disabled = true
			btn_reiniciar.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			if btn_reiniciar:
				btn_reiniciar.disabled = false
				btn_reiniciar.modulate = Color(1, 1, 1, 1)
		
		# Animación simple para que se vea mejor
		visible = true
		bg.visible = true
		panel.visible = true
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 1.0, 0.2)
		
	else:
		_show_hud()
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 0.0, 0.2)
		await tween.finished
		bg.visible = false
		panel.visible = false
		visible = false

func _on_jugar_pressed():
	_show_hud()
	toggle_pausa()

func _on_reiniciar_pressed():
	Global.reset_player_data()
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_load_saved_data"):
		player._load_saved_data() 
		player.position = Vector2.ZERO 
		print("[PAUSE] Jugador reiniciado")
	
	_show_hud()
	# Es importante despausar ANTES de recargar para evitar conflictos
	if get_tree().paused:
		toggle_pausa()
	
	var random_level = Global.get_random_level()
	if random_level != "":
		get_tree().change_scene_to_file(random_level)
	else:
		get_tree().reload_current_scene()

func _on_salir_pressed():
	if _is_in_multiplayer_match():
		if has_node("/root/Network"):
			var network = get_node("/root/Network")
			if network.has_method("notify_player_died"):
				network.notify_player_died() 
			if network.has_method("leave_match"):
				network.leave_match() 
			if network.has_method("set_player_available"):
				network.set_player_available() 
		_show_hud()
	
	Global.reset_player_data()
	
	if get_tree().paused:
		get_tree().paused = false
	
	# Ocultamos todo manualmente antes de salir
	bg.visible = false
	panel.visible = false
	panel.modulate.a = 0.0
	visible = false
	
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
