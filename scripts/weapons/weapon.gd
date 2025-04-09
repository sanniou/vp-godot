extends Node2D
class_name Weapon

# Base weapon properties
var level = 1
var damage = 10
var attack_speed = 1.0  # Attacks per second
var attack_timer = 0

# Called when the node enters the scene tree for the first time
func _ready():
	pass

# Called every frame
func _process(delta):
	# Update attack timer
	attack_timer += delta
	
	# Check if it's time to attack
	if attack_timer >= 1.0 / attack_speed:
		attack_timer = 0
		attack()

# Base attack method (to be overridden by specific weapons)
func attack():
	pass

# Upgrade the weapon
func upgrade(levels = 1):
	level += levels
	_apply_upgrade_effects()

# Apply effects of upgrading (to be overridden by specific weapons)
func _apply_upgrade_effects():
	# Base implementation increases damage by 20% per level
	damage = int(damage * (1 + 0.2 * (level - 1)))
