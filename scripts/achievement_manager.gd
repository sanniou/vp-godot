extends Node

# Achievement definitions
var achievements = {
	"first_blood": {
		"title": "First Blood",
		"description": "Defeat your first enemy",
		"icon": "🩸",
		"requirement": 1,
		"type": "enemies_defeated",
		"unlocked": false
	},
	"monster_hunter": {
		"title": "Monster Hunter",
		"description": "Defeat 50 enemies",
		"icon": "🔪",
		"requirement": 50,
		"type": "enemies_defeated",
		"unlocked": false
	},
	"exterminator": {
		"title": "Exterminator",
		"description": "Defeat 100 enemies",
		"icon": "💀",
		"requirement": 100,
		"type": "enemies_defeated",
		"unlocked": false
	},
	"level_up": {
		"title": "Level Up!",
		"description": "Reach level 5",
		"icon": "⬆️",
		"requirement": 5,
		"type": "player_level",
		"unlocked": false
	},
	"master": {
		"title": "Master",
		"description": "Reach level 10",
		"icon": "🌟",
		"requirement": 10,
		"type": "player_level",
		"unlocked": false
	},
	"survivor": {
		"title": "Survivor",
		"description": "Survive for 5 minutes",
		"icon": "⏱️",
		"requirement": 5 * 60,
		"type": "time_survived",
		"unlocked": false
	},
	"endurance": {
		"title": "Endurance",
		"description": "Survive for 10 minutes",
		"icon": "⏳",
		"requirement": 10 * 60,
		"type": "time_survived",
		"unlocked": false
	},
	"marathon": {
		"title": "Marathon",
		"description": "Survive for 20 minutes",
		"icon": "🏆",
		"requirement": 20 * 60,
		"type": "time_survived",
		"unlocked": false
	}
}

# Statistics
var statistics = {
	"enemies_defeated": 0,
	"player_level": 1,
	"time_survived": 0,
	"experience_collected": 0,
	"damage_dealt": 0,
	"damage_taken": 0,
	"levels_gained": 0,
	"games_played": 0,
	"highest_level": 1,
	"longest_survival_time": 0
}

# Check for achievement unlocks
func check_achievements():
	for achievement_id in achievements:
		var achievement = achievements[achievement_id]

		if achievement.unlocked:
			continue

		var stat_value = statistics[achievement.type]

		if stat_value >= achievement.requirement:
			unlock_achievement(achievement_id)

# Unlock an achievement
func unlock_achievement(achievement_id):
	if achievements.has(achievement_id) and !achievements[achievement_id].unlocked:
		achievements[achievement_id].unlocked = true
		show_achievement_notification(achievement_id)

# Show achievement notification
func show_achievement_notification(achievement_id):
	var achievement = achievements[achievement_id]

	# Create notification container
	var container = PanelContainer.new()
	container.size = Vector2(300, 80)
	container.position = Vector2(get_viewport().size.x - 320, 20)

	# Create VBox for content
	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Create title with icon
	var title = Label.new()
	title.text = achievement.icon + " Achievement Unlocked: " + achievement.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Create description
	var description = Label.new()
	description.text = achievement.description
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(description)

	# Add to UI
	get_tree().current_scene.add_child(container)

	# Animate and remove
	container.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 1.0, 0.5)
	tween.tween_property(container, "modulate:a", 1.0, 2.0)
	tween.tween_property(container, "modulate:a", 0.0, 0.5)
	await tween.finished
	container.queue_free()

# Update statistics
func update_statistic(stat_name, value):
	if statistics.has(stat_name):
		statistics[stat_name] = value
		check_achievements()

# Increment statistics
func increment_statistic(stat_name, amount = 1):
	if statistics.has(stat_name):
		statistics[stat_name] += amount
		check_achievements()

# Reset statistics for a new game
func reset_game_statistics():
	# Update persistent stats
	statistics.games_played += 1
	statistics.highest_level = max(statistics.highest_level, statistics.player_level)
	statistics.longest_survival_time = max(statistics.longest_survival_time, statistics.time_survived)

	# Reset game-specific stats
	statistics.enemies_defeated = 0
	statistics.player_level = 1
	statistics.time_survived = 0
	statistics.experience_collected = 0
	statistics.damage_dealt = 0
	statistics.damage_taken = 0
	statistics.levels_gained = 0

# Get formatted statistics text
func get_statistics_text():
	# 获取语言管理器
	var language_manager = Engine.get_main_loop().root.get_node_or_null("LanguageManager")
	if not language_manager:
		# 如果找不到语言管理器，尝试从自动加载脚本获取
		var autoload = Engine.get_main_loop().root.get_node_or_null("LanguageAutoload")
		if autoload and autoload.language_manager:
			language_manager = autoload.language_manager

	# 获取翻译文本
	var statistics_text = language_manager.get_translation("statistics", "STATISTICS") if language_manager else "STATISTICS"
	var games_played_text = language_manager.get_translation("games_played", "Games Played") if language_manager else "Games Played"
	var highest_level_text = language_manager.get_translation("highest_level", "Highest Level") if language_manager else "Highest Level"
	var longest_survival_text = language_manager.get_translation("longest_survival", "Longest Survival") if language_manager else "Longest Survival"
	var total_enemies_defeated_text = language_manager.get_translation("total_enemies_defeated", "Total Enemies Defeated") if language_manager else "Total Enemies Defeated"

	var text = statistics_text + "\\n\\n"
	text += games_played_text + ": %d\\n" % statistics.games_played
	text += highest_level_text + ": %d\\n" % statistics.highest_level
	text += longest_survival_text + ": %02d:%02d\\n" % [int(statistics.longest_survival_time / 60), int(statistics.longest_survival_time) % 60]
	text += total_enemies_defeated_text + ": %d\\n" % statistics.enemies_defeated

	return text

# Get formatted achievements text
func get_achievements_text():
	# 获取语言管理器
	var language_manager = Engine.get_main_loop().root.get_node_or_null("LanguageManager")
	if not language_manager:
		# 如果找不到语言管理器，尝试从自动加载脚本获取
		var autoload = Engine.get_main_loop().root.get_node_or_null("LanguageAutoload")
		if autoload and autoload.language_manager:
			language_manager = autoload.language_manager

	# 获取翻译文本
	var achievements_text = language_manager.get_translation("achievements", "ACHIEVEMENTS") if language_manager else "ACHIEVEMENTS"

	var text = achievements_text + "\\n\\n"

	for achievement_id in achievements:
		var achievement = achievements[achievement_id]
		var status = "✅ " if achievement.unlocked else "❌ "

		# 获取成就的翻译名称和描述
		var achievement_title = achievement.title
		var achievement_desc = achievement.description

		if achievement_id and not achievement_id.is_empty() and language_manager:
			var translated_title = language_manager.get_translation("achievement_" + achievement_id + "_name", "")
			var translated_desc = language_manager.get_translation("achievement_" + achievement_id + "_desc", "")

			if not translated_title.is_empty():
				achievement_title = translated_title
			if not translated_desc.is_empty():
				achievement_desc = translated_desc

		text += status + achievement.icon + " " + achievement_title + "\\n"
		text += "    " + achievement_desc + "\\n"

	return text
