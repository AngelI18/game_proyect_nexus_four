extends Control

# === NODOS UI ===
@onready var label: Label = $Panel/Label
@onready var lista: VBoxContainer = $Panel/ScrollContainer/VBoxContainer
@onready var scroll: ScrollContainer = $Panel/ScrollContainer
@onready var btn_enviar: Button = $Panel/Enviar
@onready var btn_ver: Button = $Panel/Ver
@onready var volver: Button = $Volver
@onready var lobby_panel: Panel = $Panel/Lobby
@onready var create_name_panel: Panel = $"Create name"

# === CONSTANTES ===
const MY_GAME_ID := "A"
const MY_GAME_KEY := "5NLQK3EMIZ"
const MY_GAME_NAME := "Guardian del falapito"

# === VARIABLES ===
var posicion_menu := 0
var modo := 0
var jugadores_del_match: Array = []

# === READY ===
func _ready():
	# El panel create_name se mostrará automáticamente si Global.player_name == ""
	label.text = "Modo Multijugador"
	lobby_panel.visible = false
	_limpiar_ui()
	
	# Connect to Network signals
	Network.connected_to_server.connect(_on_connected)
	Network.connection_closed.connect(_on_disconnected)
	Network.player_list_updated.connect(_on_player_list_updated)
	Network.invitation_received.connect(_on_invitation_received)
	Network.match_started.connect(_on_match_started)
	Network.game_over.connect(_on_game_over)
	Network.match_connected.connect(_on_match_connected)
	Network.match_ready.connect(_on_match_ready)
	Network.opponent_left.connect(_on_opponent_left)

	# UI Connections
	btn_enviar.pressed.connect(_on_enviar_pressed)
	btn_ver.pressed.connect(_on_ver_pressed)
	volver.pressed.connect(_on_volver_pressed)
	
	# Start Connection solo si hay nombre
	if Global.player_name != "":
		Network.iniciar(Global.player_name, MY_GAME_ID, MY_GAME_KEY)

	scroll.visible = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

# === NETWORK HANDLERS ===
func _on_connected():
	print("Conectado al servidor.")
	# Auto-refresh players if in that menu
	if posicion_menu == 1 and modo == 0:
		Network.refresh_players()

func _on_disconnected():
	print("Desconectado.")
	_limpiar_ui()
	label.text = "Desconectado"

func _on_player_list_updated(players: Dictionary):
	if posicion_menu == 1 and modo == 0:
		_render_player_list(players)

func _on_invitation_received(invitation: Dictionary):
	# Cambiar automáticamente a la vista de invitaciones
	scroll.visible = true
	btn_enviar.visible = false
	btn_ver.visible = false
	posicion_menu = 1
	modo = 2
	label.text = "Invitaciones recibidas"
	_render_invitations()
	print("Invitación recibida de " + invitation.get("name", ""))

func _on_match_connected(match_id: String, rival_name: String):
	print("Conectado al match: ", match_id)
	print("Mi nombre: ", Global.player_name)
	print("Rival: ", rival_name)
	
	# Si el rival_name está vacío, intentar obtenerlo
	if rival_name == "" or rival_name == "Desconocido":
		print("[WARNING] Nombre del rival vacío o desconocido")
	
	jugadores_del_match = [Global.player_name, rival_name]
	_abrir_lobby()

func _on_match_ready():
	print("Match listo. Esperando inicio...")
	# Update UI to show ready status
	_actualizar_ready_ui(true) # Assume both ready? Or wait for individual pings?
	# The server sends players-ready when both are connected.
	# Then we send ping-match.
	# Network.gd handles sending ping if we click "Ready".

func _on_match_started(rival_name: String):
	print("Partida iniciada contra: ", rival_name)
	await get_tree().process_frame
	var first_level = Global.get_first_level()
	if first_level != "":
		get_tree().change_scene_to_file(first_level)
	else:
		print("Error: No level found")

func _on_game_over(result: String, reason: String):
	print("Game Over: ", result, " Reason: ", reason)
	_finalizar_partida_ui()

func _on_opponent_left():
	print("Oponente salió.")
	_finalizar_partida_ui()
	label.text = "El rival abandonó la sala"

# === UI RENDERING ===
func _render_player_list(players: Dictionary):
	_limpiar_lista()
	
	if players.is_empty():
		lista.add_child(_crear_label("❌ No hay jugadores conectados", 22))
		return

	for id in players.keys():
		var j = players[id]
		var panel = _crear_panel_jugador(j, id)
		lista.add_child(panel)

func _crear_panel_jugador(j: Dictionary, id: String) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(600, 110)
	panel.add_theme_stylebox_override("panel", _crear_panel_estilo())

	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 60)

	var lbl := _crear_label(j["name"], 22)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(lbl)
	fila.add_child(center)

	var estado = j.get("status", "AVAILABLE")
	var btn: Button
	if estado == "BUSY" or estado == "IN_MATCH":
		btn = _crear_boton("🕹️ Ocupado", 20)
		btn.disabled = true
	else:
		btn = _crear_boton("📨 Invitar", 20, 180, 49, func(): Network.send_invitation(id))
	fila.add_child(btn)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_child(fila)
	panel.add_child(margin)
	return panel

func _render_invitations():
	_limpiar_lista()
	var invs = Network.lobby.invitations
	
	if invs.is_empty():
		lista.add_child(_crear_label("No hay invitaciones", 22))
		return

	for info in invs:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(600, 120)
		panel.add_theme_stylebox_override("panel", _crear_panel_estilo())

		var fila := HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.add_theme_constant_override("separation", 40)
		fila.add_child(_crear_label(info["name"], 24))
		
		var mid = info.get("matchId", "")
		fila.add_child(_crear_boton("✅ Aceptar", 18, 140, 45, func(): Network.accept_invitation(mid)))
		fila.add_child(_crear_boton("❌ Rechazar", 18, 140, 45, func(): Network.reject_invitation(mid)))

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_top", 16)
		margin.add_theme_constant_override("margin_bottom", 16)
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_child(fila)
		panel.add_child(margin)
		lista.add_child(panel)

func _abrir_lobby():
	lobby_panel.visible = true
	var box: VBoxContainer = $Panel/Lobby/VBoxContainer
	for c in box.get_children(): c.queue_free()
	
	box.add_child(_crear_label("🏁 LOBBY DE PARTIDA", 28))
	
	# Render players in lobby (evita nombres vacíos para no romper set_name)
	for p_name in jugadores_del_match:
		if str(p_name).strip_edges() == "":
			continue
		var is_local = (p_name == Global.player_name)
		var fila := HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.add_child(_crear_label("👤 " + p_name, 24))
		
		var btn_estado = _crear_boton("❌ No listo", 18, 160, 45)
		btn_estado.name = p_name
		if is_local:
			btn_estado.pressed.connect(func():
				btn_estado.text = "⏳ Esperando..."
				Network.send_ready_ping()
			)
		else:
			btn_estado.disabled = true
		
		fila.add_child(btn_estado)
		box.add_child(fila)

func _actualizar_ready_ui(_is_ready: bool):
	# This is a simplification. Ideally we track who is ready.
	# But the server flow is: players-ready -> ping-match -> match-start.
	# So if we get players-ready, it means both are connected.
	pass

func _finalizar_partida_ui():
	lobby_panel.visible = false
	scroll.visible = false
	btn_enviar.visible = true
	btn_ver.visible = true
	posicion_menu = 0
	label.text = "Modo Multijugador"

# === UTILS ===
func _limpiar_ui():
	_limpiar_lista()
	scroll.visible = false
	btn_enviar.visible = true
	btn_ver.visible = true
	posicion_menu = 0
	modo = 0

func _limpiar_lista():
	for c in lista.get_children():
		c.queue_free()

func _crear_panel_estilo(color: Color = Color(0.94, 0.94, 0.94)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.2, 0.2, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(25)
	return style

func _crear_label(texto: String, font_size := 22) -> Label:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl

func _crear_boton(texto, font_size := 18, ancho := 140, alto := 45, accion = null) -> Button:
	var btn := Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(ancho, alto)
	btn.add_theme_font_size_override("font_size", font_size)
	if accion != null:
		btn.pressed.connect(accion)
	return btn

# === MÉTODOS AUXILIARES ===
func _iniciar_con_nombre(nombre: String):
	"""Inicializa la conexión Network con el nombre creado"""
	print("[MULTIJUGADOR] Iniciando conexión con nombre: ", nombre)
	Network.iniciar(nombre, MY_GAME_ID, MY_GAME_KEY)

# === BOTONES ===
func _on_enviar_pressed():
	scroll.visible = true
	btn_enviar.visible = false
	btn_ver.visible = false
	posicion_menu = 1
	modo = 0
	label.text = "Jugadores conectados"
	Network.refresh_players()

func _on_ver_pressed():
	scroll.visible = true
	btn_enviar.visible = false
	btn_ver.visible = false
	posicion_menu = 1
	modo = 2
	label.text = "Invitaciones recibidas"
	_render_invitations()

func _on_volver_pressed():
	if lobby_panel.visible:
		Network.leave_match()
		_finalizar_partida_ui()
		return

	if posicion_menu == 0:
		# Mostrar mensaje de desconexión
		label.text = "Desconectando..."
		btn_enviar.visible = false
		btn_ver.visible = false
		volver.disabled = true
		
		# Rechazar todas las invitaciones pendientes antes de salir
		Network.reject_all_pending_invitations()
		
		# Desconectar completamente del servidor
		print("[MULTIJUGADOR] Desconectando del servidor...")
		Network.apagar()
		
		# Esperar a que se complete la desconexión
		await get_tree().create_timer(0.8).timeout
		
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		_limpiar_ui()
