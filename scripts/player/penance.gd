extends Node

# Sistema de penitencias para multijugador
# Se activa al recibir un ataque del oponente

signal penance_applied(penance_data: Dictionary)

var penitencias_list = [
	{
		"id": "p_speed",
		"name": "Piernas de Plomo",
		"description": "Tu velocidad de movimiento se reduce drásticamente.",
		"stat_target": "move_speed",
		"multiplier": 0.6 # Reduce velocidad al 60%
	},
	{
		"id": "p_jump",
		"name": "Grillete Gravitacional",
		"description": "Ya no puedes saltar tan alto.",
		"stat_target": "jump_height",
		"multiplier": 0.5 # Salto a la mitad de altura
	},
	{
		"id": "p_dash",
		"name": "Fatiga Etérea",
		"description": "El Dash tarda más tiempo en recargarse.",
		"stat_target": "dash_cooldown",
		"multiplier": 2.0 # Multiplicamos x2 para que sea MÁS lento el CD
	},
	{
		"id": "p_attack",
		"name": "Hoja Mellada",
		"description": "Tus ataques hacen menos daño.",
		"stat_target": "attack_damage",
		"multiplier": 0.7 # 30% menos de daño
	},
	{
		"id": "p_health",
		"name": "Alma Astillada",
		"description": "Tu capacidad máxima de vida se reduce.",
		"stat_target": "max_health",
		"multiplier": 0.75 # Pierdes un 25% de vida máxima
	}
]

var active_penance: Dictionary = {}
var countdown_timer: Timer
var effect_timer: Timer
var popup_label: Label
var countdown_label: Label

func _ready():
	# Conectar señal de ataque recibido
	if has_node("/root/Network"):
		var network = get_node("/root/Network")
		network.ataque_recibido.connect(_on_attack_received)
	
	# Crear timers
	countdown_timer = Timer.new()
	countdown_timer.one_shot = false
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)
	
	effect_timer = Timer.new()
	effect_timer.one_shot = true
	effect_timer.timeout.connect(_on_penance_end)
	add_child(effect_timer)

func _on_attack_received(_attack_data: Dictionary):
	print("[PENANCE] Ataque recibido - Iniciando penitencia")
	_show_warning_popup()

func _show_warning_popup():
	"""Muestra popup de advertencia con contador de 4 segundos"""
	# Crear label si no existe
	if not countdown_label:
		countdown_label = Label.new()
		countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		countdown_label.add_theme_font_size_override("font_size", 32)
		countdown_label.add_theme_color_override("font_color", Color.RED)
		
		# Añadir al árbol
		var root = get_tree().root
		if root:
			root.add_child(countdown_label)
			# Centrar en pantalla
			var viewport_size = get_viewport().get_visible_rect().size
			countdown_label.position = Vector2(viewport_size.x / 2 - 150, 50)
			countdown_label.custom_minimum_size = Vector2(300, 50)
	
	# Iniciar contador
	countdown_label.visible = true
	countdown_label.text = "PENITENCIA EN CAMINO 4"
	countdown_timer.wait_time = 1.0
	countdown_timer.start()

var countdown_value = 4

func _on_countdown_tick():
	countdown_value -= 1
	
	if countdown_value > 0:
		countdown_label.text = "PENITENCIA EN CAMINO " + str(countdown_value)
	else:
		# Termina el contador
		countdown_timer.stop()
		countdown_label.visible = false
		countdown_value = 4
		_apply_random_penance()

func _apply_random_penance():
	"""Aplica una penitencia aleatoria al jugador"""
	var penance = penitencias_list.pick_random()
	active_penance = penance
	
	print("[PENANCE] Aplicando: ", penance.name)
	
	# Mostrar popup de penitencia
	_show_penance_popup(penance)
	
	# Aplicar efecto al jugador
	_apply_effect_to_player(penance)
	
	# Emitir señal
	penance_applied.emit(penance)
	
	# Programar fin de penitencia (30 segundos)
	effect_timer.wait_time = 30.0
	effect_timer.start()

func _show_penance_popup(penance: Dictionary):
	"""Muestra el popup con la penitencia aplicada"""
	if not popup_label:
		popup_label = Label.new()
		popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		popup_label.add_theme_font_size_override("font_size", 28)
		popup_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		
		var root = get_tree().root
		if root:
			root.add_child(popup_label)
			var viewport_size = get_viewport().get_visible_rect().size
			popup_label.position = Vector2(viewport_size.x / 2 - 200, 50)
			popup_label.custom_minimum_size = Vector2(400, 100)
	
	popup_label.text = penance.name + "\n" + penance.description
	popup_label.visible = true
	
	# Ocultar después de 5 segundos
	await get_tree().create_timer(5.0).timeout
	if popup_label:
		popup_label.visible = false

func _apply_effect_to_player(penance: Dictionary):
	"""Aplica el efecto de la penitencia al jugador"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("[PENANCE] No se encontró el jugador")
		return
	
	var stat_target = penance.stat_target
	var multiplier = penance.multiplier
	
	match stat_target:
		"move_speed":
			if player.has("speed"):
				player.speed *= multiplier
				print("[PENANCE] Velocidad reducida a: ", player.speed)
		
		"jump_height":
			if player.has("jump_velocity"):
				player.jump_velocity *= multiplier
				print("[PENANCE] Salto reducido a: ", player.jump_velocity)
		
		"dash_cooldown":
			if player.has("dash_cooldown"):
				player.dash_cooldown *= multiplier
				print("[PENANCE] Dash cooldown aumentado a: ", player.dash_cooldown)
		
		"attack_damage":
			if player.has("attack_damage"):
				player.attack_damage *= multiplier
				print("[PENANCE] Daño reducido a: ", player.attack_damage)
		
		"max_health":
			if player.has("max_health"):
				var old_max = player.max_health
				player.max_health = int(old_max * multiplier)
				# Ajustar vida actual si supera el nuevo máximo
				if player.current_health > player.max_health:
					player.current_health = player.max_health
				print("[PENANCE] Vida máxima reducida a: ", player.max_health)

func _on_penance_end():
	"""Restaura las estadísticas del jugador al terminar la penitencia"""
	print("[PENANCE] Penitencia terminada, restaurando estadísticas")
	
	var player = get_tree().get_first_node_in_group("player")
	if not player or active_penance.is_empty():
		return
	
	var stat_target = active_penance.stat_target
	var multiplier = active_penance.multiplier
	
	# Revertir el efecto dividiendo por el multiplicador
	match stat_target:
		"move_speed":
			if player.has("speed"):
				player.speed /= multiplier
		
		"jump_height":
			if player.has("jump_velocity"):
				player.jump_velocity /= multiplier
		
		"dash_cooldown":
			if player.has("dash_cooldown"):
				player.dash_cooldown /= multiplier
		
		"attack_damage":
			if player.has("attack_damage"):
				player.attack_damage /= multiplier
		
		"max_health":
			if player.has("max_health"):
				player.max_health = int(player.max_health / multiplier)
	
	active_penance = {}
	print("[PENANCE] Estadísticas restauradas")

func _exit_tree():
	# Limpiar labels
	if countdown_label:
		countdown_label.queue_free()
	if popup_label:
		popup_label.queue_free()
