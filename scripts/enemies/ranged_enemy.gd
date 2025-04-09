extends "res://scripts/enemies/enemy.gd"
class_name RangedEnemy

# Ranged enemy specific properties
var attack_range = 300
var attack_cooldown = 2.0
var attack_timer = 0
var projectile_speed = 150

func _ready():
	# Call parent ready function
	super._ready()
	
	# Set ranged enemy stats
	max_health = 50
	current_health = max_health
	move_speed = 70
	damage = 15
	experience_value = 10

func _physics_process(delta):
	if target == null or !is_instance_valid(target):
		# Try to find player if target is lost
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
		else:
			return  # No target, don't move
	
	# Calculate distance to target
	var distance_to_target = global_position.distance_to(target.global_position)
	
	# If within attack range, stop and attack
	if distance_to_target <= attack_range:
		# Update attack timer
		attack_timer += delta
		
		# Attack if cooldown is over
		if attack_timer >= attack_cooldown:
			attack_timer = 0
			fire_projectile()
		
		# Move away if too close
		if distance_to_target < attack_range * 0.7:
			var direction = (global_position - target.global_position).normalized()
			velocity = direction * move_speed
		else:
			velocity = Vector2.ZERO
	else:
		# Move towards target
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * move_speed
	
	# Apply movement
	move_and_slide()

# Fire a projectile at the target
func fire_projectile():
	# Create projectile
	var projectile = ColorRect.new()
	projectile.color = Color(0.8, 0.2, 0.8, 1.0)
	projectile.size = Vector2(10, 10)
	projectile.position = Vector2(-5, -5)  # Center the rect
	
	# Create projectile container
	var projectile_node = Area2D.new()
	projectile_node.global_position = global_position
	projectile_node.add_child(projectile)
	
	# Set up collision
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 5
	collision_shape.shape = shape
	projectile_node.add_child(collision_shape)
	
	# Set collision layers
	projectile_node.collision_layer = 0
	projectile_node.collision_mask = 2  # Player layer
	
	# Add to scene
	get_tree().current_scene.add_child(projectile_node)
	
	# Calculate direction to target
	var direction = (target.global_position - global_position).normalized()
	
	# Create script for projectile
	var script = GDScript.new()
	script.source_code = '''
extends Area2D

var velocity = Vector2.ZERO
var damage = 0
var lifetime = 0
var max_lifetime = 5.0

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	position += velocity * delta
	
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()
'''
	script.reload()
	
	# Apply script to projectile
	projectile_node.set_script(script)
	
	# Set projectile properties
	projectile_node.velocity = direction * projectile_speed
	projectile_node.damage = damage
