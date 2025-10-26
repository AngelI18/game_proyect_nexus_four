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

# configurar Ataque
var enemy_in_attack_range = false
var enemy_attack_cooldown = true
var health = 200
var player_alive = true
var attack_ip = false
var direction = 0

func _physics_process(delta: float) -> void:
	direction = 0
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		can_double_jump = true
		jump_less = cant_double_jump
		
	#movimiento si no esta atacando
	if !attack_ip and  !is_taking_damage:
		#Salto
		if Input.is_action_just_pressed("ui_up"):
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
				jump_less -= 1
			elif can_double_jump && jump_less != 0:
				velocity.y = JUMP_VELOCITY
				jump_less -= 1
			elif jump_less == 0:
				can_double_jump = false
		elif Input.is_action_just_pressed("attack") and is_on_floor():
			attack()
		elif Input.is_action_pressed("ui_left"):
			direction = -1
		elif Input.is_action_pressed("ui_right"):
			direction = 1
		else:
			direction = 0
	
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
	

func _update_animation(direction: float) -> void:
	if is_taking_damage:
		return 
	
	if direction != 0:
		$AnimatedSprite2D.flip_h = direction <0
	
	if not is_on_floor():
		# Animación de salto
		$AnimatedSprite2D.play("jump")
	elif direction == 0:
		# Animación de reposo
		if attack_ip == false:
			$AnimatedSprite2D.play("idle")
	else:
		# Animación de correr
		if attack_ip == false:
			$AnimatedSprite2D.play("run")
			$AnimatedSprite2D.flip_h = direction < 0


func player():
	pass

func _on_player_hit_box_body_entered(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_in_attack_range = true
		current_enemy = body

func _on_player_hit_box_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_in_attack_range = false
		if current_enemy == body:
			current_enemy = null
func enemyAttack():
	if enemy_in_attack_range and enemy_attack_cooldown and !is_invulnerable:
		health -= 20
		var damage_direction = (global_position - current_enemy.global_position).normalized()
		apply_damage_and_knockback(damage_direction)
		enemy_attack_cooldown = false
		$attack_cooldown.start()
		print(health)

func apply_damage_and_knockback(damage_direction: Vector2):
	is_taking_damage = true
	is_taking_knockback = true
	is_invulnerable = true
	
	var knockback_dir = 1 if damage_direction.x > 0 else -1

	velocity.x = knockback_dir * KNOCKBACK_FORCE
	velocity.y = -150
	print(knockback_dir)
	
	$AnimatedSprite2D.play("hurt")
	
	await $AnimatedSprite2D.animation_finished
	
	is_taking_damage = false
	is_taking_knockback = false
	
	$invulnerability_timer.start(2.0)
	blink_sprite(2)
	

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

func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
