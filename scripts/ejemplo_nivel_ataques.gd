extends Node2D

# Script de ejemplo para manejar ataques en un nivel
# Puedes agregar este script a tu escena de nivel o copiar las funciones que necesites

@onready var player = $player  # Ajusta la ruta a tu jugador

func _ready():
	_connect_to_network()
	_connect_to_player()


func _connect_to_network():
	"""Conecta a las señales del sistema de red"""
	if has_node("/root/Network"):
		var network = get_node("/root/Network")
		
		# Señal cuando recibes un ataque
		if network.has_signal("ataque_recibido"):
			network.ataque_recibido.connect(_on_ataque_recibido)
			print("[NIVEL] Conectado a señal ataque_recibido")
		
		# Opcional: escuchar todos los mensajes de juego
		if network.has_signal("game_message_received"):
			network.game_message_received.connect(_on_game_message_received)
			print("[NIVEL] Conectado a señal game_message_received")
	else:
		print("[NIVEL] Network no encontrado")


func _connect_to_player():
	"""Conecta a las señales del jugador si las tiene"""
	if player:
		# Si tu jugador tiene una señal de enemy_killed, conéctala
		# Ejemplo: player.enemy_killed.connect(_on_player_killed_enemy)
		print("[NIVEL] Jugador encontrado")
	else:
		print("[NIVEL] Jugador no encontrado")


# =========================================
# HANDLERS DE ATAQUES
# =========================================

func _on_ataque_recibido(attack_data: Dictionary):
	"""Se llama cuando recibes un ataque del oponente"""
	var attacker = attack_data.get("player", "desconocido")
	var damage = attack_data.get("damage", 10)
	
	print("==================================================")
	print("[NIVEL] ATAQUE RECIBIDO")
	print("[NIVEL] Atacante: ", attacker)
	print("[NIVEL] Daño: ", damage)
	print("==================================================")
	
	# Aplicar daño al jugador
	_apply_damage_to_player(damage)
	
	# Opcional: Efectos visuales/sonoros
	_play_attack_effects()
	
	# Opcional: Spawnear enemigos extra
	# _spawn_extra_enemies(2)


func _on_game_message_received(data: Dictionary):
	"""Se llama para TODOS los mensajes de juego (debug)"""
	var msg_type = data.get("type", "unknown")
	print("[NIVEL] Mensaje recibido - Tipo: ", msg_type)


# =========================================
# FUNCIONES DE APLICACIÓN DE EFECTOS
# =========================================

func _apply_damage_to_player(damage: int):
	"""Aplica daño al jugador"""
	if player and player.has_method("take_damage"):
		player.take_damage(damage)
		print("[NIVEL] Aplicando ", damage, " de daño al jugador")
	else:
		print("[NIVEL] No se pudo aplicar daño (método no encontrado)")


func _play_attack_effects():
	"""Reproduce efectos visuales/sonoros del ataque"""
	# Ejemplo: Hacer temblar la cámara
	if player and player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		_shake_camera(camera, 0.3, 10.0)
	
	# Ejemplo: Reproducir sonido
	# $AttackSound.play()
	
	# Ejemplo: Flash rojo en pantalla
	# _flash_screen(Color.RED, 0.2)


func _shake_camera(camera: Camera2D, duration: float, intensity: float):
	"""Hace temblar la cámara"""
	if not camera:
		return
	
	var tween = create_tween()
	var original_offset = camera.offset
	
	for i in range(int(duration * 60)):  # 60 fps
		var random_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(camera, "offset", random_offset, 0.016)
	
	tween.tween_property(camera, "offset", original_offset, 0.1)


func _spawn_extra_enemies(count: int):
	"""Spawnea enemigos extra como castigo por recibir ataque"""
	print("[NIVEL] Spawneando ", count, " enemigos extra")
	
	# Aquí va tu lógica de spawn
	# Ejemplo:
	# for i in range(count):
	#     var enemy = preload("res://scenes/enemies/slime.tscn").instantiate()
	#     enemy.position = _get_random_spawn_position()
	#     add_child(enemy)


func _get_random_spawn_position() -> Vector2:
	"""Obtiene una posición aleatoria para spawnear enemigos"""
	# Ejemplo: spawnnear cerca del jugador pero no encima
	if player:
		var offset = Vector2(
			randf_range(-200, 200),
			randf_range(-200, 200)
		)
		return player.position + offset
	return Vector2.ZERO


# =========================================
# ENVÍO DE ATAQUES (OPCIONAL)
# =========================================

func _on_player_killed_enemy():
	"""Se llama cuando el jugador mata un enemigo"""
	# Notificar a Network (envía ataque automático cada 5 enemigos)
	if has_node("/root/Network"):
		get_node("/root/Network").enemy_killed()


func send_manual_attack(damage: int = 10):
	"""Envía un ataque manual inmediatamente"""
	if has_node("/root/Network"):
		get_node("/root/Network").send_attack(damage)
		print("[NIVEL] Ataque manual enviado")


# =========================================
# INPUTS DE PRUEBA
# =========================================

func _input(event):
	"""Inputs de prueba (eliminar en producción)"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				# Enviar ataque de prueba
				send_manual_attack(15)
				print("[TEST] F1: Ataque manual enviado")
			
			KEY_F2:
				# Simular recibir ataque
				_on_ataque_recibido({
					"type": "attack",
					"player": "TestPlayer",
					"damage": 20
				})
				print("[TEST] F2: Ataque simulado")
			
			KEY_F3:
				# Simular matar enemigo
				_on_player_killed_enemy()
				print("[TEST] F3: Enemigo simulado")
