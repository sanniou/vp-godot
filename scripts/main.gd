extends Node2D

# 预加载类
const AbstractRelic = preload("res://scripts/relics/abstract_relic.gd")
const RelicManager = preload("res://scripts/relics/relic_manager.gd")

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

# Weapon scenes
var magic_wand_scene = preload("res://scenes/weapons/magic_wand.tscn")
var flamethrower_scene = preload("res://scenes/weapons/flamethrower.tscn")
var gun_scene = preload("res://scenes/weapons/gun.tscn")
var knife_scene = preload("res://scenes/weapons/knife.tscn")
var shield_scene = preload("res://scenes/weapons/shield.tscn")
var lightning_scene = preload("res://scenes/weapons/lightning.tscn")

# New weapon scenes
var orbital_satellite_scene = preload("res://scenes/weapons/orbital_satellite.tscn")
var black_hole_bomb_scene = preload("res://scenes/weapons/black_hole_bomb.tscn")
var toxic_spray_scene = preload("res://scenes/weapons/toxic_spray.tscn")
var frost_staff_scene = preload("res://scenes/weapons/frost_staff.tscn")
var boomerang_scene = preload("res://scenes/weapons/boomerang.tscn")

# Achievement manager
var achievement_manager = null

# Relic manager
var relic_manager = null

# 预加载遗物管理器脚本
var relic_manager_script = preload("res://scripts/relics/relic_manager.gd")

# Weapon manager
var weapon_manager = null

# Regeneration timer for Golden Apple relic
var regeneration_timer = 0

# 升级选项相关
var current_upgrade_options = []  # 当前显示的升级选项
var max_rerolls = 3  # 每个选项最多重新随机次数
var option_rerolls = {}  # 存储每个选项已使用的重新随机次数

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

	# Initialize relic manager
	relic_manager = Node.new()
	relic_manager.set_script(load("res://scripts/relics/relic_manager.gd"))
	relic_manager.name = "RelicManager"
	add_child(relic_manager)

	# Load selected relics from global
	load_selected_relics()

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

		# Handle regeneration from Golden Apple relic
		if player and relic_manager and relic_manager.has_relic("golden_apple"):
			regeneration_timer += delta
			var relic = relic_manager.get_relic("golden_apple")
			if regeneration_timer >= relic.interval:
				regeneration_timer = 0
				player.heal(relic.value)

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
	regeneration_timer = 0

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

	# Initialize weapon manager
	weapon_manager = Node.new()
	weapon_manager.set_script(load("res://scripts/weapons/weapon_manager.gd"))

	# 设置武器容器
	weapon_manager.set_weapon_container(player.weapon_container)

	# Give player initial weapon
	# 暂时使用默认武器
	var wand = load("res://scenes/weapons/magic_wand.tscn").instantiate()
	player.weapon_container.add_child(wand)

	# 加载选择的遗物
	load_selected_relics()

	# 触发游戏开始事件，应用遗物效果
	if relic_manager:
		var event_data = {
			"player": player,
			"health_bar": health_bar,
			"experience_bar": experience_bar
		}

		# 触发游戏开始事件
		print("触发游戏开始事件，枚举值:", AbstractRelic.EventType.GAME_START)
		var modified_data = relic_manager.trigger_event(AbstractRelic.EventType.GAME_START, event_data)

		# 处理修改后的数据
		if modified_data.has("stat_boosts"):
			var stat_boosts = modified_data["stat_boosts"]

			# 应用属性加成
			if stat_boosts.has("max_health"):
				player.max_health += stat_boosts["max_health"]
				player.current_health = player.max_health
				health_bar.max_value = player.max_health
				health_bar.value = player.current_health

			if stat_boosts.has("move_speed"):
				player.move_speed += stat_boosts["move_speed"]

		# 处理时间扭曲器遗物效果
		if modified_data.has("enemy_speed_modifier"):
			enemy_spawner.enemy_speed_modifier = modified_data["enemy_speed_modifier"]
			print("应用敌人速度修改器:", enemy_spawner.enemy_speed_modifier)

		if modified_data.has("player_attack_speed_modifier"):
			var attack_speed_bonus = modified_data["player_attack_speed_modifier"]
			# 将攻击速度加成应用到所有武器
			for weapon in player.weapon_container.get_children():
				if "attack_speed" in weapon:
					weapon.attack_speed *= (1 + attack_speed_bonus)
			print("应用玩家攻击速度修改器:", attack_speed_bonus)

		# 处理自动升级
		print("检查自动升级标志:", modified_data)
		if modified_data.has("auto_level_up") and modified_data["auto_level_up"]:
			print("智慧水晶触发自动升级")
			# 在下一帧自动升级，避免在初始化过程中升级
			await get_tree().process_frame
			# 直接调用升级函数，不需要经验值
			player_level += 1

			# 计算新的升级所需经验值
			experience_to_level = int(experience_to_level * 1.2)  # 增加下一级所需的经验值

			# 显示升级效果
			show_level_up_screen()

	# Reset enemy spawner
	# print("Setting enemy_spawner.player to: ", player)
	enemy_spawner.player = player
	enemy_spawner.difficulty = 0
	# print("Enemy spawner reset, player: ", enemy_spawner.player, ", difficulty: ", enemy_spawner.difficulty)

# Update the timer display
func update_timer_display():
	var minutes = int(game_time / 60)
	var seconds = int(game_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

# Spawn an enemy
func spawn_enemy():
	# print("Main: Attempting to spawn enemy")
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
	# 在发布版本中去掉调试日志
	# print("Adding experience to player: ", amount, ", current experience: ", player_experience)

	# 触发经验获取事件，应用遗物效果
	if relic_manager:
		var event_data = {
			"experience": amount,
			"player": player
		}

		# 触发经验获取事件
		var modified_data = relic_manager.trigger_event(AbstractRelic.EventType.EXPERIENCE_GAIN, event_data)

		# 获取修改后的经验值
		amount = modified_data["experience"]

		# 显示经验加成效果（如果有）
		if modified_data.has("bonus_exp") and modified_data["bonus_exp"] > 0:
			var bonus = modified_data["bonus_exp"]
			var bonus_label = Label.new()
			bonus_label.text = "+" + str(int(bonus)) + " 经验"
			bonus_label.position = Vector2(-30, -30)
			bonus_label.modulate = Color(0.5, 1.0, 0.5, 1.0)
			player.add_child(bonus_label)

			# 动画效果
			var tween = player.create_tween()
			tween.tween_property(bonus_label, "position:y", -50, 0.5)
			tween.parallel().tween_property(bonus_label, "modulate:a", 0, 0.5)
			tween.tween_callback(func(): bonus_label.queue_free())

	player_experience += amount
	experience_bar.value = player_experience

	# Update achievement statistics
	if achievement_manager:
		achievement_manager.increment_statistic("experience_collected", amount)

	# Debug output
	# print("New experience: ", player_experience, ", experience bar value: ", experience_bar.value)

	# Check for level up
	if player_experience >= experience_to_level:
		level_up()

# Level up the player
func level_up():
	player_level += 1
	player_experience -= experience_to_level

	# Calculate new experience to level
	experience_to_level = int(experience_to_level * 1.2)  # Increase XP needed for next level

	# 触发升级事件，应用遗物效果
	if relic_manager:
		var event_data = {
			"player": player,
			"level": player_level,
			"experience_to_level": experience_to_level
		}

		# 触发升级事件
		var modified_data = relic_manager.trigger_event(1, event_data)  # 1 = LEVEL_UP

		# 获取修改后的数据
		if modified_data.has("experience_to_level"):
			experience_to_level = modified_data["experience_to_level"]

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

	# 重置重新随机计数器
	option_rerolls.clear()

	# 生成升级选项基础池
	var base_options = [
		{"type": "max_health", "name": "Max Health +20", "description": "Increase maximum health by 20", "amount": 20},
		{"type": "move_speed", "name": "Move Speed +20", "description": "Increase movement speed by 20", "amount": 20},
		{"type": "weapon_damage", "name": "Weapon Damage +20%", "description": "Increase all weapon damage by 20%", "amount": 0.2}
	]

	# 如果有遗物管理器，允许遗物修改基础选项
	if relic_manager and relic_manager.has_method("modify_upgrade_options"):
		base_options = relic_manager.modify_upgrade_options(base_options)

	# 获取当前可用的重新随机次数
	max_rerolls = 3  # 默认值
	if relic_manager and relic_manager.has_method("get_reroll_count"):
		max_rerolls = relic_manager.get_reroll_count()

	# 检查玩家拥有的武器
	var available_weapons = [
		"flamethrower", "gun", "knife", "shield", "lightning",
		"orbital_satellite", "black_hole_bomb", "toxic_spray", "frost_staff", "boomerang"
	]
	var has_weapons = {}

	# 使用武器管理器获取已装备武器
	if weapon_manager:
		# 添加武器升级选项
		for weapon_id in weapon_manager.equipped_weapons:
			has_weapons[weapon_id] = true

			# 获取武器实例
			var weapon = weapon_manager.get_weapon(weapon_id)
			if weapon:
				# 安全地获取武器升级选项
				var weapon_options = []
				if weapon.has_method("get_upgrade_options"):
					weapon_options = weapon.get_upgrade_options()
				else:
					# 默认选项
					weapon_options = [
						{"type": 0, "name": "伤害 +5", "description": "增加武器伤害", "icon": "💥"},
						{"type": 1, "name": "攻击速度 +20%", "description": "增加武器攻击速度", "icon": "⚡"}
					]

				# 添加到选项列表
				for option in weapon_options:
					base_options.append({
						"type": "weapon_upgrade",
						"weapon": weapon,
						"upgrade_type": option.type,
						"name": option.name,
						"description": option.description,
						"icon": option.icon if "icon" in option else ""
					})

	# 添加新武器选项
	for weapon_id in available_weapons:
		if not has_weapons.has(weapon_id):
			# 根据武器ID获取对应的场景
			var weapon_scene = null
			var weapon_name = ""
			var weapon_description = ""

			match weapon_id:
				"flamethrower":
					weapon_scene = flamethrower_scene
					weapon_name = "Flamethrower"
					weapon_description = "A weapon that deals continuous damage in a cone"
				"gun":
					weapon_scene = gun_scene
					weapon_name = "Gun"
					weapon_description = "A weapon that fires bullets at enemies"
				"knife":
					weapon_scene = knife_scene
					weapon_name = "Knife"
					weapon_description = "A melee weapon that damages enemies in a wide arc"
				"shield":
					weapon_scene = shield_scene
					weapon_name = "Shield"
					weapon_description = "Protects from damage and burns nearby enemies"
				"lightning":
					weapon_scene = lightning_scene
					weapon_name = "Lightning"
					weapon_description = "Strikes enemies with chain lightning"
				"orbital_satellite":
					weapon_scene = orbital_satellite_scene
					weapon_name = "Orbital Satellite"
					weapon_description = "Satellites orbit around you, damaging enemies they touch"
				"black_hole_bomb":
					weapon_scene = black_hole_bomb_scene
					weapon_name = "Black Hole Bomb"
					weapon_description = "Creates a black hole that pulls and damages enemies"
				"toxic_spray":
					weapon_scene = toxic_spray_scene
					weapon_name = "Toxic Spray"
					weapon_description = "Sprays poison that deals damage over time"
				"frost_staff":
					weapon_scene = frost_staff_scene
					weapon_name = "Frost Staff"
					weapon_description = "Slows enemies and deals damage with ice magic"
				"boomerang":
					weapon_scene = boomerang_scene
					weapon_name = "Boomerang"
					weapon_description = "Returns after being thrown, damaging enemies along its path"

			# 添加到选项列表
			if weapon_scene:
				base_options.append({
					"type": "new_weapon",
					"name": weapon_name,
					"description": weapon_description,
					"weapon": weapon_scene
				})

	# Shuffle options
	base_options.shuffle()

	# 获取升级选项数量
	var num_options = 3  # 默认值

	# 使用遗物管理器获取升级选项数量
	if relic_manager:
		num_options = relic_manager.get_upgrade_options_count()

	# 保存当前选项以供重新随机使用
	current_upgrade_options = base_options.duplicate(true)

	# Create buttons for each option
	for i in range(min(num_options, base_options.size())):
		var option = base_options[i]

		# 创建选项容器
		var option_container = VBoxContainer.new()
		option_container.custom_minimum_size = Vector2(300, 120)
		option_container.size_flags_horizontal = Control.SIZE_FILL
		option_container.size_flags_vertical = Control.SIZE_FILL

		# 创建选项按钮
		var button = Button.new()
		button.text = option.name + "\n" + option.description
		button.custom_minimum_size = Vector2(300, 80)
		button.size_flags_horizontal = Control.SIZE_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL

		# Connect button press based on option type
		match option.type:
			"new_weapon":
				button.pressed.connect(func(): select_upgrade(option.type, null, option.weapon))
			"weapon_upgrade":
				button.pressed.connect(func(): select_upgrade(option.type, null, null, option.weapon, option.upgrade_type))
			_:
				button.pressed.connect(func(): select_upgrade(option.type, option.amount))

		# 创建重新随机按钮
		var reroll_button = Button.new()
		reroll_button.text = "Reroll (0/" + str(max_rerolls) + ")"
		reroll_button.custom_minimum_size = Vector2(300, 30)
		reroll_button.size_flags_horizontal = Control.SIZE_FILL

		# 设置重新随机按钮的标识
		reroll_button.set_meta("option_index", i)

		# 初始化重新随机计数器
		option_rerolls[i] = 0

		# 连接重新随机按钮事件
		reroll_button.pressed.connect(func(): reroll_option(i, reroll_button))

		# 添加到容器
		option_container.add_child(button)
		option_container.add_child(reroll_button)
		upgrade_options.add_child(option_container)

	# Show the screen
	level_up_screen.visible = true

# Handle player selecting an upgrade
func select_upgrade(upgrade_type, upgrade_amount = null, weapon_scene = null, target_weapon = null, weapon_upgrade_type = null):
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
			if weapon_manager:
				for weapon_id in weapon_manager.equipped_weapons:
					var weapon = weapon_manager.get_weapon(weapon_id)
					if weapon and "damage" in weapon:
						weapon.damage = int(weapon.damage * (1 + upgrade_amount))
		"new_weapon":
			# Add new weapon to player
			if weapon_scene and weapon_manager:
				# 从场景路径中提取武器ID
				var path = weapon_scene.resource_path
				var weapon_id = path.get_file().get_basename().replace(".tscn", "")

				# 添加武器
				weapon_manager.add_weapon(weapon_id)
		"weapon_upgrade":
			# Upgrade specific weapon
			if target_weapon and weapon_manager:
				# 获取武器ID
				var weapon_id = target_weapon.name.to_lower()

				# 升级武器
				weapon_manager.upgrade_weapon(weapon_id, weapon_upgrade_type)

	# Hide level up screen and resume game
	level_up_screen.visible = false
	get_tree().paused = false

# 重新随机升级选项
func reroll_option(option_index, reroll_button):
	# 检查是否还有重新随机次数
	if option_rerolls[option_index] >= max_rerolls:
		return

	# 增加重新随机计数器
	option_rerolls[option_index] += 1

	# 更新重新随机按钮文本
	reroll_button.text = "Reroll (" + str(option_rerolls[option_index]) + "/" + str(max_rerolls) + ")"

	# 如果达到最大重新随机次数，禁用按钮
	if option_rerolls[option_index] >= max_rerolls:
		reroll_button.disabled = true

	# 获取当前选项容器
	var option_container = reroll_button.get_parent()
	var option_button = option_container.get_child(0)  # 第一个子节点是选项按钮

	# 从当前选项池中随机选择一个新选项
	var available_options = current_upgrade_options.duplicate(true)
	available_options.shuffle()

	# 如果有遗物管理器，允许遗物修改重新随机结果
	if relic_manager and relic_manager.has_method("modify_rerolled_options"):
		available_options = relic_manager.modify_rerolled_options(option_index, option_rerolls[option_index], available_options)

	# 选择一个新选项
	var new_option = available_options[0]

	# 更新选项按钮文本
	option_button.text = new_option.name + "\n" + new_option.description

	# 断开原有的信号连接
	for connection in option_button.pressed.get_connections():
		option_button.pressed.disconnect(connection.callable)

	# 连接新的信号
	match new_option.type:
		"new_weapon":
			option_button.pressed.connect(func(): select_upgrade(new_option.type, null, new_option.weapon))
		"weapon_upgrade":
			option_button.pressed.connect(func(): select_upgrade(new_option.type, null, null, new_option.weapon, new_option.upgrade_type))
		_:
			option_button.pressed.connect(func(): select_upgrade(new_option.type, new_option.amount))

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
	# 检查是否已经有遗物选择场景
	if has_node("RelicSelection"):
		print("Relic selection scene already exists")
		return

	# 暂停游戏
	get_tree().paused = true

	# 创建遗物选择场景
	var relic_selection_scene = load("res://scenes/relic_selection.tscn")
	var relic_selection = relic_selection_scene.instantiate()

	# 添加到场景树
	add_child(relic_selection)

	# 设置遗物选择场景的属性
	relic_selection.main_scene_instance = self

	# 隐藏开始界面
	start_screen.visible = false

	# 打印调试信息
	print("Relic selection scene added to main scene")

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
	# print("Spawning experience orb at position: ", position, " with value: ", value)

	var orb = experience_orb_scene.instantiate()
	orb.global_position = position
	orb.set_value(value)
	game_world.add_child(orb)

	# Debug output
	# print("Experience orb added to scene")

# Player signal handlers
func _on_player_health_changed(new_health):
	health_bar.value = new_health

func _on_player_died():
	# 触发玩家死亡事件，应用遗物效果
	if relic_manager:
		var event_data = {
			"player": player,
			"prevent_death": false,
			"heal_percent": 0
		}

		# 触发玩家死亡事件
		print("触发玩家死亡事件，枚举值:", AbstractRelic.EventType.PLAYER_DEATH)
		var modified_data = relic_manager.trigger_event(AbstractRelic.EventType.PLAYER_DEATH, event_data)

		print("玩家死亡事件返回数据:", modified_data)

		# 检查是否防止死亡
		if modified_data.has("prevent_death") and modified_data["prevent_death"]:
			# 恢复生命值
			var heal_amount = player.max_health * modified_data["heal_percent"]
			player.current_health = heal_amount
			health_bar.value = player.current_health
			return

	# 如果没有防止死亡，则游戏结束
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

# Load selected relics from global
func load_selected_relics():
	# Check if RelicGlobal exists
	var relic_global = Engine.get_main_loop().root.get_node_or_null("RelicGlobal")
	if relic_global:
		# Equip selected relics
		for relic_id in relic_global.selected_relics:
			relic_manager.equip_relic(relic_id)

		# Debug output
		# print("Equipped relics: ", relic_manager.get_equipped_relics_info())



# Enemy signal handlers
func _on_enemy_died(position, experience):
	# Debug output
	# print("Main scene received enemy_died signal at position: ", position, " with experience: ", experience)

	# 触发敌人死亡事件，应用遗物效果
	if relic_manager:
		var event_data = {
			"position": position,
			"experience_value": experience,
			"player": player
		}

		# 触发敌人死亡事件
		var modified_data = relic_manager.trigger_event(AbstractRelic.EventType.ENEMY_KILLED, event_data)

		# 处理经验催化剂遗物效果
		if modified_data.has("spawn_extra_orb") and modified_data["spawn_extra_orb"]:
			var extra_value = 1
			if modified_data.has("extra_orb_value"):
				extra_value = modified_data["extra_orb_value"]

			# 生成额外的经验球
			var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
			spawn_experience_orb(position + offset, extra_value)

	# Increment enemy defeat counter
	enemies_defeated += 1

	# Update achievement statistics
	if achievement_manager:
		achievement_manager.update_statistic("enemies_defeated", enemies_defeated)

	# Spawn experience orb
	spawn_experience_orb(position, experience)

# 处理游戏退出时的资源释放
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# 清理资源
		if weapon_manager:
			weapon_manager.queue_free()
			weapon_manager = null

		if relic_manager:
			relic_manager.queue_free()
			relic_manager = null

		if enemy_spawner:
			enemy_spawner.queue_free()
			enemy_spawner = null

		if achievement_manager:
			achievement_manager.queue_free()
			achievement_manager = null

		# 退出游戏
		get_tree().quit()
