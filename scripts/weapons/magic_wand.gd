extends "res://scripts/weapons/weapon.gd"
class_name MagicWand

# Magic wand specific properties
var projectile_speed = 400
var projectile_scene = preload("res://scenes/weapons/magic_projectile.tscn")
var max_projectiles = 1  # Start with 1 projectile, increase with upgrades

func _ready():
	# Set initial properties
	damage = 15
	attack_speed = 1.0
	name = "MagicWand"

func attack():
	# Get all enemies in the scene
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return  # No enemies to attack

	# Determine how many projectiles to fire (based on level)
	var projectiles_to_fire = min(max_projectiles, enemies.size())

	# Sort enemies by distance
	enemies.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))

	# Fire projectiles at the closest enemies
	for i in range(projectiles_to_fire):
		var target = enemies[i]
		_fire_projectile(target)

func _fire_projectile(target):
	# Create projectile instance
	var projectile = projectile_scene.instantiate()

	# Set projectile properties
	projectile.damage = damage
	projectile.speed = projectile_speed
	projectile.target = target

	# Add to scene
	get_tree().current_scene.add_child(projectile)

	# Position at player
	projectile.global_position = global_position

func _apply_upgrade_effects():
	# Call parent method to increase base damage
	super._apply_upgrade_effects()

	# Magic wand specific upgrades
	match level:
		2:
			max_projectiles = 2  # Level 2: can fire 2 projectiles
		3:
			attack_speed = 1.5  # Level 3: faster attack speed
		4:
			max_projectiles = 3  # Level 4: can fire 3 projectiles
		5:
			projectile_speed = 500  # Level 5: faster projectiles
