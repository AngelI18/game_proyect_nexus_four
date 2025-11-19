extends EnemyBase

#Clase: Enemigo Básico (Slime)
#Comportamiento: Camina hacia el jugador, ataque simple por contacto

func _ready() -> void:
	# Configuración de enemigo tipo 1 (básico)
	enemy_type = 1  # 8% de daño
	speed = 100
	max_health = 100
	damage_from_attack = 20
	coin_reward = 20
	knockback_strength = 200.0
	
	super._ready()

func _on_ready() -> void:
	# Inicialización específica del slime
	pass

func _handle_movement(_delta: float) -> void:
	if not player or not is_on_floor():
		velocity.x = 0
		return
	
	var direction = sign(player.global_position.x - global_position.x)
	
	if player_chase:
		velocity.x = direction * speed
		if animated_sprite:
			animated_sprite.flip_h = direction < 0
	else:
		velocity.x = 0

func _handle_animation() -> void:
	if not animated_sprite:
		return
	
	if velocity.x != 0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")
