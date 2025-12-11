extends Node

# Sistema de penitencias para multijugador
# Se activa al recibir un ataque del oponente

signal penance_applied(penance_data: Dictionary)

@onready var title_message = $VBoxContainer/Title
@onready var corpus_message = $VBoxContainer/message
@onready var vbox_container = $VBoxContainer

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
var is_penance_active: bool = false
var countdown_value: int = 4

func _ready():
	# Ocultar UI al inicio
	vbox_container.visible = false
	
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
	if is_penance_active:
		print("[PENANCE] Ya hay penitencia activa, ignorando ataque")
		return
	
	print("[PENANCE] Ataque recibido - Iniciando penitencia")
	_show_warning_popup()

func _show_warning_popup():
	"""Muestra popup de advertencia con contador de 4 segundos"""
	countdown_value = 4
	vbox_container.visible = true
	title_message.text = "⚠ PENITENCIA EN CAMINO"
	corpus_message.text = str(countdown_value)
	countdown_timer.wait_time = 1.0
	countdown_timer.start()

func _on_countdown_tick():
	countdown_value -= 1
	
	if countdown_value > 0:
		corpus_message.text = str(countdown_value)
	else:
		countdown_timer.stop()
		_apply_random_penance()

func _apply_random_penance():
	"""Aplica una penitencia aleatoria al jugador"""
	var penance = penitencias_list.pick_random()
	active_penance = penance
	is_penance_active = true
	
	print("[PENANCE] Aplicando: ", penance.name)
	
	# Mostrar popup de penitencia
	_show_penance_popup(penance)
	
	# Aplicar efecto al jugador
	_apply_effect_to_player(penance)
	
	# Emitir señal
	penance_applied.emit(penance)
	
	# Programar fin de penitencia (20 segundos)
	effect_timer.wait_time = 20.0
	effect_timer.start()

func _show_penance_popup(penance: Dictionary):
	"""Muestra el popup con la penitencia aplicada"""
	vbox_container.visible = true
	title_message.text = penance.name
	corpus_message.text = penance.description
	
	# Ocultar después de 5 segundos
	await get_tree().create_timer(5.0).timeout
	vbox_container.visible = false

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
			if "SPEED" in player:
				player.SPEED *= multiplier
				print("[PENANCE] Velocidad reducida a: ", player.SPEED)
		
		"jump_height":
			if "JUMP_VELOCITY" in player:
				player.JUMP_VELOCITY *= multiplier
				print("[PENANCE] Salto reducido a: ", player.JUMP_VELOCITY)
		
		"dash_cooldown":
			if "DASH_COOLDOWN" in player:
				player.DASH_COOLDOWN *= multiplier
				print("[PENANCE] Dash cooldown aumentado a: ", player.DASH_COOLDOWN)
		
		"attack_damage":
			if "damage" in player:
				player.damage *= multiplier
				print("[PENANCE] Daño reducido a: ", player.damage)
		
		"max_health":
			if "MAX_HEALTH" in player:
				var old_max = player.MAX_HEALTH
				player.MAX_HEALTH = int(old_max * multiplier)
				# Ajustar vida actual si supera el nuevo máximo
				if player.health > player.MAX_HEALTH:
					player.health = player.MAX_HEALTH
				print("[PENANCE] Vida máxima reducida a: ", player.MAX_HEALTH)

func _on_penance_end():
	"""Restaura las estadísticas del jugador al terminar la penitencia"""
	print("[PENANCE] Penitencia terminada, restaurando estadísticas")
	
	var player = get_tree().get_first_node_in_group("player")
	if not player or active_penance.is_empty():
		is_penance_active = false
		return
	
	var stat_target = active_penance.stat_target
	var multiplier = active_penance.multiplier
	
	# Revertir el efecto dividiendo por el multiplicador
	match stat_target:
		"move_speed":
			if "SPEED" in player:
				player.SPEED /= multiplier
		
		"jump_height":
			if "JUMP_VELOCITY" in player:
				player.JUMP_VELOCITY /= multiplier
		
		"dash_cooldown":
			if "DASH_COOLDOWN" in player:
				player.DASH_COOLDOWN /= multiplier
		
		"attack_damage":
			if "damage" in player:
				player.damage /= multiplier
		
		"max_health":
			if "MAX_HEALTH" in player:
				player.MAX_HEALTH = int(player.MAX_HEALTH / multiplier)
	
	active_penance = {}
	is_penance_active = false
	print("[PENANCE] Estadísticas restauradas")
