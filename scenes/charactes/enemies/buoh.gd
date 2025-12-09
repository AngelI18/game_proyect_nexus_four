extends EnemyBase

# --- CONFIGURACIÓN DEL BÚHO ---
# Comportamiento: Vuela ignorando gravedad. Persigue al jugador.

@export var fly_speed = 70.0  # Un poco más lento que el buitre (que era 80)

func _ready() -> void:
	# Estadísticas del Búho
	max_health = 50       # Un poco más de vida que el buitre (40)
	speed = fly_speed
	damage_from_attack = 15
	coin_reward = 20
	
	super._ready()
	
	# Iniciar aleteo
	if animated_sprite:
		animated_sprite.play("fly")

# --- FÍSICA DE VUELO (Anti-Gravedad) ---
func _physics_process(delta: float) -> void:
	if is_taking_knockback:
		move_and_slide()
		return
		
	# Persecución aérea
	if player_chase and player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * fly_speed
		update_sprite_direction(sign(direction.x))
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# Funciones vitales heredadas
	_handle_combat()
	_update_health_bar()

func update_sprite_direction(direction: int) -> void:
	if animated_sprite and direction != 0:
		animated_sprite.flip_h = direction > 0
		
		
