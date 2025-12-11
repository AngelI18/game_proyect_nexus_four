extends Control
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var minimap_camera: Camera2D = $SubViewportContainer/SubViewport/minimap
@onready var player_marker: ColorRect = $SubViewportContainer/SubViewport/PlayerMarker

var player_node: Node2D
var enemy_markers: Array[ColorRect] = []
var hazard_markers: Array[ColorRect] = []
var shop_markers: Array[ColorRect] = []

func _ready() -> void:
	# Asegurar que el contenido no se desborde del área blanca
	clip_contents = true
	
	# Configurar el SubViewportContainer para que se estire
	if sub_viewport_container:
		sub_viewport_container.stretch = true
		sub_viewport_container.stretch_shrink = 1
		# Asegurar que ocupe todo el espacio disponible
		sub_viewport_container.anchor_right = 1.0
		sub_viewport_container.anchor_bottom = 1.0
		sub_viewport_container.offset_left = 0
		sub_viewport_container.offset_top = 0
		sub_viewport_container.offset_right = 0
		sub_viewport_container.offset_bottom = 0
	
	# Configurar el SubViewport para que coincida con el tamaño del contenedor
	if sub_viewport and sub_viewport_container:
		sub_viewport.size = sub_viewport_container.size
	
	# Esperar a que el nivel esté completamente cargado
	call_deferred("_setup_level")
	call_deferred("_setup_player")

func _setup_level() -> void:
	# Buscar el nivel en la escena actual
	var current_scene = get_tree().current_scene
	if not current_scene:
		print("[MINIMAP] No se encontró la escena actual")
		return
	
	# Buscar tilemaps de diferentes formas
	var tilemaps_found = false
	
	# Opción 1: Buscar un nodo "TileMaps" que contenga los tilemaps
	if current_scene.has_node("TileMaps"):
		print("[MINIMAP] Encontrado nodo TileMaps")
		for tilemap in current_scene.get_node("TileMaps").get_children():
			if tilemap is TileMapLayer:
				_add_tilemap_to_minimap(tilemap)
				tilemaps_found = true
	
	# Opción 2: Buscar todos los TileMapLayer en la escena
	if not tilemaps_found:
		print("[MINIMAP] Buscando TileMapLayer en toda la escena")
		var all_tilemaps = _find_tilemaps_recursive(current_scene)
		for tilemap in all_tilemaps:
			_add_tilemap_to_minimap(tilemap)
			tilemaps_found = true
	
	if not tilemaps_found:
		print("[MINIMAP] No se encontraron tilemaps en el nivel")
	
	# Configurar marcadores de enemigos, peligros y tiendas
	_setup_markers()

func _find_tilemaps_recursive(node: Node) -> Array[TileMapLayer]:
	var tilemaps: Array[TileMapLayer] = []
	
	if node is TileMapLayer:
		tilemaps.append(node)
	
	for child in node.get_children():
		tilemaps.append_array(_find_tilemaps_recursive(child))
	
	return tilemaps

func _add_tilemap_to_minimap(tilemap: TileMapLayer) -> void:
	print("[MINIMAP] Agregando tilemap: ", tilemap.name)
	var minimap_tilemap = tilemap.duplicate()
	_setup_minimap(minimap_tilemap)
	var used_rect: Rect2i = tilemap.get_used_rect()
	_set_minimap_limits(used_rect)
	print("[MINIMAP] Límites: ", used_rect)

func _setup_player() -> void:
	# Buscar al jugador
	player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		print("[MINIMAP] Jugador encontrado: ", player_node.name)
		# Centrar la cámara del minimapa en el jugador inmediatamente
		minimap_camera.global_position = player_node.global_position
		player_marker.global_position = player_node.global_position
	else:
		print("[MINIMAP] No se encontró el jugador")

func _process(_delta: float) -> void:
	if player_node:
		minimap_camera.global_position = lerp(
			minimap_camera.global_position,
			player_node.global_position, 0.2
		)
		player_marker.global_position = player_node.global_position
	
	# Actualizar posiciones de marcadores
	_update_enemy_markers()
	_update_hazard_markers()

func _setup_minimap(minimap_tilemap: TileMapLayer) -> void:
	sub_viewport.add_child(minimap_tilemap)

func _set_minimap_limits(used_rect: Rect2i) -> void:
	minimap_camera.limit_left = used_rect.position.x * 16
	minimap_camera.limit_top = used_rect.position.y * 16
	minimap_camera.limit_right = (used_rect.position.x + used_rect.size.x) * 16
	minimap_camera.limit_bottom = (used_rect.position.y + used_rect.size.y) * 16

func _setup_markers() -> void:
	# Marcar enemigos en rojo
	var enemies = get_tree().get_nodes_in_group("enemies")
	print("[MINIMAP] Enemigos encontrados: ", enemies.size())
	for enemy in enemies:
		var marker = _create_marker(Color.RED, Vector2(6, 6))
		enemy_markers.append(marker)
		sub_viewport.add_child(marker)
	
	# Marcar objetos que hacen daño en amarillo
	var hazards = get_tree().get_nodes_in_group("hazards")
	print("[MINIMAP] Peligros encontrados: ", hazards.size())
	for hazard in hazards:
		var marker = _create_marker(Color.YELLOW, Vector2(6, 6))
		hazard_markers.append(marker)
		sub_viewport.add_child(marker)
		marker.global_position = hazard.global_position
	
	# Marcar tiendas en morado
	var shops = get_tree().get_nodes_in_group("shops")
	print("[MINIMAP] Tiendas encontradas: ", shops.size())
	for shop in shops:
		var marker = _create_marker(Color.PURPLE, Vector2(8, 8))
		shop_markers.append(marker)
		sub_viewport.add_child(marker)
		marker.global_position = shop.global_position

func _create_marker(color: Color, marker_size: Vector2) -> ColorRect:
	var marker = ColorRect.new()
	marker.color = color
	marker.custom_minimum_size = marker_size
	marker.size = marker_size
	marker.pivot_offset = marker_size / 2
	return marker

func _update_enemy_markers() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	# Limpiar marcadores de enemigos muertos
	for i in range(enemy_markers.size() - 1, -1, -1):
		if i >= enemies.size() or not is_instance_valid(enemies[i]):
			enemy_markers[i].queue_free()
			enemy_markers.remove_at(i)
	
	# Actualizar posiciones
	for i in range(min(enemies.size(), enemy_markers.size())):
		if is_instance_valid(enemies[i]):
			enemy_markers[i].global_position = enemies[i].global_position

func _update_hazard_markers() -> void:
	var hazards = get_tree().get_nodes_in_group("hazards")
	
	# Actualizar posiciones (los peligros normalmente no se mueven)
	for i in range(min(hazards.size(), hazard_markers.size())):
		if is_instance_valid(hazards[i]):
			hazard_markers[i].global_position = hazards[i].global_position
