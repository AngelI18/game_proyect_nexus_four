extends Panel

# === NODOS UI ===
@onready var input: LineEdit = $MarginContainer/GridContainer/LineEdit
@onready var btn_connect: Button = $MarginContainer/GridContainer/connect
@onready var scroll: ScrollContainer = $MarginContainer/GridContainer/scroll
@onready var players_names: VBoxContainer = $"MarginContainer/GridContainer/scroll/player names"

# === READY ===
func _ready() -> void:
	# Conectar señales
	if not Network.player_list_updated.is_connected(Callable(self, "_on_player_list_updated")):
		Network.player_list_updated.connect(_on_player_list_updated)
	if not btn_connect.pressed.is_connected(Callable(self, "_on_connect_pressed")):
		btn_connect.pressed.connect(_on_connect_pressed)
	if not input.text_submitted.is_connected(Callable(self, "_on_connect_pressed")):
		input.text_submitted.connect(func(_new_text): _on_connect_pressed())
	
	# Mostrar siempre el panel con el nombre actual
	visible = true
	
	# Cargar nombre actual si existe
	if Global.player_name != "":
		input.text = Global.player_name
		input.placeholder_text = "Cambiar nombre"
	else:
		input.placeholder_text = "Ingresa tu nombre"
		input.grab_focus()

# === METHODS ===
func _on_player_list_updated(players: Dictionary) -> void:
	"""Actualiza la lista de jugadores conectados - mismo patrón que Multijugador.gd"""
	_limpiar_lista_jugadores()
	
	for id in players.keys():
		var player_info = players[id]
		var player_label = Label.new()
		player_label.text = player_info.get("name", "Desconocido")
		player_label.add_theme_font_size_override("font_size", 14)
		player_label.add_theme_color_override("font_color", Color.BLACK)
		players_names.add_child(player_label)

func _on_connect_pressed() -> void:
	var nombre = input.text.strip_edges()
	
	# Validar que el nombre no esté vacío
	if nombre == "":
		_mostrar_error("Por favor ingresa un nombre")
		return
	
	# Verificar que el nombre no exista en la lista de jugadores
	if _nombre_existe(nombre):
		_mostrar_error("Ese nombre ya está en uso")
		return
	
	# Guardar nombre en Global
	Global.player_name = nombre
	print("[CREATE_NAME] Nombre guardado: ", nombre)
	
	# Inicializar Network con el nombre (nuevo o actualizado)
	var parent = get_parent()
	if parent and parent.has_method("_iniciar_con_nombre"):
		parent._iniciar_con_nombre(nombre)
	
	# El panel sigue visible pero muestra el nombre actual
	input.text = nombre
	input.placeholder_text = "Cambiar nombre"

func _nombre_existe(nombre: String) -> bool:
	"""Verifica si el nombre ya existe en la lista de jugadores"""
	for label in players_names.get_children():
		var label_text = label.text.trim_prefix("👤 ")
		if label_text == nombre:
			return true
	return false

func _mostrar_error(_mensaje: String) -> void:
	"""Muestra un error en el input"""
	input.modulate = Color.RED
	await get_tree().create_timer(0.5).timeout
	input.modulate = Color.WHITE

func _limpiar_lista_jugadores() -> void:
	"""Limpia la lista de jugadores mostrados"""
	for child in players_names.get_children():
		child.queue_free()
