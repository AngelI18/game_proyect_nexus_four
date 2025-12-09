extends EnemyBase

# --- CONFIGURACIÓN DE ENEMIGO VOLADOR ---
# Comportamiento: Flota en el aire e ignora la gravedad. 
# Persigue al jugador en línea recta atravesando plataformas.

@export var fly_speed = 80.0

func _ready() -> void:
	# Configuración inicial
	max_health = 40  # Suelen tener menos vida
	speed = fly_speed
	damage_from_attack = 10
	coin_reward = 15
	
	# Llamamos al ready del padre (EnemyBase)
	super._ready()
	
	# Iniciar animación de vuelo
	if animated_sprite:
		animated_sprite.play("fly")

# --- SOBREESCRIBIMOS LA FÍSICA PARA ELIMINAR LA GRAVEDAD ---
func _physics_process(delta: float) -> void:
	# ¡IMPORTANTE! NO llamamos a super._physics_process(delta) aquí
	# porque eso aplicaría gravedad. Lo manejamos nosotros.
	
	if is_taking_knockback:
		move_and_slide()
		return
		
	# 1. Movimiento de Persecución
	if player_chase and player:
		# Calculamos la dirección directa hacia el jugador (vector)
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * fly_speed
		
		# Voltear el sprite según la dirección horizontal
		update_sprite_direction(sign(direction.x))
	else:
		# Si no persigue, se queda quieto flotando
		velocity = Vector2.ZERO
	
	# 2. Aplicar movimiento
	move_and_slide()
	
	# 3. Llamar a las funciones del padre que SÍ necesitamos
	_handle_combat()
	_update_health_bar()

# --- ARREGLO DE DIRECCIÓN PARA EL BUITRE ---
func update_sprite_direction(direction: int) -> void:
	if animated_sprite and direction != 0:
		# Invertimos la lógica para que coincida con tu dibujo
		animated_sprite.flip_h = direction < 0

func _on_player_lost(body: Node2D) -> void:
	if animated_sprite:
		animated_sprite.play("idle")
	super._on_player_lost(body)

func _on_player_detected(body: Node2D) -> void:
	if animated_sprite:
		animated_sprite.play("fly")
	super._on_player_detected(body)
