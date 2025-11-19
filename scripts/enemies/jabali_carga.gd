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
@export var wall_stun_duration = 1.0        # Duración del stun al chocar
@export var wall_knockback_force = 100.0    # Fuerza del retroceso              

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
	
	# Si está en zona de ataque, atacar directamente
	if player_in_attack_zone:
		current_state = State.ATTACK
		lock_attack_direction()
		return
	
	# Verificar si el jugador está a MAYOR altura (en otra plataforma)
	if height_diff > jump_height_min:
		if should_jump_to_higher_platform():
			perform_jump()
			current_state = State.JUMP
			return
	# Verificar si hay obstáculo al mismo nivel
	elif should_jump_to_reach_player():
		perform_jump()
		current_state = State.JUMP
		return
	
	# Si choca con terreno (no jugador), detenerse
	if is_colliding_with_terrain():
		velocity.x = 0
		return
	
	# LÓGICA DE DISTANCIA:
	# - Si está CERCA (dentro de charge_detection_range) → CARGAR
	# - Si está LEJOS (dentro de walk_detection_range) → CAMINAR
	# - Si está MUY LEJOS (fuera de walk_detection_range) → IDLE
	
	if distance_to_player <= charge_detection_range and cooldown_timer <= 0:
		# CERCA: Iniciar carga
		_start_prepare(direction)
	elif distance_to_player <= walk_detection_range:
		# LEJOS: Caminar hacia el jugador
		velocity.x = direction * walk_speed
		update_sprite_direction(direction)
	else:
		# MUY LEJOS: Detenerse
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
