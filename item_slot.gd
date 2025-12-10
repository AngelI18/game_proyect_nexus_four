extends Button

var item_data = {} # Aquí guardaremos info del item
signal item_pressed(boton_referencia, data)

func set_item(data):
	item_data = data
	# Asumiendo que 'data' tiene: nombre, precio e icono
	$name.text = str(data.name)
	$price.text = "$" + str(data.price)
	
	# Si tienes la imagen cargada en la data:
	if data.has("icon"):
		$TextureRect.texture = load(data.icon)
	
func _pressed():
	item_pressed.emit(self, item_data)
