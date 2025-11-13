extends "res://scripts/enemies/enemy.gd"
@export var anim_walk_dos:="walk"
@export var anim_idle_dos:="idle"
@onready var anim_player_dos:=$AnimationPlayer
func _ready():
	speed=20
	health= 150
	anim_walk_dos="ataque_uno"
	anim_idle_dos="idle"
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
func update_health():
	super.update_health()
