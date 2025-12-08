extends Button
class_name BlinkingButton

var _tween: Tween

func _ready():
	# Conectar señales para mouse y foco (teclado/gamepad)
	mouse_entered.connect(_start_blinking)
	mouse_exited.connect(_stop_blinking)
	focus_entered.connect(_start_blinking)
	focus_exited.connect(_stop_blinking)

func _start_blinking():
	if _tween:
		_tween.kill()
	
	_tween = create_tween().set_loops()
	# Parpadeo suave: De color normal a transparente (o blanco brillante)
	# Asumimos que queremos que el texto parpadee.
	
	# Opción 1: Modulate (afecta a todo el botón)
	# _tween.tween_property(self, "modulate:a", 0.5, 0.5).set_trans(Tween.TRANS_SINE)
	# _tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	
	# Opción 2: Color de fuente (Blanco -> Gris -> Blanco)
	# Forzamos el color de hover a blanco
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_focus_color", Color.WHITE)
	
	# Animamos el color base 'font_color' o 'font_hover_color' si está activo?
	# Mejor animamos el modulate del self para un efecto de "respiración" o parpadeo
	
	_tween.tween_property(self, "modulate", Color(1, 1, 1, 0.5), 0.4).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4).set_trans(Tween.TRANS_SINE)

func _stop_blinking():
	if _tween:
		_tween.kill()
	modulate = Color(1, 1, 1, 1)
