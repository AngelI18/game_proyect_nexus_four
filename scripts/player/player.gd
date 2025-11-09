extends CharacterBody2D
signal health_changed(current_health,max_health)
signal coin_changed(new_coints)
# Velocidad ajustada para tiles de 24x24 (5 tiles por segundo)
const SPEED = 170.0
const JUMP_VELOCITY = -350.0

var can_double_jump = true
var cant_double_jump = 2
var jump_less = cant_double_jump

#mecanica del oro
var coint_player = 0

#configurarAtaque
var enemy_node_in_range: Node2D = null
var enemy_attack_cooldown = true
var max_life = 200
var health = max_life
var max_regeneration = max_life * 0.7
var player_alive = true
var attack_ip = false
var player_hurt_ip = false

#retroceso
const KNOCKBACK_STRENGTH = 150.0
const KNOCKBACK_JUMP = -150.0
var is_invulnerable = false
var is_taking_damage = false

#sistema de checkpoint fantasma
var last_safe_position: Vector2 = Vector2.ZERO
var ghost_sprite: Sprite2D = null
var is_on_damage_tile = false

func _ready():
	# Agregar al grupo "player" para que el HUD lo encuentre
	add_to_group("player")
	
	var joystick = get_tree().get_first_node_in_group("attack_joystick")
	if joystick:
		joystick.attack_triggered.connect(_on_joystick_attack_triggered)
		print("Joystick conectado!")
	else:
		print("Joystick no encontrado")
	
	# Emitir señal inicial de salud después de que todo esté listo
	call_deferred("update_health")
	# Emitir señal inicial de monedas después de que todo este listo
	call_deferred("set_coin")

func _physics_process(delta: float) -> void:
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

	#Movimiento horizontal sin inercia
	var direction := Input.get_axis("ui_left", "ui_right")
	if attack_ip == true:
		if is_on_floor():
			velocity.x = 0.0 # Detener al jugador mientras ataca, solo si esta en el piso, en aire mantener direccion
	elif player_hurt_ip == true:
		pass
	else:
		# Movimiento normal si no estamos ni atacando ni heridos
		velocity.x = direction * SPEED
		
	if health <= 0:
		player_alive = false
		health = 0
		self.queue_free()
		#display menu de muerte, y voler a inicio

	move_and_slide()
	_update_animation(direction)
	enemyAttack()
	attack()

func _update_animation(direction: float) -> void:
	
	if !attack_ip and !player_hurt_ip:
		#cambiar orientacion de la animacion acorde a la direccion independiente de la animacion
		if direction !=0:
			$AnimatedSprite2D.flip_h = direction <0
		
		if not is_on_floor():
			# Animación de salto
			if velocity.y < 0 and $AnimatedSprite2D.name != "jump":
				$AnimatedSprite2D.play("jump")
			# Animacion de caida
			elif velocity.y > 0 and $AnimatedSprite2D.name != "fall":
				$AnimatedSprite2D.play("fall")
		elif direction == 0:
			# Animación de reposo
			if attack_ip == false and player_hurt_ip == false:
				$AnimatedSprite2D.play("idle")
		else:
			# Animación de correr
			if attack_ip == false and player_hurt_ip == false:
				$AnimatedSprite2D.play("run")

#esto no lo estamos usando ahora, cuando se pula las hitbox si
#func _update_collision(animation_name: String) -> void:
#		$CollisionShape2D_idle.set_disabled(animation_name != "idle")
#		$CollisionShape2D_run.set_disabled(animation_name != "run")
#		$CollisionShape2D_jump.set_disabled(animation_name != "jump")

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
		update_health()
		is_invulnerable = true
		player_hurt_ip = true
		enemy_attack_cooldown = false
		is_taking_damage = true
		$attack_cooldown.start()
		$player_is_hurt.start()
		$AnimatedSprite2D.play("hurt")
		$invulnerability_timer.start(2.0)
		#reiniciar timer de regeneracion
		$regen_timer.stop()
		$regen_timer.start()
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
	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_action_just_pressed("attack"):
		Global.player_current_attack = true
		attack_ip = true
		$AnimatedSprite2D.play("attack")
		if (direction < 0):
			$AnimatedSprite2D.flip_h = true
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
	is_taking_damage = false

func update_health():
	health_changed.emit(health, 200)

func _on_regen_timer_timeout() -> void:
	var health_changed_flag = false
	
	if (health < max_regeneration):
		health += 20
		if (health >= max_regeneration):
			health = max_regeneration
		health_changed_flag = true
	if (health <= 0):
		health = 0
		health_changed_flag = true
	if health_changed_flag:
		health_changed_flag = false
		update_health()
	
func _on_joystick_attack_triggered(direction_attack: Vector2):
	if is_on_floor() and !attack_ip and !is_taking_damage:
		# Aplicar flip según dirección del joystick
		if direction_attack.x < -0.3:
			$AnimatedSprite2D.flip_h = true  # Izquierda
		elif direction_attack.x > 0.3:
			$AnimatedSprite2D.flip_h = false  # Derecha
		#funcion attack()
		var direction := Input.get_axis("ui_left", "ui_right")
		Global.player_current_attack = true
		attack_ip = true
		$AnimatedSprite2D.play("attack")
		if (direction < 0):
			$AnimatedSprite2D.flip_h = true
		$deal_attack_timer.start()
#coins
func set_coin(new_coin_count: int) -> void:
	coint_player += new_coin_count
	coin_changed.emit(coint_player)
