extends "res://scripts/enemies/enemy.gd"
@export var anim_walk:="walk"
@export var anim_idle:="idle"
@onready var anim_player:=$AnimationPlayer
func _ready():
	speed=20
	health= 150
	anim_walk="AtaqueRápido"
	anim_idle="idle"
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
func update_health():
	super.update_health()



	
