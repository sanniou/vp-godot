extends CharacterBody2D

signal health_changed(new_health)
signal died

# Player stats
var max_health = 100
var current_health = max_health
var move_speed = 300
var is_invincible = false

# References
@onready var invincibility_timer = $InvincibilityTimer
@onready var weapon_container = $WeaponContainer
@onready var hit_box = $HitBox

func _ready():
	# Add to player group
	add_to_group("player")

	# Connect signals
	hit_box.body_entered.connect(_on_hit_box_body_entered)
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)

func _physics_process(_delta):
	# Get input direction
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Set velocity
	if direction.length() > 0.1:
		velocity = direction * move_speed
	else:
		# Immediately stop when no input
		velocity = Vector2.ZERO

	# Move the player
	move_and_slide()

# Take damage
func take_damage(amount):
	if is_invincible:
		return

	current_health -= amount
	health_changed.emit(current_health)

	# Enhanced visual feedback for damage
	# 1. Flash the player red
	modulate = Color(1, 0, 0, 1)

	# 2. Create a screen shake effect
	var camera = $Camera2D
	if camera:
		var shake_strength = 5.0
		var shake_duration = 0.2
		var shake_tween = create_tween()
		shake_tween.tween_method(func(s): camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s)),
							shake_strength, 0, shake_duration)

	# 3. Create a damage animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.5), 0.1)
	tween.tween_property(self, "modulate", Color(1, 0, 0, 1), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.5), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)

	# Start invincibility
	is_invincible = true
	invincibility_timer.start()

	# Check for death
	if current_health <= 0:
		die()

# Heal the player
func heal(amount):
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health)

# Player death
func die():
	died.emit()
	# We don't queue_free the player, as the main scene will handle game over

# Add a weapon to the player
func add_weapon(weapon_scene, level = 1):
	# Check if we already have this weapon
	for weapon in weapon_container.get_children():
		if weapon.name == weapon_scene.instance().name:
			# Upgrade existing weapon
			weapon.upgrade(level)
			return

	# Add new weapon
	var weapon_instance = weapon_scene.instance()
	weapon_instance.level = level
	weapon_container.add_child(weapon_instance)

# Upgrade a specific stat
func upgrade_stat(stat_name, amount):
	match stat_name:
		"max_health":
			max_health += amount
			heal(amount)  # Heal by the amount of max health increase
		"move_speed":
			move_speed += amount

# Signal handlers
func _on_hit_box_body_entered(body):
	if body.is_in_group("enemies"):
		take_damage(body.damage)

func _on_invincibility_timer_timeout():
	is_invincible = false
	modulate = Color(1, 1, 1, 1)  # Reset color
