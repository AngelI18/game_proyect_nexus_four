extends CharacterBody2D

var speed = 40
var player_chase = false
var player = null

#attack
var health = 100
var player_in_attack_zone = false
var can_take_damage = true

func _physics_process(delta: float) -> void:
	#gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	#seguir al jugador
	if player_chase:
		position += (player.position - position)/speed
		$AnimatedSprite2D.play("walk")
		if(player.position.x - position.x) < 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.play("idle")
		
	move_and_slide()
	deal_with_damage()
	update_health()




func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
	player_chase = false
	
func enemy():
	pass
	
func _on_enemy_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_attack_zone = true


func _on_enemy_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_attack_zone = false
		
func deal_with_damage():
	if player_in_attack_zone and Global.player_current_attack == true:
		if can_take_damage == true:
			health -= 20
			$take_damage_cooldown.start()
			can_take_damage = false
			print ("slime health = ",health)
			if health <= 0:
				player.set_coin(20)
				self.queue_free()

func _on_take_damage_cooldown_timeout() -> void:
	can_take_damage = true
	$take_damage_cooldown.stop()
	

func update_health():
	var healthbar = $"health_bar"
	healthbar.value = health
	
	if (health >= 100):
		healthbar.visible = false
	else:
		healthbar.visible = true
	
