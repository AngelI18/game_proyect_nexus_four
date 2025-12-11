extends CharacterBody2D

@onready var sfx_pasos = $AudioPasos
@onready var sfx_ataque = $AudioAtaque
@onready var sfx_dano = $AudioDano
@onready var sfx_salto = $AudioSalto

#Señales
signal health_changed(health, max_health)
signal coin_changed(new_coins)

# --- DASH CONFIG ---
var DASH_SPEED = 450.0    # Velocidad del impulso (más rápido que SPEED normal)
var DASH_DURATION = 0.2   # Cuánto dura el impulso (en segundos)
var DASH_COOLDOWN = 1.0   # Tiempo de espera para volver a usarlo
var is_dashing = false    # Estado actual
var can_dash = true       # Control del cooldown

# Movimiento
var SPEED = 170.0
const JUMP_VELOCITY = -350.0
const KNOCKBACK_STRENGTH = 150.0
const KNOCKBACK_JUMP = -150.0

var can_double_jump = true
var MAX_JUMPS = 2
var jumps_remaining = MAX_JUMPS

# Salud
var MAX_HEALTH = 200
var health = MAX_HEALTH
var max_regeneration = MAX_HEALTH * 0.7
var player_alive = true

# Estado
var damage = 20
var is_attacking = false
var is_hurt = false
var is_invulnerable = false
var is_taking_damage = false

# Combate
var enemy_in_range: Node2D = null
var enemy_in_attack_range: Node2D = null
var can_take_damage = true
var joystick_is_active = false
var joystick_direction = Vector2.ZERO

# Colecciones
var coins = 0
var enemies_killed_this_run: int = 0

# Checkpoint
var last_safe_position: Vector2 = Vector2.ZERO


func _ready():
	add_to_group("player")
	_load_saved_data()
	_connect_joystick()
	call_deferred("_emit_initial_signals")

func _connect_joystick():
	var joystick = get_tree().get_first_node_in_group("attack_joystick")
	if joystick:
		joystick.attack_triggered.connect(_on_joystick_attack_triggered)
		joystick.direction_changed.connect(_on_joystick_direction_changed)

func _load_saved_data() -> void:
	health = Global.player_health
	coins = Global.player_coins

func _emit_initial_signals():
	update_health()
	emit_coin_signal()


func _physics_process(delta: float) -> void:
	_handle_dash_input()
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	_handle_attack()
	_check_death()
	
	move_and_slide()
	
	_update_animation()
	_handle_audio()
	_check_enemy_damage()
	_check_tile_damage()
	_update_safe_position()
	
	
# Audio
func _handle_audio() -> void:
	# Si estamos atacando, heridos o en el aire, NO deben sonar pasos
	if is_attacking or is_hurt or not is_on_floor():
		sfx_pasos.stop()
		return
	
	# Si nos estamos moviendo (velocidad X no es 0)
	if velocity.x != 0:
		if not sfx_pasos.playing:
			# Opcional: Variación de tono pequeña para mas realismo
			sfx_pasos.pitch_scale = randf_range(0.9, 1.1)
			sfx_pasos.play()
	else:
		# Si estamos quietos
		sfx_pasos.stop()
	_auto_save_data()


func _apply_gravity(delta: float) -> void:
	if is_dashing: return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		can_double_jump = true
		jumps_remaining = MAX_JUMPS

func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			_jump()
		elif can_double_jump and jumps_remaining > 0:
			_jump()
		elif jumps_remaining == 0:
			can_double_jump = false

func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	jumps_remaining -= 1
	# Reproducir sonido de salto con un poco de variación para que no canse
	sfx_salto.pitch_scale = randf_range(0.9, 1.1)
	sfx_salto.play()

func _handle_movement() -> void:
	if is_dashing: return
	
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if is_attacking and is_on_floor():
		velocity.x = 0.0
	elif is_hurt:
		pass
	else:
		velocity.x = direction * SPEED
	
	if direction != 0 and not is_attacking and not is_hurt:
		$AnimatedSprite2D.flip_h = direction < 0

func _update_safe_position() -> void:
	if is_on_floor():
		last_safe_position = global_position

var _save_timer: float = 0.0
const SAVE_INTERVAL: float = 2.0  # Guardar cada 2 segundos

func _auto_save_data() -> void:
	_save_timer += get_physics_process_delta_time()
	if _save_timer >= SAVE_INTERVAL:
		_save_timer = 0.0
		Global.save_player_data(health, coins, global_position)

#Animaciones
func _update_animation() -> void:
	if is_dashing: return
	
	if is_attacking or is_hurt:
		return
	
	if not is_on_floor():
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump")
		else:
			$AnimatedSprite2D.play("fall")
	elif velocity.x == 0:
		$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("run")

func blink_sprite(duration: float) -> void:
	var time = 0.0
	while time < duration:
		$AnimatedSprite2D.modulate.a = 0.3
		await get_tree().create_timer(0.1).timeout
		$AnimatedSprite2D.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		time += 0.2
	$AnimatedSprite2D.modulate.a = 1.0


func _handle_attack() -> void:
	# Ataque con teclado
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_perform_attack()
	
	# Ataque continuo con joystick
	if joystick_is_active and not is_attacking and is_on_floor() and not is_taking_damage:
		_perform_attack(joystick_direction)

func _perform_attack(attack_direction: Vector2 = Vector2.ZERO) -> void:
	Global.player_current_attack = true
	is_attacking = true
	sfx_ataque.play()
	
	# Aplicar dirección del joystick si se proporciona
	if attack_direction != Vector2.ZERO and abs(attack_direction.x) > 0.3:
		$AnimatedSprite2D.flip_h = attack_direction.x < 0
	
	$AnimatedSprite2D.play("attack")
	$deal_attack_timer.start()
	_enable_attack_hitbox()

func _enable_attack_hitbox() -> void:
	var attack_hitbox = $player_attack_hit_box/CollisionShape2D
	if attack_hitbox:
		attack_hitbox.disabled = false
		var offset_x = 12 if not $AnimatedSprite2D.flip_h else -12
		attack_hitbox.position.x = offset_x

func _disable_attack_hitbox() -> void:
	var attack_hitbox = $player_attack_hit_box/CollisionShape2D
	if attack_hitbox:
		attack_hitbox.disabled = true

func _on_joystick_attack_triggered(_direction_attack: Vector2) -> void:
	# Esta señal se emite cuando se SUELTA el joystick
	# Solo la usamos para marcar que el joystick ya no está activo
	joystick_is_active = false
	joystick_direction = Vector2.ZERO

func _on_joystick_direction_changed(direction: Vector2) -> void:
	# Esta señal se emite mientras se mueve el joystick
	joystick_direction = direction
	
	# Solo activar si la dirección supera el área muerta (dead zone)
	if direction.length() > 0.1:  # Respeta el dead_zone del joystick
		joystick_is_active = true
		# Primer ataque inmediato si no estamos atacando
		if not is_attacking and is_on_floor() and not is_taking_damage:
			_perform_attack(direction)
	else:
		joystick_is_active = false


func take_damage(damage_amount: int, knockback_dir: Vector2 = Vector2.ZERO, invulnerability_time: float = 1.0) -> void:
	if is_invulnerable or not can_take_damage:
		return
	
	if is_attacking:
		is_attacking = false
		Global.player_current_attack = false
		$deal_attack_timer.stop()
	
	health -= damage_amount
	health = max(0, health)
	update_health()
	
	sfx_dano.play()
	
	if knockback_dir != Vector2.ZERO:
		velocity.x = knockback_dir.x * KNOCKBACK_STRENGTH
		velocity.y = knockback_dir.y * abs(KNOCKBACK_JUMP)
	
	is_invulnerable = true
	is_hurt = true
	can_take_damage = false
	is_taking_damage = true
	
	$attack_cooldown.start()
	$player_is_hurt.start()
	$invulnerability_timer.start(invulnerability_time)
	
	$regen_timer.stop()
	$regen_timer.start()
	
	$AnimatedSprite2D.play("hurt")
	blink_sprite(invulnerability_time)
	
	Global.save_player_data(health, coins, global_position)  # Guardar al recibir daño
	print("Daño recibido: ", damage_amount, " | Salud actual: ", health)

func _check_enemy_damage() -> void:
	if enemy_in_range == null:
		return
	
	var damage_amount = 0
	var enemy_type = 1
	
	if enemy_in_range.has_method("get_enemy_type"):
		enemy_type = enemy_in_range.get_enemy_type()
	
	match enemy_type:
		1:
			damage_amount = int(MAX_HEALTH * 0.08)
		2:
			damage_amount = int(MAX_HEALTH * 0.12)
		3:
			damage_amount = int(MAX_HEALTH * 0.16)
		_:
			damage_amount = int(MAX_HEALTH * 0.08)
	
	var knockback_direction = (global_position - enemy_in_range.global_position).normalized()
	take_damage(damage_amount, knockback_direction, 2.0)

func _check_tile_damage() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is TileMapLayer:
			_process_tile_collision(collider, collision)

func _process_tile_collision(tile_map: TileMapLayer, collision: KinematicCollision2D) -> void:
	var collision_pos = collision.get_position()
	var collision_normal = collision.get_normal()
	
	var search_offset = collision_normal * -2.0
	var adjusted_pos = collision_pos + search_offset
	
	var tile_coords = tile_map.local_to_map(tile_map.to_local(adjusted_pos))
	var tile_data = tile_map.get_cell_tile_data(tile_coords)
	
	if not tile_data:
		return
	
		# ESTO ES NUEVO: Busca la etiqueta de datos
	var es_peligroso = tile_data.get_custom_data("is_damage") # Asegúrate que el nombre sea exacto

	if es_peligroso:
		var knockback_dir = Vector2.ZERO
		
		if abs(collision_normal.y) > 0.5:
			var horizontal_dir = -sign(velocity.x) if velocity.x != 0 else 0
			knockback_dir = Vector2(horizontal_dir, -2)
		else:
			knockback_dir = Vector2(collision_normal.x * 1.5, -1)
		
		take_damage(10, knockback_dir, 1.0)

func _check_death() -> void:
	if health <= 0:
		player_alive = false
		health = 0
		
		Global.update_stats_on_death(coins, enemies_killed_this_run)
		
		var death_scene = preload("res://scenes/ui/death_scene.tscn").instantiate()
		
		# Pasar configuración de cámara
		if has_node("Camera2D"):
			var camera = $Camera2D
			death_scene.setup_camera_data(
				camera.zoom,
				camera.limit_left,
				camera.limit_top,
				camera.limit_right,
				camera.limit_bottom,
				camera.global_position
			)
			camera.enabled = false
		
		get_tree().root.add_child(death_scene)
		
		queue_free()


func update_health() -> void:
	health_changed.emit(health, MAX_HEALTH)

func _on_regen_timer_timeout() -> void:
	if health < max_regeneration:
		health = min(health + 20, max_regeneration)
		update_health()
	elif health <= 0:
		$Camera2D.enabled = false
		health = 0
		update_health()

#Sistema de monedas
func add_coins(amount: int) -> void:
	coins += amount
	emit_coin_signal()
	Global.save_player_data(health, coins, global_position)  # Guardar inmediatamente

func emit_coin_signal() -> void:
	coin_changed.emit(coins)

#Detección de colisiones
func _on_player_hit_box_area_entered(area: Area2D) -> void:
	# Detectar si el área pertenece a un enemigo (para RECIBIR daño)
	if area.name == "enemy_hitbox" and area.get_parent().has_method("enemy"):
		enemy_in_range = area.get_parent()
		
func _on_player_hit_box_area_exited(area: Area2D) -> void:
	# Verificar si el área que salió es del enemigo actual en rango
	if area.name == "enemy_hitbox" and area.get_parent() == enemy_in_range:
		enemy_in_range = null

func _on_player_attack_hit_box_body_entered(body: Node2D) -> void:
	# Detectar enemigos en rango de ATAQUE del jugador
	if body.has_method("enemy"):
		enemy_in_attack_range = body
		# Conectar señal de muerte si el enemigo la tiene
		if body.has_signal("enemy_died") and not body.is_connected("enemy_died", _on_enemy_killed):
			body.enemy_died.connect(_on_enemy_killed)

func _on_player_attack_hit_box_body_exited(body: Node2D) -> void:
	# Enemigo salió del rango de ataque
	if body.has_method("enemy") and body == enemy_in_attack_range:
		enemy_in_attack_range = null

func _on_enemy_killed(_coin_reward: int, hits_received: int = 1) -> void:
	"""Incrementa el contador cuando el jugador mata un enemigo"""
	enemies_killed_this_run += 1
	
	# Calcular puntos según la dificultad (golpes necesarios)
	var points = 1  # Por defecto 1 punto
	if hits_received >= 4:
		points = 2  # Si necesitó 4 o más golpes, cuenta como 2
	
	print("Enemigo eliminado con ", hits_received, " golpes = ", points, " punto(s)")
	
	# Notificar al Network para el sistema de ataques
	if has_node("/root/Network"):
		var network = get_node("/root/Network")
		if network.has_method("add_enemy_points"):
			network.add_enemy_points(points)


func _on_attack_cooldown_timeout() -> void:
	can_take_damage = true

func _on_deal_attack_timer_timeout() -> void:
	Global.player_current_attack = false
	is_attacking = false
	_disable_attack_hitbox()

func _on_player_is_hurt_timeout() -> void:
	is_taking_damage = false
	is_hurt = false

func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false



#Utilidades
func player() -> void:
	pass


func _handle_dash_input() -> void:
	# Verificamos tecla, cooldown, y que no estemos heridos
	if Input.is_action_just_pressed("dash") and can_dash and not is_hurt and not is_dashing:
		start_dash()

func start_dash() -> void:
	is_dashing = true
	can_dash = false
	
	# Cancelar ataque si estabas atacando
	if is_attacking:
		is_attacking = false
		Global.player_current_attack = false
		$deal_attack_timer.stop()
		_disable_attack_hitbox()
	
	# Determinar dirección:
	# 1. Si el jugador presiona una flecha, dash hacia allá.
	# 2. Si no presiona nada, dash hacia donde mira el sprite.
	var input_dir = Input.get_axis("ui_left", "ui_right")
	var dash_dir = 0
	
	if input_dir != 0:
		dash_dir = input_dir
	else:
		dash_dir = -1 if $AnimatedSprite2D.flip_h else 1
		
	# Actualizar hacia donde mira el sprite
	$AnimatedSprite2D.flip_h = dash_dir < 0
	
	# Aplicar velocidad y quitar verticalidad
	velocity.x = dash_dir * DASH_SPEED
	velocity.y = 0 
	
	# Animación y Sonido
	$AnimatedSprite2D.play("dash")
	# sfx_pasos.play() # Opcional: Un sonido de viento o dash quedaría bien aquí
	
	# --- TEMPORIZADOR DE DURACIÓN ---
	# Usamos un timer temporal del árbol para no llenar la escena de nodos
	await get_tree().create_timer(DASH_DURATION).timeout
	end_dash()

func end_dash() -> void:
	is_dashing = false
	velocity.x = 0 # Frenar al terminar (opcional, quítalo si quieres conservar inercia)
	
	# --- TEMPORIZADOR DE COOLDOWN ---
	await get_tree().create_timer(DASH_COOLDOWN).timeout
	can_dash = true
