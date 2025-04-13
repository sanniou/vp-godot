extends Node2D

# 预加载类
const AbstractRelic = preload("res://scripts/relics/abstract_relic.gd")
const RelicManager = preload("res://scripts/relics/relic_manager.gd")
const SimpleAchievementSystem = preload("res://scripts/simple_achievement_system.gd")
const ExperienceManager = preload("res://scripts/experience/experience_manager.gd")
const ExperienceOrbManager = preload("res://scripts/experience/experience_orb_manager.gd")
const PerformanceMonitor = preload("res://scripts/performance/performance_monitor.gd")

# Game state variables
var game_time = 0
var game_running = true
var enemy_spawn_timer = 0
var enemy_spawn_interval = 1.0  # Spawn enemies every second
var difficulty_increase_timer = 0
var difficulty_increase_interval = 60.0  # Increase difficulty every minute

# 性能监控器
var performance_monitor = null

# 精英/Boss进度条变量
var special_enemy_progress = 0.0
var special_enemy_progress_max = 100.0
var special_enemy_progress_rate = 0.5  # 每秒增加的进度
var next_special_enemy_type = "elite"  # 下一个特殊敌人类型："elite" 或 "boss"
var special_enemy_spawned_recently = false  # 是否最近生成了特殊敌人
var special_enemy_cooldown = 30.0  # 特殊敌人生成后的冷却时间（秒）
var special_enemy_cooldown_timer = 0.0

# 信号
signal special_enemy_spawned(enemy_type)
signal game_over

# 经验系统
var experience_manager = null
var experience_orb_manager = null

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

# 遗物管理器已预加载在文件头部

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

# 语言管理器引用
var language_manager = null

# Called when the node enters the scene tree for the first time
func _ready():
	# 获取语言管理器
	language_manager = get_node_or_null("/root/LanguageManager")
	if not language_manager:
		# 如果找不到语言管理器，尝试从自动加载脚本获取
		var autoload = get_node_or_null("/root/LanguageAutoload")
		if autoload and autoload.language_manager:
			language_manager = autoload.language_manager
		else:
			# 如果还是找不到，创建一个新的语言管理器
			language_manager = load("res://scripts/language/language_manager.gd").new()
			language_manager.name = "LanguageManager"
			get_tree().root.call_deferred("add_child", language_manager)

# 连接语言变更信号
	if language_manager:
		language_manager.language_changed.connect(_on_language_changed)

	# 初始化经验系统
	experience_manager = ExperienceManager.new(self)
	experience_manager.name = "ExperienceManager"
	add_child(experience_manager)

	experience_orb_manager = ExperienceOrbManager.new(self, experience_manager)
	experience_orb_manager.name = "ExperienceOrbManager"
	add_child(experience_orb_manager)

	# 连接经验系统信号
	experience_manager.level_up.connect(_on_experience_level_up)

	# 初始化经验系统调试面板
	var debug_panel = load("res://scenes/ui/experience_debug_panel.tscn").instantiate()
	debug_panel.name = "ExperienceDebugPanel"
	$UI.add_child(debug_panel)
	debug_panel.set_experience_manager(experience_manager)
	debug_panel.set_experience_orb_manager(experience_orb_manager)

	# Initialize UI
	experience_bar.min_value = 0
	experience_bar.max_value = experience_manager.experience_to_level
	experience_bar.value = 0
	experience_bar.show_percentage = true

	# 初始化经验条

	# Connect signals
	$UI/GameOverScreen/RestartButton.pressed.connect(_on_restart_button_pressed)
	$UI/PauseScreen/ResumeButton.pressed.connect(_on_resume_button_pressed)
	$UI/PauseScreen/QuitButton.pressed.connect(_on_quit_button_pressed)
	$UI/PauseScreen/ConsoleButton.pressed.connect(_on_console_button_pressed)
	$UI/GameOverScreen/AchievementsButton.pressed.connect(_on_achievements_button_pressed)
	$UI/AchievementsScreen/BackButton.pressed.connect(_on_achievements_back_button_pressed)
	$UI/GameOverScreen/HomeButton.pressed.connect(_on_home_button_pressed)

	# 连接首页按钮信号
	var buttons_container = $UI/StartScreen/ButtonsContainer
	if buttons_container:
		var start_button = buttons_container.get_node("StartButton")
		if start_button:
			start_button.pressed.connect(_on_start_button_pressed)

		var achievements_button = buttons_container.get_node("AchievementsButton")
		if achievements_button:
			achievements_button.pressed.connect(_on_achievements_button_pressed)

		var settings_button = buttons_container.get_node("SettingsButton")
		if settings_button:
			settings_button.pressed.connect(_on_settings_button_pressed)

	# 更新UI文本
	update_ui_text()

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
			enemy_spawner.enemy_died.connect(_on_enemy_died)

		# 连接特殊敌人生成信号
		if has_signal("special_enemy_spawned"):
			special_enemy_spawned.connect(_on_special_enemy_spawned)

	# Initialize achievement manager
	achievement_manager = SimpleAchievementSystem.new()
	achievement_manager.name = "AchievementManager"
	add_child(achievement_manager)

	# Connect achievement unlocked signal
	achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)

	# Load achievements from file
	achievement_manager.load_achievements_from_file()

	# Initialize relic manager
	relic_manager = RelicManager.new()
	relic_manager.name = "RelicManager"
	add_child(relic_manager)

	# Initialize effect manager
	var effect_manager = Node.new()
	effect_manager.set_script(load("res://scripts/utils/effect_manager.gd"))
	effect_manager.name = "EffectManager"
	add_child(effect_manager)

	# Load selected relics from global
	load_selected_relics()

	# 初始化特殊敌人进度条
	update_special_enemy_icon()
	update_special_enemy_progress_bar()

	# 初始化音频系统
	init_audio_system()

	# 初始化性能监控器
	performance_monitor = PerformanceMonitor.new()
	performance_monitor.name = "PerformanceMonitor"
	add_child(performance_monitor)

	# 设置性能监控器参数
	performance_monitor.debug_mode = false  # 在生产环境中关闭调试模式
	performance_monitor.target_fps = 60
	performance_monitor.min_acceptable_fps = 30

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

		# 更新精英/Boss进度条
		if special_enemy_spawned_recently:
			# 如果最近生成了特殊敌人，则进入冷却时间
			special_enemy_cooldown_timer += delta
			if special_enemy_cooldown_timer >= special_enemy_cooldown:
				special_enemy_spawned_recently = false
				special_enemy_cooldown_timer = 0.0
				special_enemy_progress = 0.0
				# 切换下一个特殊敌人类型
				if next_special_enemy_type == "elite":
					next_special_enemy_type = "boss"
				else:
					next_special_enemy_type = "elite"
				# 更新进度条图标颜色
				update_special_enemy_icon()
		else:
			# 如果没有最近生成特殊敌人，则增加进度
			special_enemy_progress += special_enemy_progress_rate * delta
			if special_enemy_progress >= special_enemy_progress_max:
				# 生成特殊敌人
				spawn_special_enemy()
				special_enemy_spawned_recently = true
				special_enemy_progress = special_enemy_progress_max

		# 更新进度条UI
		update_special_enemy_progress_bar()

		# Handle regeneration from Golden Apple relic
		if player and relic_manager and relic_manager.has_relic("golden_apple"):
			regeneration_timer += delta
			var relic = relic_manager.get_relic("golden_apple")
			if regeneration_timer >= relic.interval:
				regeneration_timer = 0
				player.heal(relic.value)

# 生成特殊敌人（精英或Boss）
func spawn_special_enemy():
	# 使用enemy_spawner的spawn_special_enemy函数
	var enemy = enemy_spawner.spawn_special_enemy(next_special_enemy_type)

	# 检查敌人是否有效
	if enemy == null:
		return

	# 添加到场景
	get_tree().current_scene.add_child(enemy)

	# 显示特殊敌人生成消息
	var message = "精英敌人出现了！"
	if next_special_enemy_type == "boss":
		message = "Boss出现了！"
	show_difficulty_message(message)

# 更新特殊敌人进度条
func update_special_enemy_progress_bar():
	# 获取进度条
	var progress_bar = $UI/GameUI/SpecialEnemyProgressContainer/SpecialEnemyProgress
	if progress_bar:
		# 设置进度条值
		progress_bar.max_value = special_enemy_progress_max
		progress_bar.value = special_enemy_progress

		# 更新敌人图标位置
		var enemy_icon = progress_bar.get_node("EnemyIcon")
		if enemy_icon:
			# 计算图标位置，使其根据进度移动
			var progress_ratio = special_enemy_progress / special_enemy_progress_max
			# 获取进度条宽度
			var bar_width = progress_bar.size.x
			if bar_width <= 0:
				bar_width = 180  # 默认宽度
			# 计算图标位置，确保它不会超出进度条范围
			var icon_width = 20  # 图标宽度
			var icon_position = progress_ratio * bar_width - (icon_width / 2)
			# 限制图标位置在进度条范围内
			icon_position = clamp(icon_position, -icon_width, bar_width)
			enemy_icon.position.x = icon_position

		# 确保进度条标签显示正确的文本
		var label = $UI/GameUI/SpecialEnemyProgressContainer/Label
		if label:
			var Tr = load("res://scripts/language/tr.gd")
			if next_special_enemy_type == "elite":
				label.text = Tr.get_tr("next_elite_enemy", "下一个精英敌人")
			else:
				label.text = Tr.get_tr("next_boss_enemy", "下一个Boss敌人")

# 更新特殊敌人图标
func update_special_enemy_icon():
	# 获取敌人图标
	var enemy_icon = $UI/GameUI/SpecialEnemyProgressContainer/SpecialEnemyProgress/EnemyIcon
	if enemy_icon:
		# 根据下一个特殊敌人类型设置颜色
		if next_special_enemy_type == "elite":
			enemy_icon.color = Color(0.8, 0.8, 0.2, 1.0)  # 黄色表示精英
		else:
			enemy_icon.color = Color(0.8, 0.2, 0.2, 1.0)  # 红色表示Boss

# 处理特殊敌人生成信号
func _on_special_enemy_spawned(enemy_type):
	# 更新统计信息
	if achievement_manager:
		if enemy_type == "elite":
			achievement_manager.update_statistic("elite_enemies_killed", 1, true)
		else:
			achievement_manager.update_statistic("boss_enemies_killed", 1, true)

	# 播放特殊敌人音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		if enemy_type == "elite":
			# 播放精英敌人出现音效
			audio_manager.play_sfx(AudioManager.SfxType.BOSS_ATTACK)
		else:
			# 播放Boss敌人出现音效
			audio_manager.play_sfx(AudioManager.SfxType.BOSS_ATTACK)
			# 切换到Boss音乐
			audio_manager.play_music(AudioManager.MusicType.BOSS)

# 初始化音频系统
func init_audio_system():
	# 获取音频管理器
	var audio_manager = get_node_or_null("/root/AudioManager")
	if not audio_manager:
		print("Warning: AudioManager not found")
		return

	# 连接游戏状态变化信号
	game_over.connect(_on_game_over)

	# 初始化音频设置面板
	var audio_settings_panel = load("res://scenes/ui/audio_settings_panel.tscn").instantiate()
	audio_settings_panel.name = "AudioSettingsPanel"
	audio_settings_panel.hide()
	# 设置为最高层级
	audio_settings_panel.z_index = 100
	# 连接关闭信号
	audio_settings_panel.settings_closed.connect(_on_audio_settings_closed)
	$UI.add_child(audio_settings_panel)

	# 连接控制台关闭信号
	var console_panel = $UI/ConsolePanel
	if console_panel:
		console_panel.console_closed.connect(_on_console_closed)

	# 初始化暂停菜单
	var pause_menu = load("res://scenes/ui/pause_menu.tscn").instantiate()
	pause_menu.name = "PauseMenu"
	pause_menu.hide()
	pause_menu.resume_game.connect(_on_resume_game)
	pause_menu.quit_game.connect(_on_quit_game)
	pause_menu.show_settings.connect(_on_show_settings)
	pause_menu.show_console.connect(_on_show_console)
	pause_menu.show_achievements.connect(_on_show_achievements)
	pause_menu.return_to_home.connect(_on_return_to_home)
	$UI.add_child(pause_menu)

	# 播放菜单音乐
	audio_manager.play_music(AudioManager.MusicType.MENU)

# 游戏结束回调
func _on_game_over():
	# 播放游戏结束音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		# 播放游戏结束音效
		audio_manager.play_sfx(AudioManager.SfxType.PLAYER_DEATH)
		# 切换到游戏结束音乐
		audio_manager.play_music(AudioManager.MusicType.GAME_OVER)

# 暂停游戏
func pause_game():
	if not game_running:
		return

	# 暂停游戏
	get_tree().paused = true

	# 显示暂停菜单
	var pause_menu = $UI/PauseMenu
	if pause_menu:
		pause_menu.show_menu()

	# 暂停音乐
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.pause_music()

# 恢复游戏
func resume_game():
	# 恢复游戏
	get_tree().paused = false

	# 隐藏暂停菜单
	var pause_menu = $UI/PauseMenu
	if pause_menu:
		pause_menu.hide_menu()

	# 隐藏设置面板
	var audio_settings_panel = $UI/AudioSettingsPanel
	if audio_settings_panel:
		audio_settings_panel.hide()

	# 恢复音乐
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.resume_music()

# 暂停菜单恢复游戏回调
func _on_resume_game():
	resume_game()

# 暂停菜单退出游戏回调
func _on_quit_game():
	# 退出游戏
	get_tree().quit()

# 暂停菜单显示设置回调
func _on_show_settings():
	# 使用UIManager打开设置页面
	UIManager.open_page(UIManager.PageType.AUDIO_SETTINGS)

# 音频设置面板关闭回调
func _on_audio_settings_closed():
	# 使用UIManager处理页面导航，不需要手动处理
	pass

# 控制台关闭回调
func _on_console_closed():
	# 使用UIManager处理页面导航，不需要手动处理
	pass

# 暂停菜单显示控制台回调
func _on_show_console():
	# 使用UIManager打开控制台页面
	UIManager.open_page(UIManager.PageType.CONSOLE)

# 暂停菜单显示成就回调
func _on_show_achievements():
	# 使用UIManager打开成就页面
	UIManager.open_page(UIManager.PageType.ACHIEVEMENTS)

# 暂停菜单返回主页回调
func _on_return_to_home():
	# 恢复游戏
	resume_game()

	# 重置游戏状态
	game_running = false
	enemies_defeated = 0

	# 清除现有敌人
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

	# 清除现有经验球
	for orb in get_tree().get_nodes_in_group("experience"):
		orb.queue_free()

	# 清除现有玩家
	if player != null and is_instance_valid(player):
		player.queue_free()

	# 显示开始屏幕
	show_start_screen()

# Start or restart the game
func start_game():
	# Reset game state
	game_time = 0
	game_running = true
	enemy_spawn_timer = 0
	enemy_spawn_interval = 1.0
	difficulty_increase_timer = 0
	regeneration_timer = 0

	# 重置特殊敌人进度条
	special_enemy_progress = 0.0
	special_enemy_spawned_recently = false
	special_enemy_cooldown_timer = 0.0
	next_special_enemy_type = "elite"

	# 在下一帧更新图标和进度条，确保 UI 已经准备好
	await get_tree().process_frame
	update_special_enemy_icon()
	update_special_enemy_progress_bar()

	# 播放游戏音乐
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_music(AudioManager.MusicType.GAMEPLAY)

	# 显示游戏开始提示
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		# 获取翻译文本
		var game_start_message = language_manager.get_translation("game_start_message", "Game started! Good luck!")

		# 显示游戏开始提示
		ui_manager.show_toast(game_start_message, 3.0)

		# 显示控制提示
		var controls_message = language_manager.get_translation("controls_message", "Use WASD to move, mouse to aim")
		await get_tree().create_timer(1.0).timeout
		ui_manager.show_toast(controls_message, 3.0)

	# 重置经验系统
	experience_manager.reset()
	experience_orb_manager.clear_all_orbs()

	# Reset achievement statistics
	if achievement_manager:
		achievement_manager.reset_game_statistics()

	# Reset UI
	health_bar.value = 100
	level_label.text = "Level: %d" % experience_manager.current_level
	game_over_screen.visible = false
	level_up_screen.visible = false

	# 直接更新经验条，不使用函数
	experience_bar.min_value = 0
	experience_bar.max_value = experience_manager.experience_to_level
	experience_bar.value = experience_manager.current_experience
	experience_bar.show_percentage = true

	# 设置经验条样式
	var font_color = Color(1, 1, 1, 1)
	experience_bar.add_theme_color_override("font_color", font_color)
	experience_bar.add_theme_font_size_override("font_size", 16)

	# 设置百分比可见性
	experience_bar.set("theme_override_constants/font_outline_size", 1)
	experience_bar.set("percent_visible", true)

	# 计算并设置自定义文本
	var percent = 0
	if experience_bar.max_value > 0:
		percent = int((experience_bar.value / experience_bar.max_value) * 100)
	experience_bar.set("text", str(percent) + "%")

	# 强制更新经验条外观
	experience_bar.queue_redraw()

	# 更新经验条

	# 强制更新经验条文本
	experience_bar.tooltip_text = str(int(experience_manager.current_experience)) + " / " + str(int(experience_manager.experience_to_level))

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
			experience_manager.set_level(experience_manager.current_level + 1)

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
func add_experience(amount, source = "default"):
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

	# 使用经验管理器添加经验
	var final_amount = experience_manager.add_experience(amount, source)

	# 直接更新经验条，不使用函数
	experience_bar.min_value = 0
	experience_bar.max_value = experience_manager.experience_to_level
	experience_bar.value = experience_manager.current_experience
	experience_bar.show_percentage = true

	# 设置经验条样式
	var font_color = Color(1, 1, 1, 1)
	experience_bar.add_theme_color_override("font_color", font_color)
	experience_bar.add_theme_font_size_override("font_size", 16)

	# 设置百分比可见性
	experience_bar.set("theme_override_constants/font_outline_size", 1)
	experience_bar.set("percent_visible", true)

	# 计算并设置自定义文本
	var percent = 0
	if experience_bar.max_value > 0:
		percent = int((experience_bar.value / experience_bar.max_value) * 100)
	experience_bar.set("text", str(percent) + "%")

	# 强制更新经验条外观
	experience_bar.queue_redraw()

	# 更新经验条显示

	# 强制更新经验条文本
	experience_bar.tooltip_text = str(int(experience_manager.current_experience)) + " / " + str(int(experience_manager.experience_to_level))

	# Update achievement statistics
	if achievement_manager:
		achievement_manager.increment_statistic("experience_collected", final_amount)

	return final_amount

# 经验系统升级回调
func _on_experience_level_up(new_level, overflow_exp):
	# 更新等级标签
	level_label.text = "Level: %d" % new_level

	# 直接更新经验条，不使用函数
	experience_bar.min_value = 0
	experience_bar.max_value = experience_manager.experience_to_level
	experience_bar.value = experience_manager.current_experience
	experience_bar.show_percentage = true

	# 设置经验条样式
	var font_color = Color(1, 1, 1, 1)
	experience_bar.add_theme_color_override("font_color", font_color)
	experience_bar.add_theme_font_size_override("font_size", 16)

	# 设置百分比可见性
	experience_bar.set("theme_override_constants/font_outline_size", 1)
	experience_bar.set("percent_visible", true)

	# 计算并设置自定义文本
	var percent = 0
	if experience_bar.max_value > 0:
		percent = int((experience_bar.value / experience_bar.max_value) * 100)
	experience_bar.set("text", str(percent) + "%")

	# 强制更新经验条外观
	experience_bar.queue_redraw()

	# 升级后更新经验条显示

	# 强制更新经验条文本
	experience_bar.tooltip_text = str(int(experience_manager.current_experience)) + " / " + str(int(experience_manager.experience_to_level))

	# 触发升级事件，应用遗物效果
	if relic_manager:
		var event_data = {
			"player": player,
			"level": new_level,
			"experience_to_level": experience_manager.experience_to_level
		}

		# 触发升级事件
		var modified_data = relic_manager.trigger_event(1, event_data)  # 1 = LEVEL_UP

		# 获取修改后的数据
		if modified_data.has("experience_to_level"):
			experience_manager.update_config({"base_exp_to_level": modified_data["experience_to_level"]})
			experience_bar.max_value = experience_manager.experience_to_level

	# Update achievement statistics
	if achievement_manager:
		achievement_manager.update_statistic("player_level", new_level)
		achievement_manager.increment_statistic("levels_gained")

	# 记录控制台状态
	var console_panel = $UI/ConsolePanel
	var console_was_visible = console_panel and console_panel.visible

	# Show level up screen
	show_level_up_screen(false)

	# 使用UI管理器显示升级提示
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		# 获取翻译文本
		var level_up_message = language_manager.get_translation("level_up_message", "Level Up! You are now level %d")
		level_up_message = level_up_message % new_level

		# 显示升级提示
		ui_manager.show_toast(level_up_message, 3.0)

		# 播放升级音效
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager:
			audio_manager.play_sfx(AudioManager.SfxType.LEVEL_UP)

# 更新经验条
func update_experience_bar():
	# 设置经验条的最大值和当前值
	experience_bar.min_value = 0
	experience_bar.max_value = experience_manager.experience_to_level
	experience_bar.value = experience_manager.current_experience

	# 确保经验条显示百分比
	experience_bar.show_percentage = true

	# 强制更新经验条外观
	experience_bar.queue_redraw()

	# 更新经验条显示

# Level up the player (for backward compatibility and console commands)
func level_up(from_console = false):
	# 使用经验管理器升级
	if from_console:
		# 如果是从控制台调用，直接添加足够的经验升级
		var needed_exp = experience_manager.experience_to_level - experience_manager.current_experience
		if needed_exp > 0:
			experience_manager.add_experience(needed_exp, "console")
		else:
			# 如果已经有足够的经验，手动触发升级检查
			experience_manager.check_level_up()

# Show the level up screen with upgrade options
func show_level_up_screen(from_console = false):
	# 记录控制台状态
	var console_panel = $UI/ConsolePanel
	var console_was_visible = console_panel and console_panel.visible

	# 如果控制台可见，隐藏它
	if console_was_visible:
		console_panel.visible = false

	# Pause the game
	get_tree().paused = true

	# Clear previous upgrade options
	for child in upgrade_options.get_children():
		child.queue_free()

	# 重置重新随机计数器
	option_rerolls.clear()

	# 生成升级选项基础池
	var base_options = [
		{
			"type": "max_health",
			"name": language_manager.get_translation("player_upgrade_max_health", "Max Health +20").format({"0": "20"}),
			"description": language_manager.get_translation("player_upgrade_max_health_desc", "Increase maximum health by 20").format({"0": "20"}),
			"amount": 20
		},
		{
			"type": "move_speed",
			"name": language_manager.get_translation("player_upgrade_move_speed", "Move Speed +20").format({"0": "20"}),
			"description": language_manager.get_translation("player_upgrade_move_speed_desc", "Increase movement speed by 20").format({"0": "20"}),
			"amount": 20
		},
		{
			"type": "weapon_damage",
			"name": language_manager.get_translation("player_upgrade_weapon_damage", "Weapon Damage +20%").format({"0": "20"}),
			"description": language_manager.get_translation("player_upgrade_weapon_damage_desc", "Increase all weapon damage by 20%").format({"0": "20"}),
			"amount": 0.2
		}
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
				"gun":
					weapon_scene = gun_scene
				"knife":
					weapon_scene = knife_scene
				"shield":
					weapon_scene = shield_scene
				"lightning":
					weapon_scene = lightning_scene
				"orbital_satellite":
					weapon_scene = orbital_satellite_scene
				"black_hole_bomb":
					weapon_scene = black_hole_bomb_scene
				"toxic_spray":
					weapon_scene = toxic_spray_scene
				"frost_staff":
					weapon_scene = frost_staff_scene
				"boomerang":
					weapon_scene = boomerang_scene

			# 使用语言管理器获取武器名称和描述
			if language_manager:
				weapon_name = language_manager.get_translation("weapon_" + weapon_id + "_name", weapon_id.capitalize())
				weapon_description = language_manager.get_translation("weapon_" + weapon_id + "_desc", "A weapon that damages enemies")
			else:
				# 如果没有语言管理器，使用默认名称
				weapon_name = weapon_id.capitalize()
				weapon_description = "A weapon that damages enemies"

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
		var reroll_text = "Reroll"
		if language_manager:
			reroll_text = language_manager.get_translation("reroll", "Reroll")
		reroll_button.text = reroll_text + " (0/" + str(max_rerolls) + ")"
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
				# 调试输出
				print("Applying weapon_damage upgrade with amount: ", upgrade_amount)

				for weapon_id in weapon_manager.equipped_weapons:
					var weapon = weapon_manager.get_weapon(weapon_id)
					if weapon:
						# 调试输出
						print("Upgrading weapon: ", weapon_id)

						# 检查武器是否有 damage 属性
						if "damage" in weapon:
							var old_damage = weapon.damage
							weapon.damage = int(weapon.damage * (1 + upgrade_amount))
							print("  - ", weapon_id, " damage: ", old_damage, " -> ", weapon.damage)
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
				var weapon_id = ""
				if "weapon_id" in target_weapon:
					weapon_id = target_weapon.weapon_id
				else:
					weapon_id = target_weapon.name.to_lower()

				# 调试输出
				print("Upgrading weapon: ", weapon_id, " with upgrade type: ", weapon_upgrade_type)

				# 升级武器
				weapon_manager.upgrade_weapon(weapon_id, weapon_upgrade_type)

	# Hide level up screen
	level_up_screen.visible = false

	# 检查是否需要恢复游戏
	var console_panel = $UI/ConsolePanel
	if console_panel and console_panel.visible:
		# 如果控制台可见，保持暂停状态
		get_tree().paused = true
	else:
		# 如果控制台不可见，恢复游戏
		get_tree().paused = false

# 重新随机升级选项
func reroll_option(option_index, reroll_button):
	# 检查是否还有重新随机次数
	if option_rerolls[option_index] >= max_rerolls:
		return

	# 增加重新随机计数器
	option_rerolls[option_index] += 1

	# 更新重新随机按钮文本
	var reroll_text = "Reroll"
	if language_manager:
		reroll_text = language_manager.get_translation("reroll", "Reroll")
	reroll_button.text = reroll_text + " (" + str(option_rerolls[option_index]) + "/" + str(max_rerolls) + ")"

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

	# 添加遗物选择场景

# Toggle pause state
func toggle_pause():
	# 使用新的暂停系统
	if get_tree().paused:
		resume_game()
	else:
		pause_game()

# Resume button pressed
func _on_resume_button_pressed():
	toggle_pause()

# Console button pressed
func _on_console_button_pressed():
	# 隐藏暂停菜单
	pause_screen.visible = false

	# 显示控制台并让其获取焦点
	$UI/ConsolePanel.visible = true
	$UI/ConsolePanel.input_field.grab_focus()

	# 保持游戏暂停状态
	get_tree().paused = true

# Quit button pressed
func _on_quit_button_pressed():
	# Hide pause screen
	pause_screen.visible = false

	# Show start screen
	show_start_screen()

# Handle game over
func handle_game_over():
	game_running = false

	# Save achievements
	if achievement_manager:
		achievement_manager.save_achievements_to_file()

	# 使用UI管理器显示游戏结束通知
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		# 获取翻译文本
		var game_over_title = language_manager.get_translation("game_over_title", "Game Over")
		var game_over_message = language_manager.get_translation("game_over_message", "You survived for %s and defeated %d enemies.")

		# 格式化消息
		var time_str = "%02d:%02d" % [int(game_time / 60), int(game_time) % 60]
		game_over_message = game_over_message % [time_str, enemies_defeated]

		# 显示游戏结束通知
		ui_manager.show_notification(game_over_title, game_over_message, "error", 10.0)

	# Update game over stats
	# 使用多语言系统获取翻译文本
	var time_survived_text = language_manager.get_translation("time_survived", "Time Survived")
	var level_reached_text = language_manager.get_translation("level_reached", "Level Reached")
	var enemies_defeated_text = language_manager.get_translation("enemies_defeated", "Enemies Defeated")

	var stats_text = time_survived_text + ": %02d:%02d\n" % [int(game_time / 60), int(game_time) % 60]
	stats_text += level_reached_text + ": %d\n" % experience_manager.current_level
	stats_text += enemies_defeated_text + ": %d\n\n" % enemies_defeated

	# Add achievement statistics if available
	if achievement_manager:
		var achievements_unlocked_text = language_manager.get_translation("achievements_unlocked", "Achievements Unlocked")
		stats_text += achievements_unlocked_text + ": %d/%d\n" % [
			achievement_manager.get_unlocked_achievements_count(),
			achievement_manager.get_total_achievements_count()
		]

		# Add recently unlocked achievements
		var unlocked_achievements = []
		for achievement_id in achievement_manager.achievements:
			var achievement = achievement_manager.achievements[achievement_id]
			if achievement.unlocked:
				unlocked_achievements.append(achievement)

		if unlocked_achievements.size() > 0:
			var recent_achievements_text = language_manager.get_translation("recent_achievements", "Recent Achievements")
			stats_text += "\n" + recent_achievements_text + ":\n"
			for i in range(min(3, unlocked_achievements.size())):
				var achievement = unlocked_achievements[i]
				# 获取成就的翻译名称
				var achievement_name = achievement.name
				if achievement.id and not achievement.id.is_empty():
					# 打印调试信息
					print("Looking for translation key: achievement_" + achievement.id + "_name")

					# 尝试获取翻译
					var translated_name = language_manager.get_translation("achievement_" + achievement.id + "_name", "")
					if not translated_name.is_empty():
						achievement_name = translated_name
					else:
						# 如果没有翻译，使用标题
						if "title" in achievement:
							achievement_name = achievement.title
				stats_text += achievement.icon + " " + achievement_name + "\n"

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

	# 直接使用上一局的遗物，无需重新选择
	# 遗物已经通过 RelicGlobal 保存，并在 start_game() 中加载

	# Start the game
	start_game()

	# Resume the game
	get_tree().paused = false

# Achievements button pressed
func _on_achievements_button_pressed():
	# 加载成就页面场景（如果不存在）
	var achievement_screen = null

	if has_node("UI/AchievementScreen"):
		achievement_screen = get_node("UI/AchievementScreen")
	else:
		# 动态加载成就页面
		var achievement_screen_path = "res://scenes/ui/achievement_screen.tscn"
		var achievement_screen_scene = load(achievement_screen_path)
		achievement_screen = achievement_screen_scene.instantiate()
		$UI.add_child(achievement_screen)

		# 连接返回按钮信号
		achievement_screen.back_pressed.connect(_on_achievements_back_button_pressed)

	# 初始化成屑页面
	if achievement_screen:
		achievement_screen.initialize(achievement_manager, language_manager)

		# 使用UIManager打开成就页面
		UIManager.open_page(UIManager.PageType.ACHIEVEMENTS)

# Achievements back button pressed
func _on_achievements_back_button_pressed():
	# 使用UIManager返回上一页
	# 不需要手动处理，因为成就页面已经在自己的脚本中调用了UIManager.go_back()
	pass

# Achievement unlocked handler
func _on_achievement_unlocked(achievement_id, achievement_name, achievement_description):
	# Play achievement sound
	if has_node("AudioManager"):
		get_node("AudioManager").play_sound("achievement_unlocked")

	# Show notification
	achievement_manager.show_achievement_notification(achievement_id)

	# Print achievement info
	print("Achievement unlocked: " + achievement_name + " - " + achievement_description)

# Home button pressed
func _on_home_button_pressed():
	# Hide game over screen
	game_over_screen.visible = false

	# Reset game state
	game_running = false
	enemies_defeated = 0

	# Clear existing enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

	# Clear existing experience orbs
	for orb in get_tree().get_nodes_in_group("experience"):
		orb.queue_free()

	# Clear existing player
	if player != null and is_instance_valid(player):
		player.queue_free()

	# Show start screen
	show_start_screen()

	# Resume the game (for the start screen)
	get_tree().paused = false

# Spawn an experience orb at the given position
func spawn_experience_orb(position, value, source = "enemy"):
	# 使用经验球管理器生成经验球
	return experience_orb_manager.spawn_experience_orb(position, value, source)

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
		var modified_data = relic_manager.trigger_event(AbstractRelic.EventType.PLAYER_DEATH, event_data)

		# 检查是否防止死亡
		if modified_data.has("prevent_death") and modified_data["prevent_death"]:
			# 恢复生命值
			var heal_amount = player.max_health * modified_data["heal_percent"]
			player.current_health = heal_amount
			health_bar.value = player.current_health
			return

	# 如果没有防止死亡，则游戏结束
	handle_game_over()

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
	# 使用UI管理器显示通知
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		# 使用通知组件显示难度增加消息
		ui_manager.show_notification(
			language_manager.get_translation("difficulty_increased", "Difficulty Increased"),
			message,
			"warning",
			5.0
		)
	else:
		# 如果UI管理器不可用，使用旧方法
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

		# 更新遗物显示
		update_relics_display()

		# Debug output
		# print("Equipped relics: ", relic_manager.get_equipped_relics_info())

# 更新遗物显示
func update_relics_display():
	# 获取遗物列表标签
	var relics_list = $UI/GameUI/RelicsPanel/VBoxContainer/RelicsList

	# 检查是否有遗物管理器
	if not relic_manager:
		return

	# 获取已装备遗物信息
	var equipped_relics = relic_manager.equipped_relics

	# 如果没有遗物，显示“无”
	if equipped_relics.size() == 0:
		if language_manager:
			relics_list.text = language_manager.get_translation("none", "无")
		else:
			relics_list.text = "无"
		return

	# 构建遗物显示文本
	var text = ""
	for relic_id in equipped_relics:
		# 加载遗物工具类
		var RelicUtils = load("res://scripts/utils/relic_utils.gd")
		# 使用遗物工具类获取图标
		var icon = RelicUtils.get_relic_icon(relic_id)

		# 使用多语言系统获取遗物名称
		var language_manager = get_node_or_null("/root/LanguageManager")
		var display_name = relic_id

		if language_manager:
			# 使用语言管理器获取翻译
			display_name = language_manager.get_translation("relic_" + relic_id + "_name", "")

		# 如果没有翻译，使用格式化的名称
		if display_name.is_empty():
			display_name = RelicUtils.format_relic_name(relic_id)

		text += icon + " " + display_name + "\n"

	# 设置文本
	relics_list.text = text

# 更新UI文本
func update_ui_text():
	if not language_manager:
		return

	# 更新首页文本
	$UI/StartScreen/TitleLabel.text = language_manager.get_translation("game_title", "Vampire Survivors Clone")
	$UI/StartScreen/ControlsLabel.text = language_manager.get_translation("controls_info", "Controls:\nWASD or Arrow Keys to move\nSurvive as long as possible!\nCollect experience orbs to level up")

	# 更新首页按钮文本
	var buttons_container = $UI/StartScreen/ButtonsContainer
	if buttons_container:
		var start_button = buttons_container.get_node("StartButton")
		if start_button:
			start_button.text = language_manager.get_translation("start_game", "开始游戏")

		var achievements_button = buttons_container.get_node("AchievementsButton")
		if achievements_button:
			achievements_button.text = language_manager.get_translation("achievements", "成就")

		var settings_button = buttons_container.get_node("SettingsButton")
		if settings_button:
			settings_button.text = language_manager.get_translation("settings", "设置")

	# 更新游戏结束界面文本
	$UI/GameOverScreen/GameOverLabel.text = language_manager.get_translation("game_over", "Game Over")
	$UI/GameOverScreen/RestartButton.text = language_manager.get_translation("retry", "Restart")
	$UI/GameOverScreen/AchievementsButton.text = language_manager.get_translation("achievements", "Achievements")
	$UI/GameOverScreen/HomeButton.text = language_manager.get_translation("main_menu", "Main Menu")

	# 更新暂停界面文本
	$UI/PauseScreen/PauseLabel.text = language_manager.get_translation("pause", "Pause")
	$UI/PauseScreen/ResumeButton.text = language_manager.get_translation("resume", "Resume")
	$UI/PauseScreen/QuitButton.text = language_manager.get_translation("quit", "Quit")
	$UI/PauseScreen/ConsoleButton.text = language_manager.get_translation("console", "Console")

	# 更新控制台界面文本
	$UI/ConsolePanel/VBoxContainer/HeaderLabel.text = language_manager.get_translation("console", "Console")

	# 更新遗物面板标题
	$UI/GameUI/RelicsPanel/VBoxContainer/TitleLabel.text = language_manager.get_translation("relics", "遗物")

	# 更新升级界面文本
	$UI/LevelUpScreen/LevelUpLabel.text = language_manager.get_translation("level_up", "Level Up!")

	# 更新成就界面文本
	$UI/AchievementsScreen/AchievementsLabel.text = language_manager.get_translation("achievements", "Achievements")
	$UI/AchievementsScreen/ScrollContainer/AchievementsList.text = language_manager.get_translation("loading_achievements", "Loading achievements...")
	$UI/AchievementsScreen/BackButton.text = language_manager.get_translation("back", "Back")

	# 更新遗物显示
	update_relics_display()

# 处理语言变更
func _on_language_changed(new_language):
	update_ui_text()

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

		# 我们可以在这里添加特定敌人类型的统计，但需要从敌人对象中获取类型
		# 由于当前上下文中没有敌人类型信息，暂时注释掉这部分代码
		# 如果需要跟踪特定敌人类型的击杀数，应该在敌人死亡时传递敌人类型
		# 例如：
		# if enemy and enemy.has("enemy_type"):
		#     var enemy_type_stat = "enemies_defeated_" + enemy.enemy_type
		#     achievement_manager.increment_statistic(enemy_type_stat)

	# Spawn experience orb
	spawn_experience_orb(position, experience)

	# 使用UI组件池显示得分
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		# 创建得分消息
		var score_message = "+" + str(experience) + " XP"

		# 在敌人死亡位置显示得分
		# 将世界坐标转换为屏幕坐标
		var camera = get_viewport().get_camera_2d()
		# 在 Godot 4.4.1 中，使用乘法运算符而不是 xform 方法
		var screen_position = get_viewport().get_canvas_transform() * position

		# 显示得分消息
		ui_manager.show_toast(score_message, 1.0, screen_position)

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
			# Save achievements before freeing
			achievement_manager.save_achievements_to_file()
			achievement_manager.queue_free()
			achievement_manager = null

		# 退出游戏
		get_tree().quit()

# 获取语言管理器函数，供其他脚本调用
func get_language_manager():
	return language_manager

# 设置按钮点击回调
func _on_settings_button_pressed():
	# 播放UI点击音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

	# 使用UIManager打开音频设置面板
	UIManager.open_page(UIManager.PageType.AUDIO_SETTINGS)
