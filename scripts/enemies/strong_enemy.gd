extends "res://scripts/enemies/enemy.gd"
class_name StrongEnemy

func _ready():
	# Call parent ready function
	super._ready()

	# Set strong enemy stats
	max_health = 80
	current_health = max_health
	move_speed = 80
	damage = 20
	experience_value = 15
