extends "res://scripts/weapons/weapon.gd"
class_name Flamethrower

# Flamethrower specific properties
var attack_range = 200
var attack_angle = 60  # Degrees
var damage_tick_rate = 0.2  # Damage applied every 0.2 seconds
var damage_tick_timer = 0
var flame_particles = null

func _ready():
	# Set initial properties
	damage = 5  # Per tick
	attack_speed = 1.0  # Continuous attack
	name = "Flamethrower"
	
	# Create flame particles
	flame_particles = CPUParticles2D.new()
	flame_particles.emitting = false
	flame_particles.amount = 100
	flame_particles.lifetime = 0.5
	flame_particles.explosiveness = 0.0
	flame_particles.randomness = 0.5
	flame_particles.direction = Vector2(1, 0)
	flame_particles.spread = attack_angle
	flame_particles.gravity = Vector2(0, 0)
	flame_particles.initial_velocity_min = 100
	flame_particles.initial_velocity_max = 200
	flame_particles.scale_amount_min = 3
	flame_particles.scale_amount_max = 6
	flame_particles.color = Color(1, 0.5, 0, 1)
	flame_particles.color_ramp = create_color_ramp()
	add_child(flame_particles)

func _process(delta):
	# Update attack timer
	attack_timer += delta
	
	# Check if it's time to attack
	if attack_timer >= 1.0 / attack_speed:
		attack_timer = 0
		attack()
	
	# Update damage tick timer
	if flame_particles.emitting:
		damage_tick_timer += delta
		if damage_tick_timer >= damage_tick_rate:
			damage_tick_timer = 0
			apply_damage()

func attack():
	# Find closest enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		flame_particles.emitting = false
		return
	
	# Sort enemies by distance
	enemies.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	
	# Get closest enemy
	var target = enemies[0]
	var direction = (target.global_position - global_position).normalized()
	
	# Rotate flame particles towards target
	flame_particles.rotation = direction.angle()
	
	# Start emitting particles
	flame_particles.emitting = true

func apply_damage():
	# Find all enemies in range and within angle
	var enemies = get_tree().get_nodes_in_group("enemies")
	var damaged_enemies = []
	
	for enemy in enemies:
		var to_enemy = enemy.global_position - global_position
		var distance = to_enemy.length()
		
		# Check if enemy is in range
		if distance <= attack_range:
			# Check if enemy is within attack angle
			var angle_to_enemy = rad_to_deg(flame_particles.rotation - to_enemy.angle())
			angle_to_enemy = fmod(angle_to_enemy + 180, 360) - 180  # Normalize angle to [-180, 180]
			
			if abs(angle_to_enemy) <= attack_angle / 2:
				# Apply damage with falloff based on distance
				var damage_multiplier = 1.0 - (distance / attack_range)
				enemy.take_damage(damage * damage_multiplier)
				damaged_enemies.append(enemy)

func create_color_ramp():
	# Create a color ramp for the flame particles
	var gradient = Gradient.new()
	gradient.colors = [Color(1, 1, 0, 1), Color(1, 0.5, 0, 1), Color(1, 0, 0, 0.5), Color(0.3, 0.3, 0.3, 0)]
	gradient.offsets = [0, 0.3, 0.7, 1.0]
	return gradient

func _apply_upgrade_effects():
	# Call parent method to increase base damage
	super._apply_upgrade_effects()
	
	# Flamethrower specific upgrades
	match level:
		2:
			attack_range = 250  # Level 2: increased range
		3:
			damage_tick_rate = 0.15  # Level 3: faster damage ticks
		4:
			attack_angle = 80  # Level 4: wider attack angle
		5:
			attack_range = 300  # Level 5: even more range
