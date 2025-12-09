extends CharacterBody2D

class_name EnemyBase

#Señales
signal enemy_died(coin_reward: int)
signal enemy_damaged(damage_amount: int, remaining_health: int)

#Estadísticas configurables
@export_category("Estadísticas Básicas")
@export var speed = 100
@export var max_health = 100
@export_enum("Básico:1", "Medio:2", "Fuerte:3") var enemy_type = 1  # Tipo de enemigo para cálculo de daño
@export var damage_from_attack = 25  # Daño que recibe del ataque del jugador
@export var coin_reward = 20

@export_category("Sistema de Combate")
@export var knockback_strength = 200.0
@export var knockback_duration = 0.3
@export var lock_direction_on_attack = false  # Si true, no sigue al jugador durante ataque

@export_category("Sistema de Salto")
@export var can_enemy_jump = false
@export var jump_velocity = -300.0
@export var jump_height_min = 10.0
@export var jump_height_max = 48.0
@export var jump_horizontal_max = 150.0
@export var jump_cooldown = 0.5

#Variables internas - estado
var health = 0
var player = null
var player_chase = false
var player_in_attack_zone = false
var can_take_damage = true
var is_taking_knockback = false

#Variables de combate y dirección
var attack_direction = 0  # Dirección guardada para ataques
var is_attacking = false  # Si está en modo ataque

#Variables de salto
var can_jump = true
var jump_timer = 0.0

#Nodos requeridos (deben existir en la escena hija)
@onready var animated_sprite = $AnimatedSprite2D
@onready var damage_cooldown = $take_damage_cooldown

func _ready() -> void:
	health = max_health
	_on_ready()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if can_enemy_jump and jump_timer > 0:
		jump_timer -= delta
		if jump_timer <= 0:
			can_jump = true
	
	if is_taking_knockback:
		move_and_slide()
		return
	
	_handle_movement(delta)
	_handle_animation()
	
	move_and_slide()
	_handle_combat()
	_update_health_bar()

#Funciones virtuales (override en clases hijas)
func _on_ready() -> void:
	pass

func _handle_movement(_delta: float) -> void:
	#Comportamiento por defecto: perseguir al jugador si está en el suelo
	if player_chase and is_on_floor():
		var direction = get_movement_direction()
		velocity.x = direction * speed
		update_sprite_direction(direction)
	else:
		velocity.x = 0

func _handle_animation() -> void:
	if not animated_sprite:
		return
	if abs(velocity.x) > 0:
		
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

#Sistema de salto heredable
func should_jump_to_reach_player() -> bool:
	if not can_enemy_jump or not can_jump or not is_on_floor() or not player:
		return false
	
	var height_diff = player.global_position.y - global_position.y
	var horizontal_distance = abs(player.global_position.x - global_position.x)
	
	# Solo saltar si el jugador está significativamente más alto
	if height_diff > -jump_height_min or height_diff < -jump_height_max:
		return false
	
	# Debe estar a una distancia razonable horizontal
	if horizontal_distance > jump_horizontal_max or horizontal_distance < 20:
		return false
	
	# Verificar que hay un obstáculo o plataforma que impide el camino
	# Solo salta si realmente es necesario para alcanzar al jugador
	var space_state = get_world_2d().direct_space_state
	var direction = sign(player.global_position.x - global_position.x)
	
	# Raycast hacia adelante para detectar obstáculos
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(direction * 30, 0)
	)
	query.collision_mask = 1  # Solo terreno
	
	var result = space_state.intersect_ray(query)
	
	# Solo saltar si hay un obstáculo adelante Y el jugador está arriba
	return result.size() > 0

func perform_jump() -> void:
	velocity.y = jump_velocity
	can_jump = false
	jump_timer = jump_cooldown

func is_colliding_with_terrain() -> bool:
	"""Verifica si está chocando con terreno (Layer 1), no con el jugador u otros enemigos
	Útil para detectar paredes/obstáculos reales vs colisiones con entidades"""
	if not is_on_wall():
		return false
	
	# Verificar las colisiones de pared
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Solo considerar colisión con terreno (TileMapLayer o StaticBody2D en Layer 1)
		if collider is TileMapLayer:
			return true
		if collider is StaticBody2D and (collider.collision_layer & 1) != 0:
			return true
	
	return false

func is_player_on_platform() -> bool:
	"""Verifica si el jugador está en una plataforma (no en el aire)
	Útil para decisiones de salto hacia plataformas superiores"""
	if not player or not player is CharacterBody2D:
		return false
	return player.is_on_floor()

func should_jump_to_higher_platform(random_jump_chance: float = 0.015) -> bool:
	"""Determina si debe saltar a una plataforma más alta donde está el jugador
	
	Args:
		random_jump_chance: Probabilidad (0.0-1.0) de saltar si el jugador está en el aire
							Por defecto 0.015 (1.5%)
	
	Returns:
		true si debe intentar saltar a la plataforma superior
	"""
	if not player or not is_on_floor():
		return false
	
	var height_diff = global_position.y - player.global_position.y  # Positivo si jugador está arriba
	
	# Si el jugador está más alto
	if height_diff > jump_height_min and height_diff < jump_height_max:
		# Verificar si el jugador está en una plataforma
		if is_player_on_platform():
			# El jugador está en plataforma, intentar saltar
			return should_jump_to_reach_player()
		else:
			# El jugador está en el aire, probabilidad baja configurable
			return randf() < random_jump_chance
	
	return false

#Sistema de dirección y ataque
func get_direction_to_player() -> int:
	"""Retorna la dirección hacia el jugador (-1 izquierda, 1 derecha, 0 sin jugador)"""
	if not player:
		return 0
	return sign(player.global_position.x - global_position.x)

func lock_attack_direction() -> void:
	"""Guarda la dirección actual hacia el jugador para ataques"""
	attack_direction = get_direction_to_player()
	is_attacking = true
	if animated_sprite and attack_direction != 0:
		animated_sprite.flip_h = attack_direction > 0

func unlock_attack_direction() -> void:
	"""Libera la dirección de ataque para volver a seguir al jugador"""
	is_attacking = false
	attack_direction = 0

func get_movement_direction() -> int:
	"""Retorna la dirección de movimiento según el estado de ataque"""
	if is_attacking and lock_direction_on_attack:
		return attack_direction
	return get_direction_to_player()

func update_sprite_direction(direction: int) -> void:
	"""Actualiza el flip del sprite solo si no está en ataque bloqueado"""
	if animated_sprite and direction != 0:
		if not (is_attacking and lock_direction_on_attack):
			animated_sprite.flip_h = direction > 0

#Sistema de combate
func _handle_combat() -> void:
	if not player_in_attack_zone or not can_take_damage:
		return
	
	if not Global.player_current_attack:
		return
	
	take_damage(damage_from_attack, true)

func _get_damage_reduction() -> float:
	# Override en clases hijas para reducción de daño en estados especiales
	return 0.0

func take_damage(damage_amount: int, is_attack: bool = false) -> void:
	# Llamar primero a _get_damage_reduction para permitir estados especiales
	var damage_reduction = _get_damage_reduction()
	var final_damage = max(1, int(damage_amount * (1.0 - damage_reduction)))
	
	health -= final_damage
	can_take_damage = false
	
	if damage_cooldown:
		damage_cooldown.start()
	
	# Solo aplicar knockback si no hay reducción total
	if damage_reduction < 0.9:
		apply_knockback()
	
	_show_damage_feedback()
	_on_take_damage(final_damage, is_attack)
	
	# Emitir señal de daño
	enemy_damaged.emit(final_damage, health)
	
	var attack_type = "ataque" if is_attack else "colisión"
	if damage_reduction > 0:
		print(name, " recibió ", final_damage, "/", damage_amount, " de daño (", attack_type, ", -", int(damage_reduction * 100), "%) | Salud: ", health)
	else:
		print(name, " recibió ", final_damage, " de daño (", attack_type, ") | Salud: ", health)
	
	if health <= 0:
		_on_death()

func _show_damage_feedback() -> void:
	if not animated_sprite:
		return
	
	animated_sprite.modulate = Color(1, 0.3, 0.3, 1)
	await get_tree().create_timer(0.15).timeout
	if animated_sprite:
		animated_sprite.modulate = Color(1, 1, 1, 1)

func apply_knockback() -> void:
	if player:
		var knockback_direction = (global_position - player.global_position).normalized()
		velocity.x = knockback_direction.x * knockback_strength
		is_taking_knockback = true
		await get_tree().create_timer(knockback_duration).timeout
		is_taking_knockback = false

func _on_take_damage(_damage_amount: int, _is_attack: bool) -> void:
	pass

func _on_death() -> void:
	# Emitir señal de muerte con las monedas a otorgar
	enemy_died.emit(coin_reward)
	
	# Las clases hijas pueden override este método para efectos especiales
	if player and player.has_method("add_coins"):
		player.add_coins(coin_reward)
	queue_free()

func get_enemy_type() -> int:
	return enemy_type

#Sistema de salud visual
func _update_health_bar() -> void:
	if not has_node("health_bar"):
		return
	
	var healthbar = $health_bar
	healthbar.value = health
	healthbar.visible = health < max_health

#Detección de jugador
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player = body
		player_chase = true
		_on_player_detected(body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player = null
		player_chase = false
		_on_player_lost(body)

func _on_player_detected(_body: Node2D) -> void:
	pass

func _on_player_lost(_body: Node2D) -> void:
	pass

#Zona de ataque
func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	# Detectar el área de ataque del jugador (player_attack_hit_box)
	if area.name == "player_attack_hit_box" and area.get_parent().has_method("player"):
		player_in_attack_zone = true
		_on_attack_zone_entered(area.get_parent())

func _on_enemy_hitbox_area_exited(area: Area2D) -> void:
	# El área de ataque del jugador salió
	if area.name == "player_attack_hit_box" and area.get_parent().has_method("player"):
		player_in_attack_zone = false
		_on_attack_zone_exited(area.get_parent())

func _on_attack_zone_entered(_body: Node2D) -> void:
	pass

func _on_attack_zone_exited(_body: Node2D) -> void:
	pass

#Callbacks de timers
func _on_take_damage_cooldown_timeout() -> void:
	can_take_damage = true
	if damage_cooldown:
		damage_cooldown.stop()

#Identificador
func enemy() -> void:
	pass
