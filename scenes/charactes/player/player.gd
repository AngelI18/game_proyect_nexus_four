extends CharacterBody2D

# Velocidad ajustada para tiles de 24x24 (5 tiles por segundo)
const SPEED = 170.0
const JUMP_VELOCITY = -400.0

var can_double_jump = true
var cant_double_jump = 2
var jump_less = cant_double_jump

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

	# Movimiento horizontal sin inercia
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED

	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: float) -> void:
	if not is_on_floor():
		# Animación de salto
		$AnimatedSprite2D.play("jump")
	elif direction == 0:
		# Animación de reposo
		$AnimatedSprite2D.play("idle")
	else:
		# Animación de correr
		$AnimatedSprite2D.play("run")
		$AnimatedSprite2D.flip_h = direction < 0


func _update_collision(animation_name: String) -> void:
		$CollisionShape2D_idle.set_disabled(animation_name != "idle")
		$CollisionShape2D_run.set_disabled(animation_name != "run")
		$CollisionShape2D_jump.set_disabled(animation_name != "jump")
