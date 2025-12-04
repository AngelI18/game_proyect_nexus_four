extends CharacterBody2D

#Señales
signal health_changed(current_health, max_health)
signal coin_changed(new_coins)

#Constantes de movimiento
const SPEED = 170.0
const JUMP_VELOCITY = -350.0
const KNOCKBACK_STRENGTH = 150.0
const KNOCKBACK_JUMP = -150.0

#Variables de salto
var can_double_jump = true
const MAX_JUMPS = 2
var jumps_remaining = MAX_JUMPS

#Variables de salud
const MAX_HEALTH = 200
var health = MAX_HEALTH
var max_regeneration = MAX_HEALTH * 0.7
var player_alive = true

#Variables de estado
var is_attacking = false
var is_hurt = false
var is_invulnerable = false
var is_taking_damage = false

#Variables de combate
var enemy_in_range: Node2D = null  # Enemigos que pueden hacer daño al jugador
var enemy_in_attack_range: Node2D = null  # Enemigos en rango de ataque del jugador
var can_take_damage = true

#Variables de colección
var coins = 0

#Sistema de checkpoint
var last_safe_position: Vector2 = Vector2.ZERO


#Inicialización
func _ready():
	add_to_group("player")
	_connect_joystick()
	call_deferred("_emit_initial_signals")

func _connect_joystick():
	var joystick = get_tree().get_first_node_in_group("attack_joystick")
	if joystick:
		joystick.attack_triggered.connect(_on_joystick_attack_triggered)

func _emit_initial_signals():
	update_health()
	emit_coin_signal()


#Loop principal
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	_handle_attack()
	_check_death()
	
	move_and_slide()
	
	_update_animation()
	_check_enemy_damage()
	_check_tile_damage()
	_update_safe_position()

#Física y movimiento
func _apply_gravity(delta: float) -> void:
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

func _handle_movement() -> void:
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

#Animaciones
func _update_animation() -> void:
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


#Sistema de combate
func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_perform_attack()

func _perform_attack() -> void:
	Global.player_current_attack = true
	is_attacking = true
	$AnimatedSprite2D.play("attack")
	$deal_attack_timer.start()
	
	# Activar el área de ataque
	_enable_attack_hitbox()

func _enable_attack_hitbox() -> void:
	var attack_hitbox = $player_attack_hit_box/CollisionShape2D
	if attack_hitbox:
		attack_hitbox.disabled = false
		# Posicionar el hitbox según la dirección del jugador
		var offset_x = 12 if not $AnimatedSprite2D.flip_h else -12
		attack_hitbox.position.x = offset_x

func _disable_attack_hitbox() -> void:
	var attack_hitbox = $player_attack_hit_box/CollisionShape2D
	if attack_hitbox:
		attack_hitbox.disabled = true

func _on_joystick_attack_triggered(direction_attack: Vector2) -> void:
	if not is_on_floor() or is_attacking or is_taking_damage:
		return
	
	if abs(direction_attack.x) > 0.3:
		$AnimatedSprite2D.flip_h = direction_attack.x < 0
	
	_perform_attack()

#Sistema de daño
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
	
	print("Daño recibido: ", damage_amount, " | Salud actual: ", health)

func _check_enemy_damage() -> void:
	if enemy_in_range == null:
		return
	
	var damage = 0
	var enemy_type = 1  # Tipo por defecto
	
	# Obtener el tipo de enemigo si tiene el método
	if enemy_in_range.has_method("get_enemy_type"):
		enemy_type = enemy_in_range.get_enemy_type()
	
	# Calcular daño basado en el tipo de enemigo (porcentaje de salud máxima)
	match enemy_type:
		1:  # Enemigo básico - 8% de la salud máxima
			damage = int(MAX_HEALTH * 0.08)
		2:  # Enemigo medio - 12% de la salud máxima
			damage = int(MAX_HEALTH * 0.12)
		3:  # Enemigo fuerte - 16% de la salud máxima
			damage = int(MAX_HEALTH * 0.16)
		_:  # Tipo desconocido - 8% por defecto
			damage = int(MAX_HEALTH * 0.08)
	
	var knockback_direction = (global_position - enemy_in_range.global_position).normalized()
	take_damage(damage, knockback_direction, 2.0)

func _check_tile_damage() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is TileMapLayer:
			_process_tile_collision(collider, collision)

func _process_tile_collision(tile_map: TileMapLayer, collision: KinematicCollision2D) -> void:
	var collision_pos = collision.get_position()
	var collision_normal = collision.get_normal()
	
	#Ajustar la posición de búsqueda del tile según la normal
	var search_offset = collision_normal * -2.0  # Buscar en dirección opuesta a la normal
	var adjusted_pos = collision_pos + search_offset
	
	var tile_coords = tile_map.local_to_map(tile_map.to_local(adjusted_pos))
	var tile_data = tile_map.get_cell_tile_data(tile_coords)
	
	if not tile_data:
		print("No hay tile_data en coords: ", tile_coords)
		return
	
	#Debug: verificar ambas capas de física
	var _layer_0_count = tile_data.get_collision_polygons_count(0)
	var layer_1_count = tile_data.get_collision_polygons_count(1)
	
	#Verificar si es tile de daño
	if layer_1_count > 0:
		var knockback_dir = Vector2.ZERO
		
		#Colisión desde arriba (pinchos en el suelo)
		if abs(collision_normal.y) > 0.5:
			#Empujar hacia arriba, horizontal basado en velocidad actual
			var horizontal_dir = -sign(velocity.x) if velocity.x != 0 else 0
			knockback_dir = Vector2(horizontal_dir, -2)
		#Colisión lateral
		else:
			knockback_dir = Vector2(collision_normal.x * 1.5, -1)
		
		print("Knockback aplicado: ", knockback_dir)
		take_damage(10, knockback_dir, 1.0)

func _check_death() -> void:
	if health <= 0:
		player_alive = false
		health = 0
		queue_free()
		#TODO: Mostrar menú de muerte

#Sistema de salud y regeneración
func update_health() -> void:
	health_changed.emit(health, MAX_HEALTH)

func _on_regen_timer_timeout() -> void:
	if health < max_regeneration:
		health = min(health + 20, max_regeneration)
		update_health()
	elif health <= 0:
		health = 0
		update_health()

#Sistema de monedas
func add_coins(amount: int) -> void:
	coins += amount
	emit_coin_signal()

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

func _on_player_attack_hit_box_body_exited(body: Node2D) -> void:
	# Enemigo salió del rango de ataque
	if body.has_method("enemy") and body == enemy_in_attack_range:
		enemy_in_attack_range = null

#Callbacks de timers
func _on_attack_cooldown_timeout() -> void:
	can_take_damage = true

func _on_deal_attack_timer_timeout() -> void:
	Global.player_current_attack = false
	is_attacking = false
	_disable_attack_hitbox()

func _on_player_is_hurt_timeout() -> void:
	is_hurt = false

func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
	is_taking_damage = false

#Utilidades
func player() -> void:
	pass
	
