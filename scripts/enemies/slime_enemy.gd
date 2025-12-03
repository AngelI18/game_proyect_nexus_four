extends EnemyBase

#Clase especializada: Slime
#Hereda todo el comportamiento base y puede personalizarlo

func _ready() -> void:
	#Configurar estadísticas específicas del slime
	speed = 100
	max_health = 100
	damage_to_player = 20
	coin_reward = 20
	knockback_strength = 200.0
	
	#Llamar al _ready del padre
	super._ready()

#Override: Personalizar movimiento si es necesario
func _handle_movement(delta: float) -> void:
	#Usar comportamiento por defecto del padre
	super._handle_movement(delta)
	
	#Aquí podrías agregar comportamiento específico del slime
	#Por ejemplo: saltos aleatorios, movimiento errático, etc.

#Override: Personalizar animaciones si es necesario
func _handle_animation() -> void:
	#Usar comportamiento por defecto del padre
	super._handle_animation()

#Override: Hacer algo especial cuando recibe daño
func _on_take_damage(damage_amount: int) -> void:
	#Aquí podrías agregar efectos especiales
	#Por ejemplo: cambiar color, hacer sonido, soltar partículas, etc.
	pass

#Override: Hacer algo especial al morir
func _on_death() -> void:
	#Podrías agregar animación de muerte, explosión, etc.
	print("Slime defeated!")
	
	#Llamar a la muerte del padre (da monedas y se destruye)
	super._on_death()

#Override: Hacer algo cuando detecta al jugador
func _on_player_detected(body: Node2D) -> void:
	print("Slime detected player!")
	#Aquí podrías agregar efectos como cambiar color o hacer un sonido

#Override: Hacer algo cuando pierde al jugador
func _on_player_lost(body: Node2D) -> void:
	print("Slime lost player!")
