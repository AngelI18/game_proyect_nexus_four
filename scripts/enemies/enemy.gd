extends CharacterBody2D

var speed = 100
var player_chase = false
var player = null

#Attack
var health = 100
var player_in_attack_zone = false
var can_take_damage = true

#Knockback
const KNOCKBACK_STRENGTH = 200.0
var is_taking_knockback = false

func _physics_process(delta: float) -> void:
	#Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if is_taking_knockback:
		pass
	elif player_chase and is_on_floor():
		var direction = sign(player.position.x - position.x)
		velocity.x = direction * speed
		$AnimatedSprite2D.play("walk")
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = 0
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
			apply_knockback()
			
			print ("slime health = ",health)
			if health <= 0:
				player.add_coins(20)
				self.queue_free()

func apply_knockback():
	if player:
		var knockback_direction = (global_position - player.global_position).normalized()
		velocity.x = knockback_direction.x * KNOCKBACK_STRENGTH
		is_taking_knockback = true
		await get_tree().create_timer(0.3).timeout
		is_taking_knockback = false

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
	
