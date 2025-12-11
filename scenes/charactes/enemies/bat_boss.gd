extends EnemyBase

class_name BatBoss

# --- REFERENCIAS UI ---
@onready var boss_ui = $BossUI/health_bar

# --- ESTADÍSTICAS ---
@export_category("Estadísticas Murciélago")
@export var boss_max_health = 10000
@export var fly_speed = 100.0       # Velocidad normal de vuelo
@export var chase_speed = 160.0     # Velocidad cuando te ve
@export var attack_range = 55.0     # Distancia para soltar la cuchillada

# --- DAÑO ---
var dmg_contact = 25   # Si lo tocas volando
var dmg_slash = 45     # Si te pega el cuchillazo

# --- ESTADOS ---
enum State { IDLE, CHASE, ATTACK, COOLDOWN, DEATH, HURT }
var current_state = State.IDLE
var can_attack = true

func _ready():
	# Configurar stats del padre
	max_health = boss_max_health
	health = max_health
	damage_from_attack = dmg_contact
	coin_reward = 800
	knockback_strength = 50.0 # Retrocede un poco, pero no mucho
	
	super._ready()
	
	# Configurar UI
	if boss_ui:
		boss_ui.max_value = max_health
		boss_ui.value = health
		boss_ui.visible = false

func _physics_process(delta: float) -> void:
	if current_state == State.DEATH: return

	# ¡IMPORTANTE! NO aplicamos gravedad aquí porque vuela.
	
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			velocity = Vector2.ZERO # Se detiene para acuchillar
		State.COOLDOWN:
			_state_cooldown(delta)
		State.HURT:
			move_and_slide() # Se mueve solo por el empuje del golpe
			return 

	move_and_slide()
	_handle_combat()

# --- LÓGICA DE ESTADOS ---

func _state_idle(delta):
	# Flotar suavemente arriba y abajo
	velocity.x = move_toward(velocity.x, 0, 10)
	velocity.y = sin(Time.get_ticks_msec() * 0.002) * 20 
	
	if animated_sprite: animated_sprite.play("idle")
	
	if player_chase and player:
		boss_ui.visible = true
		current_state = State.CHASE

func _state_chase(delta):
	if not player: return
	
	var distance = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()
	
	# Volar hacia el jugador
	velocity = direction * chase_speed
	
	# Girar sprite
	update_sprite_direction(sign(direction.x))
	
	if animated_sprite: animated_sprite.play("walk") # O "fly" si tienes
	
	# Si está cerca, ACUCHILLAR
	if distance < attack_range and can_attack:
		_start_attack()

func _start_attack():
	current_state = State.ATTACK
	can_attack = false
	damage_from_attack = dmg_slash # Aumentar daño
	
	if animated_sprite:
		animated_sprite.play("attack")
		# Recuerda conectar la señal animation_finished

func _state_cooldown(delta):
	# Alejarse un poco después de atacar (Hit & Run)
	if player:
		var dir_away = (global_position - player.global_position).normalized()
		velocity = dir_away * (fly_speed * 0.5) # Retrocede lento
	
	if animated_sprite: animated_sprite.play("idle")
	
	# Esperar 1.5 segundos (usando un timer simple o contador)
	await get_tree().create_timer(1.5).timeout
	if current_state == State.COOLDOWN:
		can_attack = true
		current_state = State.CHASE

# --- EVENTOS ---

func _on_animated_sprite_2d_animation_finished():
	if current_state == State.ATTACK:
		damage_from_attack = dmg_contact # Daño normal
		current_state = State.COOLDOWN
	
	if current_state == State.DEATH:
		enemy_died.emit(coin_reward)
		queue_free()

func _on_take_damage(damage_amount: int, is_attack: bool) -> void:
	if boss_ui: boss_ui.value = health
	
	# Opcional: Pequeña animación de dolor
	if animated_sprite and current_state != State.ATTACK and current_state != State.DEATH:
		animated_sprite.play("hurt")
		# Volver al estado anterior después de un momento
		await get_tree().create_timer(0.2).timeout
		if current_state != State.DEATH:
			current_state = State.CHASE

func _on_death():
	current_state = State.DEATH
	boss_ui.visible = false
	if animated_sprite: animated_sprite.play("death")

# CORRECCIÓN DE GIRO
func update_sprite_direction(direction: int) -> void:
	if animated_sprite and direction != 0:
		# Invertimos la lógica.
		# Prueba con 'direction > 0'. Si sigue mal, prueba con 'direction < 0'.
		# Depende de hacia dónde mire tu dibujo original en la carpeta de assets.
		animated_sprite.flip_h = direction > 0
