extends CanvasLayer

@onready var bg = $ColorRect
@onready var btn_reiniciar = $PanelContainer/VBoxContainer/reiniciar
@onready var panel = $PanelContainer

var menu_abierto = false

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

func _show_menu_overlay(disable_reiniciar: bool):
	_hide_hud()
	if btn_reiniciar:
		btn_reiniciar.disabled = disable_reiniciar
		btn_reiniciar.modulate = Color(0.5, 0.5, 0.5, 0.5) if disable_reiniciar else Color(1, 1, 1, 1)

	visible = true
	bg.visible = true
	panel.visible = true
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func _hide_menu_overlay():
	_show_hud()
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	bg.visible = false
	panel.visible = false
	visible = false

func toggle_pausa():
	var tree = get_tree()

	# Si estamos en partida multijugador, no pausar el árbol
	if _is_in_multiplayer_match():
		_show_menu_overlay(true)
		return

	# Toggle normal (single player): pausar/despausar
	tree.paused = !tree.paused
	
	if tree.paused:
		_show_menu_overlay(false)
	else:
		_hide_menu_overlay()

func _on_jugar_pressed():
	# Si estábamos en overlay sin pausar (multijugador), solo ocultar overlay
	if _is_in_multiplayer_match():
		_hide_menu_overlay()
		return

	_show_hud()
	toggle_pausa()

func _on_reiniciar_pressed():
	if _is_in_multiplayer_match():
		return

	# Recargar la escena completa, incluyendo jugador
	if get_tree().paused:
		get_tree().paused = false
	get_tree().reload_current_scene()

func _on_salir_pressed():
	# Si estamos en multijugador, enviar señal de derrota y salir
	if _is_in_multiplayer_match():
		print("[PAUSE] Abandonando partida - Enviando señal de derrota")
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
				print("[PAUSE] Jugador marcado como disponible")
		_show_hud()
	
	Global.reset_player_data()
	
	if get_tree().paused:
		get_tree().paused = false
	
	# Ocultamos todo manualmente antes de salir
	bg.visible = false
	panel.visible = false
	panel.modulate.a = 0.0
	visible = false
	menu_abierto = false
	
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
