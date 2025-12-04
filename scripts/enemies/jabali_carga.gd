extends EnemyBase

#Clase especializada: Jabalí con carga
#Comportamiento: Camina lento, corre rápido después de cargar, ataca en rango

#Configuración de velocidades
@export var walk_speed = 90.0
@export var run_speed = 130.0
@export var attack_speed = 80.0

#Configuración de carga
@export var charge_detection_range = 250.0  # Distancia para iniciar carga
@export var walk_detection_range = 500.0    # Distancia para caminar hacia el jugador
@export var prepare_duration = 1.5
@export var charge_cooldown_time = 3.0
@export var run_duration = 2.5
@export var wall_stun_duration = 1.0
@export var wall_knockback_force = 100.0
@export var edge_detection_distance = 48.0
@export var jump_boost_speed = 220.0
@export var min_jump_distance = 72.0  # 3 tiles de 24x24
@export var aggressive_jump_speed = 250.0  # Velocidad muy alta para persecución aérea
@export var edge_check_ahead = 24.0  # Distancia para detección temprana de bordes              

#Configuración de animaciones
@export var walk_fps = 7.0
@export var run_fps = 10.0
@export var prepare_fps = 7.0
@export var attack_fps = 8.0         

#Estados del jabalí
enum State { IDLE, WALK, RUN, PREPARE, ATTACK, COOLDOWN, JUMP, WALL_STUN }
var current_state = State.IDLE
var prepare_timer = 0.0
var cooldown_timer = 0.0
var run_timer = 0.0
var wall_stun_timer = 0.0
var wall_hit_direction = 0  # Dirección del retroceso al chocar

func _ready() -> void:
	# Configuración de enemigo tipo 2 (medio)
	enemy_type = 2  # 12% de daño
	speed = walk_speed
	max_health = 150
	damage_from_attack = 25
	coin_reward = 35
	knockback_strength = 250.0
	lock_direction_on_attack = true  # NO seguir al jugador durante carga/ataque
	
	can_enemy_jump = true
	jump_velocity = -300.0
	jump_height_min = 10.0
	jump_height_max = 120.0      # Puede saltar a plataformas más altas
	jump_horizontal_max = 150.0
	jump_cooldown = 2.5
	
	super._ready()

func _on_ready() -> void:
	current_state = State.IDLE

func _handle_movement(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if wall_stun_timer > 0:
		wall_stun_timer -= delta
	
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.WALK:
			_state_walk(delta)
		State.PREPARE:
			_state_prepare(delta)
		State.RUN:
			_state_run(delta)
		State.ATTACK:
			_state_attack(delta)
		State.COOLDOWN:
			_state_cooldown(delta)
		State.JUMP:
			_state_jump(delta)
		State.WALL_STUN:
			_state_wall_stun(delta)

func _state_idle(_delta: float) -> void:
	velocity.x = 0
	
	# Actualizar dirección hacia el jugador mientras está idle
	if player:
		var direction = get_direction_to_player()
		update_sprite_direction(direction)
	
	if player_chase:
		current_state = State.WALK

func _state_walk(_delta: float) -> void:
	if not player or not is_on_floor():
		velocity.x = 0
		return
	
	var distance_to_player = abs(player.global_position.x - global_position.x)
	var height_diff = global_position.y - player.global_position.y
	var direction = get_direction_to_player()
	
	if player_in_attack_zone:
		current_state = State.ATTACK
		lock_attack_direction()
		return
	
	# Si jugador está a MAYOR altura (arriba)
	if height_diff > jump_height_min:
		# NO CARGAR si está arriba
		if distance_to_player <= charge_detection_range and cooldown_timer <= 0:
			# Solo intentar saltar si está a la distancia correcta (3 tiles)
			if distance_to_player >= min_jump_distance and can_jump:
				if _try_jump_to_player(direction, height_diff, distance_to_player):
					current_state = State.JUMP
					return
		
		# Detectar borde cercano y calcular salto con impulso (solo si está en plataforma)
		if _is_near_edge(direction) and can_jump and _is_on_platform():
			_perform_calculated_jump_from_edge(direction, height_diff, distance_to_player)
			current_state = State.JUMP
			return
		
		# Caminar hacia el jugador si no puede saltar aún
		velocity.x = direction * walk_speed
		update_sprite_direction(direction)
		return
	
	# Jugador está al mismo nivel o abajo
	if should_jump_to_reach_player():
		perform_jump()
		current_state = State.JUMP
		return
	
	if is_colliding_with_terrain():
		velocity.x = 0
		return
	
	# Detectar borde peligroso ANTES de moverse
	if _is_approaching_edge(direction):
		# Hay un borde adelante, intentar saltar si hay plataforma cercana
		if can_jump and _has_platform_ahead(direction):
			perform_jump()
			velocity.x = direction * walk_speed * 1.5
			current_state = State.JUMP
			return
		else:
			# No puede saltar o no hay plataforma, detenerse
			velocity.x = 0
			update_sprite_direction(-direction)  # Voltear
			return
	
	if distance_to_player <= charge_detection_range and cooldown_timer <= 0:
		_start_prepare(direction)
	elif distance_to_player <= walk_detection_range:
		velocity.x = direction * walk_speed
		update_sprite_direction(direction)
	else:
		velocity.x = 0
		current_state = State.IDLE

func _state_prepare(delta: float) -> void:
	velocity.x = 0
	prepare_timer -= delta
	
	if prepare_timer <= 0:
		_start_run()

func _state_run(delta: float) -> void:
	if not is_on_floor():
		velocity.x = 0
		run_timer = 0.0
		current_state = State.WALK
		unlock_attack_direction()
		return
	
	run_timer -= delta
	
	# Si alcanza al jugador, atacar
	if player_in_attack_zone:
		current_state = State.ATTACK
		run_timer = 0.0
		return
	
	# Detectar colisión con TERRENO durante carga (no con jugador)
	if is_colliding_with_terrain():
		# Retroceso pequeño al chocar con pared
		wall_hit_direction = -attack_direction  # Dirección opuesta a la carga
		velocity.x = wall_hit_direction * wall_knockback_force
		wall_stun_timer = wall_stun_duration
		run_timer = 0.0
		current_state = State.WALL_STUN
		# NO desbloquear dirección aún, esperar al stun
		return
	
	# Detectar borde peligroso durante carga
	if _is_approaching_edge(attack_direction):
		# Detenerse antes de caer
		velocity.x = 0
		run_timer = 0.0
		current_state = State.IDLE
		unlock_attack_direction()
		return
	
	# Continuar corriendo en la dirección de carga
	# NO importa si el jugador salta, sigue corriendo en línea recta
	if run_timer <= 0:
		current_state = State.WALK
		unlock_attack_direction()
	else:
		velocity.x = attack_direction * run_speed

func _state_attack(_delta: float) -> void:
	if not is_on_floor():
		velocity.x = 0
		return
	
	if not player_in_attack_zone:
		if run_timer > 0:
			current_state = State.RUN
		else:
			current_state = State.WALK
			unlock_attack_direction()  # Liberar dirección al salir de ATTACK
		return
	
	# Mantener la dirección de ataque usando attack_direction del padre
	velocity.x = attack_direction * attack_speed
	# El flip ya está configurado desde lock_attack_direction

func _state_cooldown(_delta: float) -> void:
	velocity.x = 0
	
	# Actualizar dirección hacia el jugador durante cooldown
	if player:
		var direction = get_direction_to_player()
		update_sprite_direction(direction)
	
	if cooldown_timer <= 0:
		if player_chase:
			current_state = State.WALK
		else:
			current_state = State.IDLE

func _state_jump(_delta: float) -> void:
	if not player:
		if is_on_floor():
			current_state = State.IDLE
		return
	
	var direction = get_direction_to_player()
	# Mantener velocidad agresiva si ya la tiene, sino usar walk_speed
	if abs(velocity.x) > walk_speed * 1.5:
		pass  # Mantener la velocidad actual (agresiva)
	else:
		velocity.x = direction * walk_speed
	
	update_sprite_direction(direction)
	
	if is_on_floor():
		if run_timer > 0:
			current_state = State.RUN
		else:
			current_state = State.WALK

func _state_wall_stun(_delta: float) -> void:
	"""Estado de aturdimiento al chocar con pared
	- Primera fase (50%): Retroceso pequeño
	- Segunda fase (50%): Voltear hacia el jugador (flip.h) y buscarlo
	"""
	if not is_on_floor():
		velocity.x = 0
		return
	
	var stun_progress = 1.0 - (wall_stun_timer / wall_stun_duration)
	
	if stun_progress < 0.5:
		# PRIMERA FASE: Retroceso pequeño que disminuye
		var knockback_multiplier = (0.5 - stun_progress) * 2.0  # 1.0 a 0.0
		velocity.x = wall_hit_direction * wall_knockback_force * knockback_multiplier
	else:
		# SEGUNDA FASE: Frenar y voltear hacia el jugador
		velocity.x = 0
		
		# Desbloquear dirección de ataque y voltear hacia el jugador
		if is_attacking:
			unlock_attack_direction()
		
		# Buscar al jugador visualmente (flip.h)
		if player:
			var direction = get_direction_to_player()
			update_sprite_direction(direction)
	
	# Al terminar el stun, si ve al jugador, seguirlo
	if wall_stun_timer <= 0:
		velocity.x = 0
		
		# Si el jugador está visible, entrar en WALK para seguirlo
		if player and player_chase:
			current_state = State.WALK
		else:
			# Si no hay jugador, entrar en COOLDOWN
			current_state = State.COOLDOWN
			cooldown_timer = charge_cooldown_time

func _start_prepare(_direction: int) -> void:
	current_state = State.PREPARE
	prepare_timer = prepare_duration
	velocity.x = 0
	lock_attack_direction()  # Bloquear dirección al preparar carga

func _start_run() -> void:
	current_state = State.RUN
	run_timer = run_duration
	cooldown_timer = charge_cooldown_time

func _handle_animation() -> void:
	if not animated_sprite:
		return
	
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
			animated_sprite.speed_scale = 1.0
		State.WALK:
			animated_sprite.play("walk")
			animated_sprite.speed_scale = walk_fps / 7.0
		State.PREPARE:
			animated_sprite.play("charge")
			animated_sprite.speed_scale = prepare_fps / 7.0
		State.RUN:
			animated_sprite.play("walk")
			animated_sprite.speed_scale = run_fps / 7.0
		State.ATTACK:
			animated_sprite.play("attack")
			animated_sprite.speed_scale = attack_fps / 7.0
		State.COOLDOWN:
			animated_sprite.play("idle")
			animated_sprite.speed_scale = 1.0
		State.JUMP:
			animated_sprite.play("jump")
			animated_sprite.speed_scale = 1.0
		State.WALL_STUN:
			animated_sprite.play("idle")
			animated_sprite.speed_scale = 1.0


func _is_approaching_edge(direction: float) -> bool:
	"""Detecta si está cerca de un borde peligroso (detección temprana)"""
	if not is_on_floor():
		return false
	
	var space_state = get_world_2d().direct_space_state
	# Revisar un poco adelante del personaje
	var check_pos = global_position + Vector2(direction * edge_check_ahead, 0)
	
	var query = PhysicsRayQueryParameters2D.create(
		check_pos,
		check_pos + Vector2(0, 32)  # Revisar 32px hacia abajo
	)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()  # Si no hay piso = hay borde


func _is_near_edge(direction: float) -> bool:
	"""Detecta si hay un borde a 3 tiles de distancia en la dirección de movimiento"""
	if not is_on_floor():
		return false
	
	var space_state = get_world_2d().direct_space_state
	var check_pos = global_position + Vector2(direction * edge_detection_distance, 10)
	
	var query = PhysicsRayQueryParameters2D.create(
		check_pos,
		check_pos + Vector2(0, 20)
	)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()


func _is_on_platform() -> bool:
	if not is_on_floor():
		return false
	
	# Verificar que hay terreno sólido debajo
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(0, 20)
	)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	return not result.is_empty()


func _has_platform_ahead(direction: float) -> bool:
	"""Detecta si hay una plataforma alcanzable con un salto hacia adelante"""
	var space_state = get_world_2d().direct_space_state
	
	# Buscar plataforma en rango de salto horizontal
	for distance in range(48, 120, 24):  # De 2 a 5 tiles
		var check_pos = global_position + Vector2(direction * distance, -32)  # Revisar arriba también
		
		# Raycast hacia abajo buscando plataforma
		var query = PhysicsRayQueryParameters2D.create(
			check_pos,
			check_pos + Vector2(0, 100)  # Buscar hasta 100px abajo
		)
		query.collision_mask = 1
		
		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			# Hay plataforma, verificar que esté a altura alcanzable
			var platform_height = result.position.y - global_position.y
			if platform_height < 80 and platform_height > -80:  # Dentro de rango vertical
				return true
	
	return false


func _try_jump_to_player(_direction: float, height_diff: float, horizontal_dist: float) -> bool:
	"""Intenta saltar aleatoriamente hacia el jugador cuando está arriba"""
	# Solo saltar si está a la distancia adecuada (3 tiles)
	if horizontal_dist < min_jump_distance:
		return false
	
	if randf() > 0.4:
		return false
	
	if height_diff > jump_height_max or horizontal_dist > jump_horizontal_max:
		return false
	
	# Salto agresivo con velocidad aumentada
	perform_jump()
	velocity.x = get_direction_to_player() * aggressive_jump_speed
	return true


func _perform_calculated_jump_from_edge(direction: float, height_diff: float, horizontal_dist: float) -> void:
	"""Calcula y ejecuta un salto con impulso desde el borde para alcanzar al jugador"""
	if height_diff > jump_height_max:
		height_diff = jump_height_max
	
	var gravity_strength = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	# Calcular tiempo de vuelo basado en altura
	var time_to_peak = sqrt(2.0 * height_diff / gravity_strength)
	var total_flight_time = time_to_peak * 2.0
	
	# Calcular velocidad horizontal necesaria (con velocidad agresiva)
	var required_horizontal_speed = horizontal_dist / total_flight_time
	required_horizontal_speed = clamp(required_horizontal_speed, walk_speed, aggressive_jump_speed)
	
	# Aplicar salto con velocidad calculada
	var jump_force = jump_velocity
	if height_diff > jump_height_min * 2:
		jump_force *= 1.15
	
	velocity.y = jump_force
	velocity.x = direction * required_horizontal_speed
	update_sprite_direction(int(direction))
	can_jump = false
	jump_timer = jump_cooldown


func _get_damage_reduction() -> float:
	# Durante el ataque (carga), reduce el daño en un 60%
	if current_state == State.ATTACK:
		return 0.6
	# Durante la preparación, reduce el daño en un 30%
	elif current_state == State.PREPARE:
		return 0.3
	return 0.0

func _on_take_damage(_damage_amount: int, _is_attack: bool) -> void:
	if current_state == State.PREPARE:
		current_state = State.COOLDOWN
		cooldown_timer = charge_cooldown_time
	elif current_state == State.RUN:
		run_timer = max(0, run_timer - 1.0)

func _on_player_detected(_body: Node2D) -> void:
	if current_state == State.IDLE:
		current_state = State.WALK

func _on_player_lost(_body: Node2D) -> void:
	current_state = State.IDLE
	prepare_timer = 0.0
	cooldown_timer = 0.0
	run_timer = 0.0
