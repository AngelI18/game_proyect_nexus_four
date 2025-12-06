extends Node2D

@onready var tilemap = $TileMapLayer # Tu nodo de terreno
@onready var player = $player

func _ready():
	var camara = player.get_node("Camera2D")
	
	# Obtenemos el rectángulo que contiene todos los tiles dibujados
	var map_rect = tilemap.get_used_rect()
	
	# El tamaño de cada tile (usualmente 16, 32 o 64 px)
	var tile_size = tilemap.tile_set.tile_size
	
	if camara:
		# Convertimos coordenadas de tiles a pixeles y asignamos los límites
		camara.limit_left = map_rect.position.x * tile_size.x
		camara.limit_top = map_rect.position.y * tile_size.y
		camara.limit_right = map_rect.end.x * tile_size.x
		camara.limit_bottom = map_rect.end.y * tile_size.y
