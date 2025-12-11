extends EnemyBase

class_name pig_boss

# --- REFERENCIAS UI ---
@onready var boss_ui = $BossUI/health_bar # Tu barra de vida

# --- CONFIGURACIÓN DE ESTADÍSTICAS ---
@export_category("Estadísticas de Jefe")
@export var boss_max_health = 5000
@export var walk_speed = 50.0
@export var charge_speed = 250.0 # Velocidad de la embestida
@export var charge_prep_time = 1.0 # Tiempo que avisa antes de cargar

# --- DAÑO DE ATAQUES ---
# Define cuánto duele cada golpe
var dmg_contact = 20    # Solo por tocarlo
var dmg_gore = 40       # Cornada (ataque fuerte)
var dmg_charge = 30     # Embestida

# --- DISTANCIAS DE IA ---
var dist_gore = 70.0    # Distancia para usar Cornada (Cerca)
var dist_charge = 250.0 # Distancia mínima para Cargar (Lejos)

# --- MÁQUINA DE ESTADOS ---
enum State { IDLE, CHASE, PREPARE_CHARGE, CHARGING, GORE_ATTACK, COOLDOWN, DEATH }
var current_state = State.IDLE

# Variables internas
var attack_cooldown = false
var charge_direction = 0

func _ready():
	# 1. Configurar Stats (Heredado de EnemyBase)
	max_health = boss_max_health
	health = max_health
	damage_from_attack = dmg_contact # Daño base por contacto
	coin_reward = 500
	knockback_strength = 0 # ¡Inmune al empuje!
	
	super._ready() # Iniciar EnemyBase
	
	# Configurar UI inicial
	if boss_ui:
		boss_ui.max_value = max_health
		boss_ui.value = health
		boss_ui.visible = false

func _physics_process(delta: float) -> void:
	if current_state == State.DEATH: return
	
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Lógica de Estados
	match current_state:
		State.IDLE:
			_state_idle()
		State.CHASE:
			_state_chase()
		State.PREPARE_CHARGE:
			velocity.x = 0 # Se queda quieto preparando
		State.CHARGING:
			_state_charging(delta)
		State.GORE_ATTACK:
			velocity.x = 0 # Quieto mientras golpea
			
	move_and_slide()
	
	# Mantener combate base (para recibir daño)
	_handle_combat()

# --- LÓGICA DE IA (CEREBRO) ---

func _state_idle():
	velocity.x = 0
	if animated_sprite: animated_sprite.play("idle")
	
	if player_chase and player:
		boss_ui.visible = true
		current_state = State.CHASE

func _state_chase():
	if not player: return
	
	var distance = global_position.distance_to(player.global_position)
	var direction = sign(player.global_position.x - global_position.x)
	
	# Moverse hacia el jugador
	velocity.x = direction * walk_speed
	update_sprite_direction(direction)
	if animated_sprite: animated_sprite.play("walk")
	
	# --- DECISIÓN DE ATAQUE ---
	if attack_cooldown: return # Si está cansado, solo camina
	
	# 1. Si está MUY CERCA -> Cornada (Gore)
	if distance < dist_gore:
		_start_gore_attack()
		
	# 2. Si está LEJOS -> Carga (Charge)
	elif distance > dist_charge:
		_start_prepare_charge()

# --- ATAQUE 1: CORNADA (Cerca) ---
func _start_gore_attack():
	current_state = State.GORE_ATTACK
	damage_from_attack = dmg_gore # Subimos el daño
	
	if animated_sprite:
		animated_sprite.play("attack_cuernada") # Nombre exacto de tu imagen
		# IMPORTANTE: Conectar la señal 'animation_finished' del Sprite al script

# --- ATAQUE 2: CARGA (Lejos) ---
func _start_prepare_charge():
	current_state = State.PREPARE_CHARGE
	
	# Efecto visual de preparación (ej: se pone un poco rojo)
	if animated_sprite: 
		animated_sprite.modulate = Color(1, 0.5, 0.5)
		animated_sprite.play("idle") # O una animación de 'preparar' si tienes
		
	# Esperar 1 segundo antes de salir disparado
	await get_tree().create_timer(charge_prep_time).timeout
	
	if current_state == State.PREPARE_CHARGE: # Si no murió mientras esperaba
		_start_charge()

func _start_charge():
	current_state = State.CHARGING
	damage_from_attack = dmg_charge
	if animated_sprite: 
		animated_sprite.modulate = Color.WHITE # Volver a color normal
		animated_sprite.play("atack_carga") # Nombre exacto de tu imagen (con el error 'atack')
	
	# Fijar dirección hacia donde estaba el jugador
	charge_direction = sign(player.global_position.x - global_position.x)
	if charge_direction == 0: charge_direction = 1 # Evitar 0

func _state_charging(_delta):
	# Correr muy rápido en línea recta
	velocity.x = charge_direction * charge_speed
	update_sprite_direction(charge_direction)
	
	# DETECTAR CHOQUE CON PARED (Fin de la carga)
	if is_on_wall():
		_end_attack_cooldown()

# --- FINALIZACIÓN Y COOLDOWN ---

func _on_animated_sprite_2d_animation_finished():
	# Esta señal se dispara cuando termina una animación (loop desactivado)
	
	if current_state == State.GORE_ATTACK:
		_end_attack_cooldown()
		
	# Nota: La animación de carga ("atack_carga") debería estar en Loop en el editor,
	# porque la carga termina al chocar con pared, no al terminar el gif.

func _end_attack_cooldown():
	current_state = State.CHASE
	damage_from_attack = dmg_contact # Volver daño a normal
	attack_cooldown = true
	
	# Esperar 2 segundos antes de poder atacar de nuevo
	await get_tree().create_timer(2.0).timeout
	attack_cooldown = false

# --- SOBREESCRITURAS NECESARIAS ---

func _on_take_damage(damage_amount: int, is_attack: bool) -> void:
	# Actualizar UI
	if boss_ui: boss_ui.value = health
	
	# Efecto de Furia (Fase 2) al 50% de vida
	if health < (max_health * 0.5):
		walk_speed = 90.0 # Se mueve más rápido enojado
		charge_speed = 350.0 

func _on_death():
	current_state = State.DEATH
	if boss_ui: boss_ui.visible = false
	if animated_sprite: animated_sprite.play("death")
	enemy_died.emit(coin_reward)
	# Esperar animación de muerte
	await animated_sprite.animation_finished
	queue_free()

func apply_knockback():
	pass # El jefe no retrocede con golpes

func update_sprite_direction(direction: int) -> void:
	if animated_sprite and direction != 0:
		# CORRECCIÓN: Como tu dibujo original mira a la IZQUIERDA:
		# - Si la dirección es positiva (Derecha) -> Activamos flip_h (True) para voltearlo.
		# - Si la dirección es negativa (Izquierda) -> Desactivamos flip_h (False) para que se vea normal.
		animated_sprite.flip_h = direction > 0
