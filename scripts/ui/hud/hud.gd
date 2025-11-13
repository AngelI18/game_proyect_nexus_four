extends Control

@onready var left_button = $left
@onready var right_button = $right
@onready var jump_button = $jump
@onready var menu_button = $pause_menu
@onready var joystick = $joystick_attack
@onready var health_bar = $Margin_stats/GridContainer/ProgressBar
@onready var coins = $Margin_stats/GridContainer/coins

func _ready():
	left_button.modulate = Color(1,1,1,0.5)
	right_button.modulate = Color(1,1,1,0.5)
	jump_button.modulate = Color(1,1,1,0.5)
	menu_button.modulate = Color(1,1,1,0.5)
	# Esperar un frame para que el jugador se agregue al grupo
	call_deferred("connect_to_player")

func connect_to_player():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.coin_changed.connect(_on_player_coin_changed)
		print("HUD: Conectado al jugador correctamente")
		# Forzar actualización inicial
		if player.has_method("update_health"):
			player.update_health()
	else:
		print("HUD: ERROR - No se encontró el jugador")

func _on_player_health_changed(current_health: int, max_health: int):
	print("HUD: Señal recibida - Salud: ", current_health, "/", max_health)  # Debug temporal
	health_bar.value = current_health
	health_bar.max_value = max_health
	health_bar.visible = true

func _on_player_coin_changed(coin_current:int) -> void:
	coins.text = str(coin_current)

# Eventos de transparencia
func _on_left_pressed(): 
	left_button.modulate = Color(1,1,1,1)
func _on_left_released(): 
	left_button.modulate = Color(1,1,1,0.5)

func _on_right_pressed(): 
	right_button.modulate = Color(1,1,1,1)
func _on_right_released(): 
	right_button.modulate = Color(1,1,1,0.5)

func _on_jump_pressed(): 
	jump_button.modulate = Color(1,1,1,1)
func _on_jump_released(): 
	jump_button.modulate = Color(1,1,1,0.5)

func _on_pause_menu_pressed() -> void:
	menu_button.modulate = Color(1,1,1,1)
func _on_pause_menu_released() -> void:
	menu_button.modulate = Color(1,1,1,0.5)
