extends EnemyBase

# --- CONFIGURACIÓN DE NUTRIA (Ágil y con Giro) ---
# Comportamiento: Empieza dormida. Al despertar es muy rápida. Ataca girando.

@export var walk_speed = 90.0
@export var run_speed = 180.0  # Nutria corre muy rápido
@export var spin_speed = 120.0 # Velocidad mientras gira atacando

# Distancias
@export var attack_range = 40.0   # Distancia para empezar a girar
@export var chase_range = 400.0   # Distancia para perseguir

# Animaciones
@export var spin_fps = 12.0

# --- ESTADOS (La lógica del Jabalí adaptada) ---
enum State { SLEEP, IDLE, CHASE, JUMP, SPIN_ATTACK, COOLDOWN }
var current_state = State.SLEEP

var cooldown_timer = 0.0
var spin_duration = 1.5
var spin_timer = 0.0

func _on_ready() -> void:
	# Configuración base
	speed = walk_speed
	max_health = 60    # Menos vida que el jabalí
	damage_from_attack = 15
	coin_reward = 30
	
	# Configuración de salto (Es saltarina)
	can_enemy_jump = true
	jump_velocity = -350.0
	jump_height_min = 10.0
	jump_height_max = 80.0
	jump_cooldown = 0.8
	
	# Corrección visual inicial
	if animated_sprite: 
		animated_sprite.flip_h = false
	
	# Estado inicial obligatorio
	current_state = State.SLEEP

func _handle_movement(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# MÁQUINA DE ESTADOS (Como el Jabalí)
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

# --- LÓGICA DE CADA ESTADO ---

func _state_sleep(_delta: float) -> void:
	velocity.x = 0
	# Si detectamos al jugador (gracias a la señal _on_player_detected), despertamos
	if player_chase and player:
		_wake_up()

func _state_idle(_delta: float) -> void:
	velocity.x = 0
	if player_chase and player:
		current_state = State.CHASE

func _state_chase(_delta: float) -> void:
	if not player or not is_on_floor():
		return

	var direction = get_direction_to_player()
	var distance = abs(player.global_position.x - global_position.x)
	
	# 1. Si está muy cerca -> ATACAR (Giro)
	if distance < attack_range and cooldown_timer <= 0:
		_start_spin_attack()
		return
		
	# 2. Si necesita saltar (Lógica heredada y adaptada)
	if should_jump_to_reach_player():
		perform_jump()
		current_state = State.JUMP
		return

	# 3. Perseguir
	velocity.x = direction * run_speed
	update_sprite_direction(direction)

func _state_spin(delta: float) -> void:
	# Ataque giratorio (Como el RUN del Jabalí pero con daño constante)
	spin_timer -= delta
	
	if spin_timer <= 0:
		current_state = State.COOLDOWN
		cooldown_timer = 1.0 # Descanso después de girar
		unlock_attack_direction()
		return
	
	# Moverse hacia el jugador mientras gira
	if is_on_floor():
		velocity.x = attack_direction * spin_speed

func _state_jump(_delta: float) -> void:
	# Lógica de aire
	if is_on_floor():
		current_state = State.CHASE # Al tocar suelo, vuelve a perseguir
		return
	
	# Moverse en el aire
	if player:
		var direction = get_direction_to_player()
		velocity.x = direction * walk_speed

func _state_cooldown(_delta: float) -> void:
	velocity.x = 0
	if cooldown_timer <= 0:
		current_state = State.IDLE

# --- TRANSICIONES Y UTILIDADES ---

func _wake_up() -> void:
	velocity.y = -200 # Saltito de susto al despertar
	current_state = State.IDLE

func _start_spin_attack() -> void:
	current_state = State.SPIN_ATTACK
	spin_timer = spin_duration
	lock_attack_direction() # Fija la dirección para no girar loco

# --- ANIMACIONES (Mapping limpio) ---
func _handle_animation() -> void:
	if not animated_sprite: return
	
	match current_state:
		State.SLEEP:
			animated_sprite.play("sleep")
		State.IDLE, State.COOLDOWN:
			animated_sprite.play("idle") # O usa las fotos de sleep si quieres que parezca cansada
		State.CHASE:
			animated_sprite.play("walk") # Usa tus sprites de run
			animated_sprite.speed_scale = 1.5 # Corre rápido visualmente
		State.JUMP:
			animated_sprite.play("jump")
		State.SPIN_ATTACK:
			animated_sprite.play("spin")
			animated_sprite.speed_scale = 1.0

# --- ARREGLO DE DIRECCIÓN VISUAL ---
func update_sprite_direction(direction: int) -> void:
	if animated_sprite and direction != 0:
		# Lógica invertida para tus sprites que miran a la derecha
		if current_state != State.SPIN_ATTACK:
			animated_sprite.flip_h = direction < 0

# --- SISTEMA DE DAÑO (Blindado) ---
func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	# 1. Ignorar sensores propios o del jugador
	if "detection" in area.name or "coin" in area.name: return

	# 2. Imprimir para debug
	print("Nutria golpeada por: ", area.name)
	
	# 3. Recibir daño (Sin cambiar de estado a lo loco)
	take_damage(20, true)
	_show_damage_feedback()
	
	# NOTA: No forzamos cambio de estado aquí. 
	# Si le pegas mientras duerme, se despertará solo porque entra en _state_sleep -> wake_up

# Reducción de daño al girar (Spin)
func _get_damage_reduction() -> float:
	if current_state == State.SPIN_ATTACK:
		return 0.5 # Resistente mientras gira
	return 0.0

# Detección (Necesaria para despertar)
func _on_player_detected(body: Node2D) -> void:
	if current_state == State.SLEEP:
		_wake_up()
	super._on_player_detected(body)
