extends Control

func _ready():
	# Esto pone la barrita en la posición correcta al iniciar
	# Busca el bus "Musica" y obtiene su volumen actual
	var bus_musica = AudioServer.get_bus_index("Musica")
	$VBoxContainer/SliderMusica.value = db_to_linear(AudioServer.get_bus_volume_db(bus_musica))
	
	# Busca el bus "SFX" y obtiene su volumen actual
	var bus_sfx = AudioServer.get_bus_index("SFX")
	$VBoxContainer/SliderSFX.value = db_to_linear(AudioServer.get_bus_volume_db(bus_sfx))

# Esta función controla el volumen de la MÚSICA
func _on_slider_musica_value_changed(value):
	var bus_index = AudioServer.get_bus_index("Musica")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

# Esta función controla el volumen de los EFECTOS
func _on_slider_sfx_value_changed(value):
	print("Moviendo slider música a: ", value)
	var bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

# Esta función es para el botón ATRÁS
func _on_back_pressed():
	hide() # Oculta este menú
	# Opcional: Si tienes un menú principal detrás, podrías necesitar emitir una señal
	# pero por ahora con hide() basta si estás superponiendo la escena.
