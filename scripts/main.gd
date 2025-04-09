extends Node2D

# Game state variables
var game_time = 0
var game_running = true
var player_level = 1
var player_experience = 0
var experience_to_level = 100
var enemy_spawn_timer = 0
var enemy_spawn_interval = 1.0  # Spawn enemies every second
var difficulty_increase_timer = 0
var difficulty_increase_interval = 60.0  # Increase difficulty every minute

# Scenes
var player_scene = preload("res://scenes/player/player.tscn")
var experience_orb_scene = preload("res://scenes/experience_orb.tscn")
var magic_wand_scene = preload("res://scenes/weapons/magic_wand.tscn")
var flamethrower_scene = preload("res://scenes/weapons/flamethrower.tscn")

# Achievement manager
var achievement_manager = null

# References
var player = null
var enemy_spawner = null

# Game statistics
var enemies_defeated = 0

# References to UI elements
@onready var health_bar = $UI/GameUI/HealthBar
@onready var experience_bar = $UI/GameUI/ExperienceBar
@onready var timer_label = $UI/GameUI/Timer
@onready var level_label = $UI/GameUI/LevelLabel
@onready var game_over_screen = $UI/GameOverScreen
@onready var level_up_screen = $UI/LevelUpScreen
@onready var upgrade_options = $UI/LevelUpScreen/UpgradeOptions
@onready var start_screen = $UI/StartScreen
@onready var pause_screen = $UI/PauseScreen
@onready var game_ui = $UI/GameUI
@onready var game_world = $GameWorld
@onready var player_container = $GameWorld/Player
@onready var enemies_container = $GameWorld/Enemies

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize UI
	experience_bar.max_value = experience_to_level
	experience_bar.value = 0

	# Connect signals
	$UI/GameOverScreen/RestartButton.pressed.connect(_on_restart_button_pressed)
	$UI/StartScreen/StartButton.pressed.connect(_on_start_button_pressed)
	$UI/PauseScreen/ResumeButton.pressed.connect(_on_resume_button_pressed)
	$UI/PauseScreen/QuitButton.pressed.connect(_on_quit_button_pressed)
	$UI/GameOverScreen/AchievementsButton.pressed.connect(_on_achievements_button_pressed)
	$UI/AchievementsScreen/BackButton.pressed.connect(_on_achievements_back_button_pressed)

	# Create enemy spawner
	enemy_spawner = Node2D.new()
	var spawner_script = load("res://scripts/enemies/enemy_spawner.gd")
	if spawner_script == null:
		print("Error: Failed to load enemy_spawner.gd script")
	else:
		print("Successfully loaded enemy_spawner.gd script")
		enemy_spawner.set_script(spawner_script)
		game_world.add_child(enemy_spawner)

		# Connect enemy spawner signals
		if enemy_spawner.has_signal("enemy_died"):
			print("Connecting enemy_died signal")
			enemy_spawner.enemy_died.connect(_on_enemy_died)
		else:
			print("Error: enemy_spawner does not have enemy_died signal")

	# Initialize achievement manager
	achievement_manager = Node.new()
	achievement_manager.set_script(load("res://scripts/achievement_manager.gd"))
	add_child(achievement_manager)

	# Show start screen
	show_start_screen()

# Called every frame
func _process(delta):
	# Handle pause input
	if Input.is_action_just_pressed("ui_cancel") and game_running:
		toggle_pause()

	if game_running:
		# Update game time
		game_time += delta
		update_timer_display()

		# Update time survived statistic
		if achievement_manager:
			achievement_manager.update_statistic("time_survived", game_time)

		# Handle enemy spawning
		enemy_spawn_timer += delta
		if enemy_spawn_timer >= enemy_spawn_interval:
			enemy_spawn_timer = 0
			spawn_enemy()

		# Handle difficulty increase
		difficulty_increase_timer += delta
		if difficulty_increase_timer >= difficulty_increase_interval:
			difficulty_increase_timer = 0
			increase_difficulty()

# Start or restart the game
func start_game():
	# Reset game state
	game_time = 0
	game_running = true
	player_level = 1
	player_experience = 0
	experience_to_level = 100
	enemy_spawn_timer = 0
	enemy_spawn_interval = 1.0
	difficulty_increase_timer = 0

	# Reset achievement statistics
	if achievement_manager:
		achievement_manager.reset_game_statistics()

	# Reset UI
	health_bar.value = 100
	experience_bar.max_value = experience_to_level
	experience_bar.value = 0
	level_label.text = "Level: %d" % player_level
	game_over_screen.visible = false
	level_up_screen.visible = false

	# Clear existing enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

	# Clear existing experience orbs
	for orb in get_tree().get_nodes_in_group("experience"):
		orb.queue_free()

	# Clear existing player
	if player != null and is_instance_valid(player):
		player.queue_free()

	# Spawn player
	player = player_scene.instantiate()
	player_container.add_child(player)
	player.global_position = Vector2.ZERO

	# Connect player signals
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)

	# Give player initial weapon
	var wand = magic_wand_scene.instantiate()
	player.weapon_container.add_child(wand)

	# Reset enemy spawner
	print("Setting enemy_spawner.player to: ", player)
	enemy_spawner.player = player
	enemy_spawner.difficulty = 0
	print("Enemy spawner reset, player: ", enemy_spawner.player, ", difficulty: ", enemy_spawner.difficulty)

# Update the timer display
func update_timer_display():
	var minutes = int(game_time / 60)
	var seconds = int(game_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

# Spawn an enemy
func spawn_enemy():
	print("Main: Attempting to spawn enemy")
	enemy_spawner.spawn_enemy()

# Increase game difficulty
func increase_difficulty():
	# Increase difficulty counter
	enemy_spawner.difficulty += 1

	# Decrease spawn interval (more enemies)
	enemy_spawn_interval = max(0.2, enemy_spawn_interval * 0.9)

	# Increase enemy difficulty
	enemy_spawner.increase_difficulty()

	# Special difficulty milestones
	match enemy_spawner.difficulty:
		5:  # At 5 minutes
			# Spawn a wave of enemies
			spawn_enemy_wave(10, "basic")
			# Show difficulty increase message
			show_difficulty_message("Difficulty increased!\nMore enemies are coming!")
		10:  # At 10 minutes
			# Spawn a wave of strong enemies
			spawn_enemy_wave(5, "strong")
			# Increase enemy max health
			enemy_spawner.max_enemies += 20
			# Show difficulty increase message
			show_difficulty_message("Difficulty increased!\nStronger enemies are appearing!")
		15:  # At 15 minutes
			# Spawn a wave of ranged enemies
			spawn_enemy_wave(3, "ranged")
			# Increase enemy damage
			enemy_spawn_interval = max(0.1, enemy_spawn_interval * 0.8)
			# Show difficulty increase message
			show_difficulty_message("Difficulty increased!\nEnemies are more aggressive!")
		20:  # At 20 minutes
			# Spawn a mix of enemies
			spawn_enemy_wave(5, "basic")
			spawn_enemy_wave(5, "strong")
			spawn_enemy_wave(5, "ranged")
			# Increase enemy stats dramatically
			enemy_spawner.max_enemies += 30
			# Show difficulty increase message
			show_difficulty_message("Final wave!\nSurvive if you can!")

# Add experience to the player
func add_experience(amount):
	# Debug output
	print("Adding experience to player: ", amount, ", current experience: ", player_experience)

	player_experience += amount
	experience_bar.value = player_experience

	# Update achievement statistics
	if achievement_manager:
		achievement_manager.increment_statistic("experience_collected", amount)

	# Debug output
	print("New experience: ", player_experience, ", experience bar value: ", experience_bar.value)

	# Check for level up
	if player_experience >= experience_to_level:
		level_up()

# Level up the player
func level_up():
	player_level += 1
	player_experience -= experience_to_level
	experience_to_level = int(experience_to_level * 1.2)  # Increase XP needed for next level

	experience_bar.max_value = experience_to_level
	experience_bar.value = player_experience

	# Update level label
	level_label.text = "Level: %d" % player_level

	# Update achievement statistics
	if achievement_manager:
		achievement_manager.update_statistic("player_level", player_level)
		achievement_manager.increment_statistic("levels_gained")

	# Show level up screen
	show_level_up_screen()

# Show the level up screen with upgrade options
func show_level_up_screen():
	# Pause the game
	get_tree().paused = true

	# Clear previous upgrade options
	for child in upgrade_options.get_children():
		child.queue_free()

	# Generate upgrade options
	var options = [
		{"type": "max_health", "name": "Max Health +20", "description": "Increase maximum health by 20", "amount": 20},
		{"type": "move_speed", "name": "Move Speed +20", "description": "Increase movement speed by 20", "amount": 20},
		{"type": "weapon_damage", "name": "Weapon Damage +20%", "description": "Increase all weapon damage by 20%", "amount": 0.2}
	]

	# Add weapon options
	var has_flamethrower = false
	for weapon in player.weapon_container.get_children():
		if weapon.name == "Flamethrower":
			has_flamethrower = true
			break

	# Add flamethrower if player doesn't have it yet
	if !has_flamethrower:
		options.append({"type": "new_weapon", "name": "Flamethrower", "description": "A weapon that deals continuous damage in a cone", "weapon": flamethrower_scene})

	# Shuffle options
	options.shuffle()

	# Create buttons for each option (up to 3)
	for i in range(min(3, options.size())):
		var option = options[i]
		var button = Button.new()
		button.text = option.name + "\n" + option.description
		button.custom_minimum_size = Vector2(300, 80)

		# Connect button press based on option type
		if option.type == "new_weapon":
			button.pressed.connect(func(): select_upgrade(option.type, null, option.weapon))
		else:
			button.pressed.connect(func(): select_upgrade(option.type, option.amount))

		upgrade_options.add_child(button)

	# Show the screen
	level_up_screen.visible = true

# Handle player selecting an upgrade
func select_upgrade(upgrade_type, upgrade_amount = null, weapon_scene = null):
	# Apply the selected upgrade
	match upgrade_type:
		"max_health":
			player.upgrade_stat("max_health", upgrade_amount)
			health_bar.max_value = player.max_health
			health_bar.value = player.current_health
		"move_speed":
			player.upgrade_stat("move_speed", upgrade_amount)
		"weapon_damage":
			# Increase damage for all weapons
			for weapon in player.weapon_container.get_children():
				weapon.damage = int(weapon.damage * (1 + upgrade_amount))
		"new_weapon":
			# Add new weapon to player
			if weapon_scene:
				var weapon = weapon_scene.instantiate()
				player.weapon_container.add_child(weapon)

	# Hide level up screen and resume game
	level_up_screen.visible = false
	get_tree().paused = false

# Show start screen
func show_start_screen():
	# Hide game UI
	game_ui.visible = false

	# Show start screen
	start_screen.visible = true

	# Pause the game
	get_tree().paused = true

# Start button pressed
func _on_start_button_pressed():
	# Hide start screen
	start_screen.visible = false

	# Show game UI
	game_ui.visible = true

	# Start the game
	start_game()

	# Resume the game
	get_tree().paused = false

# Toggle pause state
func toggle_pause():
	if pause_screen.visible:
		# Resume game
		pause_screen.visible = false
		get_tree().paused = false
	else:
		# Pause game
		pause_screen.visible = true
		get_tree().paused = true

# Resume button pressed
func _on_resume_button_pressed():
	toggle_pause()

# Quit button pressed
func _on_quit_button_pressed():
	# Hide pause screen
	pause_screen.visible = false

	# Show start screen
	show_start_screen()

# Game over
func game_over():
	game_running = false

	# Update game over stats
	var stats_text = "Time Survived: %02d:%02d\n" % [int(game_time / 60), int(game_time) % 60]
	stats_text += "Level Reached: %d\n" % player_level
	stats_text += "Enemies Defeated: %d\n\n" % enemies_defeated

	# Add achievement statistics if available
	if achievement_manager:
		stats_text += "Achievements Unlocked: %d/%d\n" % [
			achievement_manager.achievements.values().filter(func(a): return a.unlocked).size(),
			achievement_manager.achievements.size()
		]

		# Add recently unlocked achievements
		var recent_achievements = achievement_manager.achievements.values().filter(func(a): return a.unlocked)
		if recent_achievements.size() > 0:
			stats_text += "\nRecent Achievements:\n"
			for i in range(min(3, recent_achievements.size())):
				var achievement = recent_achievements[i]
				stats_text += achievement.icon + " " + achievement.title + "\n"

	$UI/GameOverScreen/StatsLabel.text = stats_text

	# Show game over screen
	game_over_screen.visible = true

	# Pause the game
	get_tree().paused = true

# Restart button pressed
func _on_restart_button_pressed():
	# Hide game over screen
	game_over_screen.visible = false

	# Reset statistics
	enemies_defeated = 0

	# Start the game
	start_game()

	# Resume the game
	get_tree().paused = false

# Achievements button pressed
func _on_achievements_button_pressed():
	# Hide game over screen
	game_over_screen.visible = false

	# Update achievements list
	if achievement_manager:
		$UI/AchievementsScreen/ScrollContainer/AchievementsList.text = achievement_manager.get_achievements_text()

	# Show achievements screen
	$UI/AchievementsScreen.visible = true

# Achievements back button pressed
func _on_achievements_back_button_pressed():
	# Hide achievements screen
	$UI/AchievementsScreen.visible = false

	# Show game over screen
	game_over_screen.visible = true

# Spawn an experience orb at the given position
func spawn_experience_orb(position, value):
	# Debug output
	print("Spawning experience orb at position: ", position, " with value: ", value)

	var orb = experience_orb_scene.instantiate()
	orb.global_position = position
	orb.set_value(value)
	game_world.add_child(orb)

	# Debug output
	print("Experience orb added to scene")

# Player signal handlers
func _on_player_health_changed(new_health):
	health_bar.value = new_health

func _on_player_died():
	game_over()

# Spawn a wave of enemies
func spawn_enemy_wave(count, enemy_type):
	for i in range(count):
		# Create enemy instance
		var enemy = enemy_spawner.create_enemy(enemy_type)

		# Set spawn position (distributed around the player in a circle)
		var angle = 2 * PI * i / count
		var spawn_direction = Vector2(cos(angle), sin(angle))
		var spawn_distance = enemy_spawner.min_spawn_distance + 50
		var spawn_position = player.global_position + (spawn_direction * spawn_distance)

		# Set enemy properties
		enemy.global_position = spawn_position
		enemy.target = player

		# Scale enemy stats based on difficulty
		enemy.max_health = int(enemy.max_health * (1 + enemy_spawner.difficulty * 0.1))
		enemy.current_health = enemy.max_health
		enemy.damage = int(enemy.damage * (1 + enemy_spawner.difficulty * 0.05))
		enemy.experience_value = int(enemy.experience_value * (1 + enemy_spawner.difficulty * 0.02))

		# Connect signals
		enemy.died.connect(enemy_spawner._on_enemy_died)

		# Add to scene
		get_tree().current_scene.add_child(enemy)

# Show difficulty increase message
func show_difficulty_message(message):
	# Create message label
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.theme_override_font_sizes = {"font_size": 24}
	label.theme_override_colors = {"font_color": Color(1, 0.5, 0, 1)}
	label.theme_override_constants = {"shadow_offset_x": 2, "shadow_offset_y": 2}
	label.theme_override_colors = {"font_shadow_color": Color(0, 0, 0, 0.5)}

	# Position in center of screen
	label.anchors_preset = Control.PRESET_CENTER
	label.anchor_left = 0.5
	label.anchor_top = 0.3
	label.anchor_right = 0.5
	label.anchor_bottom = 0.3
	label.offset_left = -200
	label.offset_top = -50
	label.offset_right = 200
	label.offset_bottom = 50

	# Add to UI
	$UI.add_child(label)

	# Animate and remove after delay
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0, 2.0).set_delay(3.0)
	await tween.finished
	label.queue_free()

# Enemy signal handlers
func _on_enemy_died(position, experience):
	# Debug output
	print("Main scene received enemy_died signal at position: ", position, " with experience: ", experience)

	# Increment enemy defeat counter
	enemies_defeated += 1

	# Update achievement statistics
	if achievement_manager:
		achievement_manager.update_statistic("enemies_defeated", enemies_defeated)

	# Spawn experience orb
	spawn_experience_orb(position, experience)
