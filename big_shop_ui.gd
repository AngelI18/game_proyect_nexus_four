extends CanvasLayer

# Referencia a la escena del botón chiquito
var slot_scene = preload("res://scenes/ui/item_slot.tscn")

@onready var grid = $Ventana/VBoxContainer/ScrollContainer/ItemGrid

var items_available = [
	{"id": "damage_up", "name": "Afiladora", "price": 30, "icon": "res://assets/ui/items/dmg.png"},
	{"id": "life_up", "name": "Poro galleta", "price": 30, "icon": "res://assets/ui/items/life.png"},
	{"id": "speed_up", "name": "Botas", "price": 30, "icon": "res://assets/ui/items/speed.png"},
	{"id": "jump_plus", "name": "Hongo Jump", "price": 80, "icon": "res://assets/ui/items/jump.png"}
]

var player_ref = null

func _ready():
	visible = false 
	$Ventana/VBoxContainer/BtnCerrar.pressed.connect(close_shop)

func open(player):
	player_ref = player
	visible = true
	# NO pausar el juego en la tienda
	# get_tree().paused = true
	
	# Limpiar items viejos si los hubiera
	for child in grid.get_children():
		child.queue_free()
		
	# Crear los botones nuevos
	for item in items_available:
		var new_slot = slot_scene.instantiate()
		grid.add_child(new_slot)
		new_slot.set_item(item)
		# Conectar la señal del slot a la función de compra de aquí
		new_slot.item_pressed.connect(_on_item_clicked)

func _on_item_clicked(slot_ref, item_data):
	if player_ref.coins >= item_data.price:
		player_ref.coins -= item_data.price
		print("Compraste: " + item_data.name)
		
		# --- LÓGICA DE APLICACIÓN DE MEJORAS ---
		match item_data.id:
			"damage_up":
				player_ref.damage += 5
				print("¡Ahora pegas más fuerte!")
			"life_up":
				# Aumentamos el máximo
				player_ref.MAX_HEALTH += 10
				# curarse al comprar vida
				player_ref.health = player_ref.MAX_HEALTH
				# IMPORTANTE: Si tienes barra de vida, fuérzala a actualizarse visualmente aquí
				player_ref.health_changed.emit(player_ref.health, player_ref.MAX_HEALTH)
					
			"speed_up":
				player_ref.SPEED += 20
				print("Velocidad aumentada")
				
			"jump_plus":
				player_ref.MAX_JUMPS += 1
				print("Saltos extra: " + str(player_ref.MAX_JUMPS))
			
		player_ref.emit_coin_signal()
	else:
		# --- ERROR (NO HAY DINERO) ---
		print("No tienes dinero suficiente")
		
		# 1. Vibración (Solo funciona en Android/iOS)
		Input.vibrate_handheld(200) # Vibra por 200 milisegundos
		
		# 2. Animación Visual (Sacudida y Rojo)
		_animar_error(slot_ref)

func close_shop():
	visible = false
	# NO despausar porque nunca pausamos
	# get_tree().paused = false

func _animar_error(boton: Control):
	# Si ya hay una animación corriendo en este botón, la matamos para que no se peleen
	if boton.get_meta("tweening", false):
		return # Opcional: Ignorar clics si ya se está animando
	
	boton.set_meta("tweening", true) # Marcamos que se está animando
	
	var tween = create_tween()
	var pos_original = boton.position.x
	
	# 1. Ponerse Rojo INMEDIATAMENTE
	boton.modulate = Color(1, 0.2, 0.2) 
	
	# 2. Sacudida
	tween.tween_property(boton, "position:x", pos_original + 5, 0.05)
	tween.tween_property(boton, "position:x", pos_original - 5, 0.05)
	tween.tween_property(boton, "position:x", pos_original + 5, 0.05)
	tween.tween_property(boton, "position:x", pos_original, 0.05)
	
	# 3. Volver a BLANCO (Color.WHITE es lo mismo que Color(1, 1, 1))
	# Usamos Color.WHITE en vez de 'color_original' para evitar el bug
	tween.tween_property(boton, "modulate", Color.WHITE, 0.2)
	
	# Al terminar, liberamos la marca
	tween.finished.connect(func(): boton.set_meta("tweening", false))
