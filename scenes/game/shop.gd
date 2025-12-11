extends Area2D

# Referencias a la UI
@onready var shop_ui = $ShopUI
@onready var anim = $Sprite2D
@onready var big_shop_ui = $BigShopUI

# Referencias a los botones (Ajusta la ruta si cambiaste nombres)
@onready var abrir_tienda = $ShopUI/PanelContainer/VBoxContainer/AbrirTienda

var player_ref = null # Guardaremos referencia al jugador aquí

func _ready():
	# Ocultar menú al inicio por seguridad
	shop_ui.visible = false
	
	# Conectar señales de detección (si no lo hiciste desde el editor)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Conectar botones
	abrir_tienda.pressed.connect(_open_store)
	
# --- Detección del Jugador ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body # Guardamos quién es el jugador
		# Opcional: Mostrar un cartelito de "Presiona E" aquí
		open_shop()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_ref = null
		_close_shop() # Cerrar tienda si se aleja

# --- Lógica de la Tienda ---
func open_shop():
	shop_ui.visible = true
	# Opcional: Pausar el juego para que no te ataquen mientras compras
	# get_tree().paused = true 

func _close_shop():
	shop_ui.visible = false
	# get_tree().paused = false

func _open_store():
	print("Abriendo catálogo...")
	_close_shop() # Cerramos el menú flotante pequeño (Node2D)
	
	# Abrimos la tienda grande y le pasamos al jugador
	big_shop_ui.open(player_ref)
