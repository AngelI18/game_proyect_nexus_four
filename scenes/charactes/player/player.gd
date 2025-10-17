extends CharacterBody2D

const SPEED = 120.0
const JUMP_VELOCITY = -400.0

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movimiento horizontal
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)

	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: float) -> void:
	if direction == 0:
		$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("run")
		$AnimatedSprite2D.flip_h = direction < 0
