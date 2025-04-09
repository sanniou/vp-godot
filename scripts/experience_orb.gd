extends Area2D

var experience_value = 1
var move_speed = 0
var max_speed = 400
var acceleration = 800
var target = null
var is_attracting = false

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	$AttractTimer.timeout.connect(_on_attract_timer_timeout)

	# Disable collision for a short time to prevent immediate collection
	set_deferred("monitoring", false)
	await get_tree().create_timer(0.5).timeout
	set_deferred("monitoring", true)

func _process(delta):
	if is_attracting and target != null and is_instance_valid(target):
		# Calculate direction to player
		var direction = (target.global_position - global_position).normalized()

		# Accelerate towards player
		move_speed = min(move_speed + acceleration * delta, max_speed)

		# Move towards player
		global_position += direction * move_speed * delta

# Set the experience value
func set_value(value):
	experience_value = value

	# Scale the sprite based on value
	var scale_factor = 1.0 + (value / 10.0)
	scale = Vector2(scale_factor, scale_factor)

# Start attracting to player
func start_attracting(player):
	target = player
	is_attracting = true

# Signal handlers
func _on_body_entered(body):
	# Debug output
	print("Experience orb collided with: ", body, ", is in player group: ", body.is_in_group("player"))

	if body.is_in_group("player"):
		# Debug output
		print("Adding experience: ", experience_value)

		# Add experience to player
		var main = get_tree().current_scene
		main.add_experience(experience_value)

		# Destroy orb
		queue_free()

func _on_attract_timer_timeout():
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		start_attracting(players[0])
