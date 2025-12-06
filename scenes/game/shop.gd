extends Area2D

@onready var prompt_label = $Label # Asegúrate de tener el nodo Label como hijo
var player_in_range = false

func _ready():
	# Conectamos las señales del Area2D para saber si entra alguien
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Nos aseguramos que el cartel esté oculto al inicio
	if prompt_label:
		prompt_label.visible = false

func _on_body_entered(body):
	# Verificamos si es el jugador (asegúrate que tu jugador se llame "player" o esté en el grupo "player")
	if body.name == "player" or body.is_in_group("player"):
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true
			print("Jugador entró a la tienda")

func _on_body_exited(body):
	if body.name == "player" or body.is_in_group("player"):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _input(event):
	# Si el jugador está cerca y presiona la tecla de interacción
	if player_in_range and event.is_action_pressed("interact"): 
		open_shop()

func open_shop():
	print("¡Abriendo interfaz de tienda!")
	# Aquí pausaremos el juego y abriremos el menú más adelante
	# get_tree().paused = true 
	# shop_ui.show()
