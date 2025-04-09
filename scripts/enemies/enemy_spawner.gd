extends Node2D
class_name EnemySpawner

# Enemy types
var enemy_types = {
	"basic": {
		"color": Color(1.0, 0.2, 0.2, 1.0),
		"max_health": 100,
		"move_speed": 100,
		"damage": 10,
		"experience_value": 5,
		"size": 25
	},
	"strong": {
		"color": Color(0.2, 0.2, 1.0, 1.0),
		"max_health": 200,
		"move_speed": 80,
		"damage": 20,
		"experience_value": 15,
		"size": 35
	},
	"ranged": {
		"color": Color(0.8, 0.2, 0.8, 1.0),
		"max_health": 50,
		"move_speed": 70,
		"damage": 15,
		"experience_value": 10,
		"size": 25,
		"is_ranged": true,
		"attack_range": 300,
		"attack_cooldown": 2.0
	}
}

# Load scenes in _ready to avoid preload errors
# Spawn settings
var spawn_radius = 800  # Distance from player to spawn enemies
var min_spawn_distance = 400  # Minimum distance from player
var max_enemies = 100  # Maximum number of enemies at once
var difficulty = 0  # Increases over time

# References
var player = null

func _ready():
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# Spawn an enemy at a random position around the player
func spawn_enemy():
	print("EnemySpawner: spawn_enemy called, player: ", player)
	if player == null or !is_instance_valid(player):
		# Try to find player again
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			return  # No player, don't spawn

	# Check if we've reached the maximum number of enemies
	var current_enemies = get_tree().get_nodes_in_group("enemies")
	if current_enemies.size() >= max_enemies:
		return

	# Determine which enemy type to spawn based on difficulty
	var enemy_type = "basic"
	var random_value = randf()

	# Always spawn basic enemies at the beginning
	if difficulty == 0:
		enemy_type = "basic"
	# After difficulty 5, start spawning ranged enemies
	elif difficulty >= 5 and random_value < 0.15 + (difficulty * 0.005):
		enemy_type = "ranged"
	# Chance of strong enemy increases with difficulty
	elif random_value < 0.2 + (difficulty * 0.01):
		enemy_type = "strong"
	# Default to basic enemy
	else:
		enemy_type = "basic"

	# Create enemy instance
	var enemy = create_enemy(enemy_type)

	# Set spawn position
	var spawn_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var spawn_distance = randf_range(min_spawn_distance, spawn_radius)
	var spawn_position = player.global_position + (spawn_direction * spawn_distance)

	# Set enemy properties
	enemy.global_position = spawn_position
	enemy.target = player

	# Scale enemy stats based on difficulty
	enemy.max_health = int(enemy.max_health * (1 + difficulty * 0.1))
	enemy.current_health = enemy.max_health
	enemy.damage = int(enemy.damage * (1 + difficulty * 0.05))
	enemy.experience_value = int(enemy.experience_value * (1 + difficulty * 0.02))

	# Connect signals
	enemy.died.connect(_on_enemy_died)

	# Add to scene
	get_tree().current_scene.add_child(enemy)

# Create an enemy of the specified type
func create_enemy(type_name):
	# Get enemy properties
	var properties = enemy_types[type_name]

	# Create enemy node
	var enemy = CharacterBody2D.new()
	enemy.add_to_group("enemies")
	enemy.collision_layer = 4  # Enemy layer
	enemy.collision_mask = 3   # World and player layers

	# Create visual representation
	var rect = ColorRect.new()
	rect.color = properties.color
	rect.size = Vector2(properties.size * 2, properties.size * 2)
	rect.position = Vector2(-properties.size, -properties.size)
	enemy.add_child(rect)

	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = properties.size
	collision.shape = shape
	enemy.add_child(collision)

	# Create health bar
	var health_bar = ProgressBar.new()
	health_bar.max_value = properties.max_health
	health_bar.value = properties.max_health
	health_bar.show_percentage = false
	health_bar.size = Vector2(properties.size * 2 + 10, 5)
	health_bar.position = Vector2(-properties.size - 5, -properties.size - 15)
	enemy.add_child(health_bar)

	# We'll set properties in the script instead

	# Create script for enemy
	var script = GDScript.new()
	# Create script with properties from enemy type
	var script_code = "extends CharacterBody2D\n\n"
	script_code += "# Enemy properties\n"
	script_code += "var max_health = %d\n" % properties.max_health
	script_code += "var current_health = %d\n" % properties.max_health
	script_code += "var move_speed = %d\n" % properties.move_speed
	script_code += "var damage = %d\n" % properties.damage
	script_code += "var experience_value = %d\n\n" % properties.experience_value

	script_code += "# Target to follow\n"
	script_code += "var target = null\n\n"
	script_code += "# Signal for death\n"
	script_code += "signal died(position, experience)\n\n"

	script_code += "func _physics_process(delta):\n"
	script_code += "\tif target == null or !is_instance_valid(target):\n"
	script_code += "\t\t# Try to find player if target is lost\n"
	script_code += "\t\tvar players = get_tree().get_nodes_in_group(\"player\")\n"
	script_code += "\t\tif players.size() > 0:\n"
	script_code += "\t\t\ttarget = players[0]\n"
	script_code += "\t\telse:\n"
	script_code += "\t\t\treturn  # No target, don't move\n\n"

	script_code += "\t# Move towards target\n"
	script_code += "\tvar direction = (target.global_position - global_position).normalized()\n"
	script_code += "\tvelocity = direction * move_speed\n"
	script_code += "\tmove_and_slide()\n\n"

	script_code += "\t# Check for collision with player\n"
	script_code += "\tfor i in get_slide_collision_count():\n"
	script_code += "\t\tvar collision = get_slide_collision(i)\n"
	script_code += "\t\tif collision.get_collider().is_in_group(\"player\"):\n"
	script_code += "\t\t\tcollision.get_collider().take_damage(damage)\n\n"

	script_code += "# Take damage\n"
	script_code += "func take_damage(amount):\n"
	script_code += "\tcurrent_health -= amount\n\n"

	script_code += "\t# Update health bar\n"
	script_code += "\tfor child in get_children():\n"
	script_code += "\t\tif child is ProgressBar:\n"
	script_code += "\t\t\tchild.value = current_health\n\n"

	script_code += "\t# Check for death\n"
	script_code += "\tif current_health <= 0:\n"
	script_code += "\t\tdie()\n\n"

	script_code += "# Die and drop experience\n"
	script_code += "func die():\n"
	script_code += "\t# Emit signal with position and experience value\n"
	script_code += "\temit_signal(\"died\", global_position, experience_value)\n\n"

	script_code += "\t# Remove from scene\n"
	script_code += "\tqueue_free()\n"

	script.source_code = script_code
	script.reload()
	enemy.set_script(script)

	# Connect death signal if not already connected
	if !enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)

	return enemy

# Increase difficulty
func increase_difficulty():
	# Note: difficulty is already incremented in main.gd

	# Increase max enemies as difficulty increases
	max_enemies = min(200, max_enemies + 5)

# Signal for enemy death
signal enemy_died(position, experience)

# Handle enemy death
func _on_enemy_died(position, experience):
	# Debug output
	print("Enemy spawner received death signal at position: ", position, " with experience: ", experience)

	# Forward the signal to the main scene
	enemy_died.emit(position, experience)
