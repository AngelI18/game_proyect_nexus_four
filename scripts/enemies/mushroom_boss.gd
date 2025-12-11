extends CharacterBody2D

# --- AJUSTE DE MIRADA ---
const SPRITE_MIRA_A_LA_IZQUIERDA = true

# --- CONFIGURACIÓN ---
@export var boss_walk_speed = 60.0
@export var attack_range = 50.0 
@export var detection_range = 300.0

enum State { IDLE, TAUNT, CHASE, ATTACK, COOLDOWN, DEATH }
var current_state = State.IDLE
var has_dealt_damage = false 
var can_attack = true
var current_attack_anim = "" 

# TUS 3 ATAQUES ACTUALES
var lista_de_ataques = ["attack_1", "attack_2", "attack_4"]

# Referencias
var player: CharacterBody2D = null 
var player_chase = false

# Stats
var damage_from_attack = 35
var health = 500
var max_health = 500

@onready var animated_sprite = $AnimatedSprite2D 
@onready var attack_area = $"Atack area" 
@onready var enemy_hitbox = $EnemyHitbox

# --- NUEVO: CONECTAMOS LA BARRA DE VIDA ---
@onready var health_bar = $health_bar 

func _ready() -> void:
	# 1. CONFIGURAMOS LA BARRA DE VIDA AL INICIO
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	
	if attack_area:
		attack_area.monitoring = true
		attack_area.monitorable = true

	# Prevención de bucles
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("taunt"):
			animated_sprite.sprite_frames.set_animation_loop("taunt", false)
		
		for nombre_ataque in lista_de_ataques:
			if animated_sprite.sprite_frames.has_animation(nombre_ataque):
				animated_sprite.sprite_frames.set_animation_loop(nombre_ataque, false)
	
	# Conexiones
	if animated_sprite:
		if animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_animation_finished)
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	if enemy_hitbox:
		if not enemy_hitbox.area_entered.is_connected(_on_enemy_hitbox_area_entered):
			enemy_hitbox.area_entered.connect(_on_enemy_hitbox_area_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if current_state == State.DEATH:
		move_and_slide()
		return 

	_state_machine_logic(delta)
	move_and_slide()
	
	# Lógica de daño al jugador
	if current_state == State.ATTACK and not has_dealt_damage:
		if attack_area and is_instance_valid(player):
			var distance = global_position.distance_to(player.global_position)
			var tocando_fisicamente = attack_area.overlaps_body(player)
			
			if tocando_fisicamente or distance < 90.0:
				if player.has_method("take_damage"):
					var knockback_dir = Vector2.ZERO
					if player.global_position.x > global_position.x:
						knockback_dir = Vector2(1, -0.5)
					else:
						knockback_dir = Vector2(-1, -0.5)
					
					player.take_damage(damage_from_attack, knockback_dir)
					has_dealt_damage = true 

func _state_machine_logic(delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, 10)
			if animated_sprite: animated_sprite.play("idle")
			if player and player_chase:
				_start_taunt()
				
		State.TAUNT:
			velocity.x = 0
			if animated_sprite: animated_sprite.play("taunt")
			
		State.CHASE:
			if not is_instance_valid(player): 
				current_state = State.IDLE
				return
			
			var distance = global_position.distance_to(player.global_position)
			
			if distance < (attack_range - 10) and can_attack:
				_start_random_attack()
			else:
				var direction_sign = sign((player.global_position - global_position).x)
				if direction_sign == 0: direction_sign = 1
				
				velocity.x = direction_sign * boss_walk_speed
				
				if animated_sprite: 
					animated_sprite.play("walk")
					_actualizar_direccion_sprite(direction_sign)
					
		State.ATTACK:
			velocity.x = 0 
			
		State.COOLDOWN:
			velocity.x = 0
			if animated_sprite: animated_sprite.play("idle")

func _actualizar_direccion_sprite(dir_x: float):
	if dir_x > 0: 
		animated_sprite.flip_h = SPRITE_MIRA_A_LA_IZQUIERDA 
	elif dir_x < 0: 
		animated_sprite.flip_h = not SPRITE_MIRA_A_LA_IZQUIERDA

func _start_taunt() -> void:
	current_state = State.TAUNT

func _start_random_attack() -> void:
	current_state = State.ATTACK
	can_attack = false
	has_dealt_damage = false
	
	current_attack_anim = lista_de_ataques.pick_random()
	print("Jefe: Usando ataque ", current_attack_anim)
	
	if animated_sprite: 
		if is_instance_valid(player):
			var dir = sign((player.global_position - global_position).x)
			if dir != 0:
				_actualizar_direccion_sprite(dir)
				
		animated_sprite.play(current_attack_anim)

func _on_animation_finished() -> void:
	var anim_name = animated_sprite.animation
	
	if anim_name == "taunt":
		current_state = State.CHASE 
	elif anim_name in lista_de_ataques:
		current_state = State.COOLDOWN
		if has_node("boss_cooldown"):
			get_node("boss_cooldown").start(2.0)
		else:
			await get_tree().create_timer(2.0).timeout
			_on_boss_cooldown_timeout()
	elif anim_name == "death":
		queue_free() 

func _on_boss_cooldown_timeout() -> void:
	can_attack = true
	current_state = State.CHASE 

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player" or body.name == "player": 
		player = body
		player_chase = true

func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "player_attack_hit_box":
		take_damage(20)

func take_damage(amount: int) -> void:
	# 1. Bajamos la vida interna
	health -= amount
	
	# 2. --- NUEVO: ACTUALIZAMOS LA BARRA VISUAL ---
	if health_bar:
		health_bar.value = health
	
	# Efecto visual de golpe
	modulate = Color(1, 0, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2)
	
	print("Vida Jefe: ", health)
	
	if health <= 0:
		current_state = State.DEATH
		if animated_sprite: animated_sprite.play("death")
