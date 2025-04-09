extends "res://scripts/enemies/enemy.gd"
class_name BasicEnemy

func _ready():
	# Call parent ready function
	super._ready()

	# Set basic enemy stats
	max_health = 30
	current_health = max_health
	move_speed = 100
	damage = 10
	experience_value = 5
