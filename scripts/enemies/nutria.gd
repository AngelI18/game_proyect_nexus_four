extends EnemyBase

# --- CONFIGURACIÓN DE NUTRIA ---
# Comportamiento: Empieza dormida. Persigue rápido. Ataca girando (Spin).

# Velocidades
@export var walk_speed = 90.0
@export var run_speed = 180.0   # Nutria corre muy rápido
@export var spin_speed = 120.0  # Velocidad mientras gira atacando

# Distancias para IA
@export var attack_range = 40.0    # Distancia para empezar a girar
@export var chase_range = 400.0    # Distancia para perseguir

# Configuración de Animaciones
@export var spin_fps = 12.0

# --- MÁQUINA DE ESTADOS ---
enum State { SLEEP, IDLE, CHASE, JUMP, SPIN_ATTACK, COOLDOWN }
var current_state = State.SLEEP

# Timers internos
var cooldown_timer = 0.0
var spin_duration = 1.5
var spin_timer = 0.0

func _on_ready() -> void:
	# 1. Estadísticas (Igual que Slime/Jabalí)
	speed = walk_speed
	max_health = 60
	damage_from_attack = 15
	coin_reward = 30
	
	# 2. Configuración de Salto
	can_enemy_jump = true
	jump_velocity = -350.0
	jump_height_min = 10.0
	jump_height_max = 80.0
	jump_cooldown = 0.8
	
	# 3. Inicializar vida (Vital para que no muera al primer golpe)
	health = max_health
	
	# 4. Corrección visual inicial (Mira a la derecha por defecto)
	if animated_sprite: 
		animated_sprite.flip_h = false
	
	# Estado inicial
	current_state = State.SLEEP

func _handle_movement(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# Lógica según el Estado actual
	match current_state:
		State.SLEEP:
			_state_sleep(delta)
		State.IDLE:
			_state_idle(delta)
		State.CHASE:
			_state_chase(delta)
		State.JUMP:
			_state_jump(delta)
		State.SPIN_ATTACK:
			_state_spin(delta)
		State.COOLDOWN:
			_state_cooldown(delta)

# --- COMPORTAMIENTO DE LOS ESTADOS ---

func _state_sleep(_delta: float) -> void:
	velocity.x = 0
	# Despierta si detectamos al jugador (la señal _on_player_detected lo activa)

func _state_idle(_delta: float) -> void:
	velocity.x = 0
	if player_chase and player:
		current_state = State.CHASE

func _state_chase(_delta: float) -> void:
	if not player or not is_on_floor():
		return

	var direction = get_direction_to_player()
	var distance = abs(player.global_position.x - global_position.x)
	
	# A. Si está muy cerca -> ATACAR (Giro)
	if distance < attack_range and cooldown_timer <= 0:
		_start_spin_attack()
		return
		
	# B. Si necesita saltar
	if should_jump_to_reach_player():
		perform_jump()
		current_state = State.JUMP
		return

	# C. Perseguir corriendo
	velocity.x = direction * run_speed
	update_sprite_direction(direction)

func _state_spin(delta: float) -> void:
	# Gira y se mueve hacia el jugador
	spin_timer -= delta
	
	if spin_timer <= 0:
		current_state = State.COOLDOWN
		cooldown_timer = 1.0 # Se cansa después de girar
		unlock_attack_direction()
		return
	
	if is_on_floor():
		velocity.x = attack_direction * spin_speed

func _state_jump(_delta: float) -> void:
	# En el aire
	if is_on_floor():
		current_state = State.CHASE # Al caer, sigue persiguiendo
		return
	
	if player:
		var direction = get_direction_to_player()
		velocity.x = direction * walk_speed

func _state_cooldown(_delta: float) -> void:
	velocity.x = 0
	if cooldown_timer <= 0:
		current_state = State.IDLE

# --- UTILIDADES Y TRANSICIONES ---

func _wake_up() -> void:
	velocity.y = -200 # Saltito al despertar
	current_state = State.IDLE

func _start_spin_attack() -> void:
	current_state = State.SPIN_ATTACK
	spin_timer = spin_duration
	lock_attack_direction() # Fija la dirección para no girar loco

# --- ANIMACIONES ---
func _handle_animation() -> void:
	if not animated_sprite: return
	
	match current_state:
		State.SLEEP:
			animated_sprite.play("sleep")
		State.IDLE, State.COOLDOWN:
			animated_sprite.play("idle")
		State.CHASE:
			animated_sprite.play("walk") 
			animated_sprite.speed_scale = 1.5 
		State.JUMP:
			animated_sprite.play("jump")
		State.SPIN_ATTACK:
			animated_sprite.play("spin")
			animated_sprite.speed_scale = 1.0

# --- ARREGLO VISUAL (Flip) ---
func update_sprite_direction(direction: int) -> void:
	if animated_sprite and direction != 0:
		# Lógica invertida para sprites que miran a la DERECHA originalmente
		if current_state != State.SPIN_ATTACK:
			animated_sprite.flip_h = direction < 0

# --- SISTEMA DE DAÑO (Blindado) ---
# --- SISTEMA DE DAÑO (CORREGIDO) ---
func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	# 1. Llamamos a la lógica base del padre (EnemyBase)
	# Esto es VITAL: configura 'player_in_attack_zone = true' para que _handle_combat funcione
	super._on_enemy_hitbox_area_entered(area)
	
	# 2. Lógica específica de la Nutria: Despertar si duerme
	# Solo necesitamos esto, el daño ya lo calculará EnemyBase automáticamente
	if current_state == State.SLEEP:
		_wake_up()
		
	# NOTA: He borrado la línea "take_damage(20, true)".
	# Ahora el daño se gestiona en _handle_combat usando las estadísticas reales de tu jugador.

# Reducción de daño al girar
func _get_damage_reduction() -> float:
	if current_state == State.SPIN_ATTACK:
		return 0.5 
	return 0.0

# Detectar jugador (Visual)
func _on_player_detected(body: Node2D) -> void:
	if current_state == State.SLEEP:
		_wake_up()
	super._on_player_detected(body)
