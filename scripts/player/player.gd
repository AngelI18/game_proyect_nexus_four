extends CharacterBody2D

# Velocidad ajustada para tiles de 24x24 (5 tiles por segundo)
const SPEED = 170.0
const JUMP_VELOCITY = -350.0
# velocidad de knockback force
const KNOCKBACK_FORCE = 100.0

# config knockback force 
var current_enemy: Node2D = null  
var is_taking_damage = false
var is_taking_knockback = false
var is_invulnerable = false

# double jump
var can_double_jump = true
var cant_double_jump = 2
var jump_less = cant_double_jump

#configurarAtaque
var enemy_node_in_range: Node2D = null
var enemy_attack_cooldown = true
var health = 200
var player_alive = true
var attack_ip = false
var player_hurt_ip = false

#retroceso
const KNOCKBACK_STRENGTH = 150.0
const KNOCKBACK_JUMP = -150.0
var is_invulnerable = false
var direction = 0

func _ready():
	var joystick = get_tree().get_first_node_in_group("attack_joystick")
	if joystick:
		joystick.attack_triggered.connect(_on_joystick_attack_triggered)
		print("Joystick conectado!")
	else:
		print("Joystick no encontrado")

func _physics_process(delta: float) -> void:
	direction = 0
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		can_double_jump = true
		jump_less = cant_double_jump
	
	# Salto
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jump_less -= 1
		elif can_double_jump && jump_less != 0:
			velocity.y = JUMP_VELOCITY
			jump_less -= 1
		elif jump_less == 0:
			can_double_jump = false

	# Movimiento horizontal sin inercia
	var direction := Input.get_axis("ui_left", "ui_right")
	if attack_ip == true:
		velocity.x = 0.0 # Detener al jugador mientras ataca
	elif player_hurt_ip == true:
		pass
	else:
		# Movimiento normal si no estamos ni atacando ni heridos
		velocity.x = direction * SPEED
		
	
	if !is_taking_knockback:
		velocity.x = SPEED * direction
		
	if health <= 0:
		player_alive = false
		health = 0
		self.queue_free()
		#display menu de muerte, y voler a inicio

	move_and_slide()
	_update_animation(direction)
	enemyAttack()
	attack()
	update_health()

func _update_animation(direction: float) -> void:
	if is_taking_damage:
		return 
	
	if direction != 0:
		$AnimatedSprite2D.flip_h = direction <0
	
	if not is_on_floor():
		# Animación de salto
		if player_hurt_ip == false:
			$AnimatedSprite2D.play("jump")
	elif direction == 0:
		# Animación de reposo
		if attack_ip == false and player_hurt_ip == false:
			$AnimatedSprite2D.play("idle")
	else:
		# Animación de correr
		if attack_ip == false and player_hurt_ip == false:
			$AnimatedSprite2D.play("run")
			$AnimatedSprite2D.flip_h = direction < 0


func player():
	pass

func _on_player_hit_box_body_entered(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_node_in_range = body


func _on_player_hit_box_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		if body == enemy_node_in_range:
			enemy_node_in_range = null

func enemyAttack():
	if enemy_node_in_range != null and enemy_attack_cooldown and !is_invulnerable:
		var knockback_direction = (global_position - enemy_node_in_range.global_position).normalized()
		#velocidad del retroceso
		velocity.x = knockback_direction.x * KNOCKBACK_STRENGTH
		velocity.y = KNOCKBACK_JUMP
		health -= 20
		is_invulnerable = true
		player_hurt_ip = true
		enemy_attack_cooldown = false
		$attack_cooldown.start()
		$player_is_hurt.start()
		$AnimatedSprite2D.play("hurt")
		$invulnerability_timer.start(2.0)
		#reiniciar timer de regeneracion
		$regen_timer
		blink_sprite(2)
		print(health)

func blink_sprite(duration: float):
	var time = 0.0
	while time < duration:
		$AnimatedSprite2D.modulate.a = 0.3
		await get_tree().create_timer(0.1).timeout
		$AnimatedSprite2D.modulate.a = 1.0 
		await get_tree().create_timer(0.1).timeout
		time += 0.2
	$AnimatedSprite2D.modulate.a = 1.0


func _on_attack_cooldown_timeout() -> void:
	enemy_attack_cooldown = true

func attack():
	Global.player_current_attack = true
	attack_ip = true
	$AnimatedSprite2D.play("attack")
	$deal_attack_timer.start()


func _on_deal_attack_timer_timeout() -> void:
	$deal_attack_timer.stop()
	Global.player_current_attack = false
	attack_ip = false


func _on_player_is_hurt_timeout() -> void:
	$player_is_hurt.stop()
	player_hurt_ip = false


func _on_invulnerability_timer_timeout() -> void:
	$invulnerability_timer.stop()
	is_invulnerable = false

func update_health():
	var healthbar = $"health_bar"
	healthbar.value = health
	
	if (health >= 200):
		healthbar.visible = false
	else:
		healthbar.visible = true
	


func _on_regen_timer_timeout() -> void:
	if (health < 200):
		health += 20
		if (health >= 200):
			health = 200
	if (health <= 0):
		health = 0
func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false

func _on_joystick_attack_triggered(direction_attack: Vector2):
	if is_on_floor() and !attack_ip and !is_taking_damage:
		# Aplicar flip según dirección del joystick
		if direction_attack.x < -0.3:
			$AnimatedSprite2D.flip_h = true  # Izquierda
		elif direction_attack.x > 0.3:
			$AnimatedSprite2D.flip_h = false  # Derecha
		attack()
