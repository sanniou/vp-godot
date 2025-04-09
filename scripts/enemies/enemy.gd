extends CharacterBody2D
class_name Enemy

signal died(position, experience)

# Enemy stats
var max_health = 30
var current_health = max_health
var move_speed = 100
var damage = 10
var experience_value = 5

# Target (usually the player)
@export var target: Node2D = null

# Health bar
@onready var health_bar = $HealthBar

func _ready():
	# Add to enemies group
	add_to_group("enemies")

	# Initialize health
	current_health = max_health

func _physics_process(delta):
	if target == null or !is_instance_valid(target):
		# Try to find player if target is lost
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
		else:
			return  # No target, don't move

	# Move towards target
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed

	# Apply movement
	move_and_slide()

# Take damage
func take_damage(amount):
	current_health -= amount

	# Update health bar
	if health_bar:
		health_bar.value = (float(current_health) / max_health) * 100

	# Flash to indicate damage
	modulate = Color(1, 0.3, 0.3, 0.7)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

	# Check for death
	if current_health <= 0:
		die()

# Enemy death
func die():
	# Debug output
	print("Enemy died at position: ", global_position, " with experience: ", experience_value)

	# Emit signal with position and experience value
	died.emit(global_position, experience_value)

	# Play death animation
	var death_animation = create_tween()

	# Disable collision
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)

	# Hide health bar
	if health_bar:
		health_bar.visible = false

	# Fade out and scale down
	death_animation.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	death_animation.parallel().tween_property(self, "scale", Vector2(0.1, 0.1), 0.5)

	# Destroy enemy after animation
	await death_animation.finished
	queue_free()
