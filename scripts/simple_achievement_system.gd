extends Node
class_name SimpleAchievementSystem

signal achievement_unlocked(achievement_id, achievement_name, achievement_description)

# 成就数据结构
class Achievement:
	var id: String
	var name: String
	var description: String
	var icon: String
	var unlocked: bool = false
	var progress: float = 0.0  # 0.0 to 1.0
	var unlock_time: int = 0  # Unix timestamp

	func _init(p_id: String, p_name: String, p_description: String, p_icon: String = "🏆"):
		id = p_id
		name = p_name
		description = p_description
		icon = p_icon

	func unlock():
		if not unlocked:
			unlocked = true
			progress = 1.0
			unlock_time = int(Time.get_unix_time_from_system())
			return true
		return false

	func update_progress(value: float):
		if not unlocked:
			progress = clamp(value, 0.0, 1.0)
			if progress >= 1.0:
				unlock()
				return true
		return false

	func get_formatted_progress() -> String:
		return str(int(progress * 100)) + "%"

# 成就字典，键为成就ID，值为成就对象
var achievements = {}

# 统计数据
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

# 初始化
func _ready():
	# 注册所有成就
	register_achievements()

# 注册所有成就
func register_achievements():
	# 击杀成就
	register_achievement("first_blood", "First Blood", "Defeat your first enemy", "🩸")
	register_achievement("monster_hunter", "Monster Hunter", "Defeat 50 enemies", "🔪")
	register_achievement("exterminator", "Exterminator", "Defeat 100 enemies", "💀")

	# 等级成就
	register_achievement("level_up", "Level Up", "Reach level 5", "⬆️")
	register_achievement("master", "Master", "Reach level 10", "🌟")

	# 生存成就
	register_achievement("survivor", "Survivor", "Survive for 5 minutes", "⏱️")
	register_achievement("endurance", "Endurance", "Survive for 10 minutes", "⏳")
	register_achievement("marathon", "Marathon", "Survive for 20 minutes", "🏆")

# 注册单个成就
func register_achievement(id: String, name: String, description: String, icon: String = "🏆"):
	achievements[id] = Achievement.new(id, name, description, icon)

# 解锁成就
func unlock_achievement(achievement_id: String):
	if achievements.has(achievement_id):
		var achievement = achievements[achievement_id]
		if achievement.unlock():
			emit_signal("achievement_unlocked", achievement_id, achievement.name, achievement.description)
			return true
	return false

# 更新统计数据
func update_statistic(stat_name: String, value):
	if statistics.has(stat_name):
		statistics[stat_name] = value
		check_achievements()

# 增加统计数据
func increment_statistic(stat_name: String, amount: int = 1):
	if statistics.has(stat_name):
		statistics[stat_name] += amount
		check_achievements()

# 检查所有成就是否应该解锁
func check_achievements():
	# 检查击杀成就
	if statistics.enemies_defeated >= 1:
		unlock_achievement("first_blood")
	if statistics.enemies_defeated >= 50:
		unlock_achievement("monster_hunter")
	if statistics.enemies_defeated >= 100:
		unlock_achievement("exterminator")

	# 检查等级成就
	if statistics.player_level >= 5:
		unlock_achievement("level_up")
	if statistics.player_level >= 10:
		unlock_achievement("master")

	# 检查生存成就
	if statistics.time_survived >= 5 * 60:  # 5分钟
		unlock_achievement("survivor")
	if statistics.time_survived >= 10 * 60:  # 10分钟
		unlock_achievement("endurance")
	if statistics.time_survived >= 20 * 60:  # 20分钟
		unlock_achievement("marathon")

	# 更新成就进度
	update_achievements_progress()

# 更新所有成就的进度
func update_achievements_progress():
	# 击杀成就进度
	if not achievements["first_blood"].unlocked:
		achievements["first_blood"].update_progress(min(statistics.enemies_defeated, 1.0))
	if not achievements["monster_hunter"].unlocked:
		achievements["monster_hunter"].update_progress(float(statistics.enemies_defeated) / 50.0)
	if not achievements["exterminator"].unlocked:
		achievements["exterminator"].update_progress(float(statistics.enemies_defeated) / 100.0)

	# 等级成就进度
	if not achievements["level_up"].unlocked:
		achievements["level_up"].update_progress(float(statistics.player_level) / 5.0)
	if not achievements["master"].unlocked:
		achievements["master"].update_progress(float(statistics.player_level) / 10.0)

	# 生存成就进度
	if not achievements["survivor"].unlocked:
		achievements["survivor"].update_progress(float(statistics.time_survived) / (5.0 * 60.0))
	if not achievements["endurance"].unlocked:
		achievements["endurance"].update_progress(float(statistics.time_survived) / (10.0 * 60.0))
	if not achievements["marathon"].unlocked:
		achievements["marathon"].update_progress(float(statistics.time_survived) / (20.0 * 60.0))

# 获取成就
func get_achievement(achievement_id: String):
	if achievements.has(achievement_id):
		return achievements[achievement_id]
	return null

# 检查成就是否已解锁
func is_achievement_unlocked(achievement_id: String) -> bool:
	if achievements.has(achievement_id):
		return achievements[achievement_id].unlocked
	return false

# 获取已解锁的成就数量
func get_unlocked_achievements_count() -> int:
	var count = 0
	for achievement_id in achievements:
		if achievements[achievement_id].unlocked:
			count += 1
	return count

# 获取成就总数
func get_total_achievements_count() -> int:
	return achievements.size()

# 显示成就解锁通知
func show_achievement_notification(achievement_id: String):
	if not achievements.has(achievement_id):
		return

	var achievement = achievements[achievement_id]

	# 创建通知容器
	var container = PanelContainer.new()
	container.size = Vector2(300, 80)
	container.position = Vector2(get_viewport().size.x - 320, 20)

	# 创建内容垂直布局
	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# 创建标题和图标
	var title = Label.new()
	title.text = achievement.icon + " Achievement Unlocked: " + achievement.name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# 创建描述
	var description = Label.new()
	description.text = achievement.description
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(description)

	# 添加到UI
	get_tree().current_scene.add_child(container)

	# 动画和移除
	container.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 1.0, 0.5)
	tween.tween_property(container, "modulate:a", 1.0, 2.0)
	tween.tween_property(container, "modulate:a", 0.0, 0.5)
	await tween.finished
	container.queue_free()

# 保存成就数据
func save_achievements() -> Dictionary:
	var save_data = {
		"statistics": statistics,
		"achievements": {}
	}

	for achievement_id in achievements:
		var achievement = achievements[achievement_id]
		save_data.achievements[achievement_id] = {
			"unlocked": achievement.unlocked,
			"progress": achievement.progress,
			"unlock_time": achievement.unlock_time
		}

	return save_data

# 加载成就数据
func load_achievements(save_data: Dictionary) -> bool:
	if not save_data.has("statistics") or not save_data.has("achievements"):
		return false

	# 加载统计数据
	for stat_name in save_data.statistics:
		if statistics.has(stat_name):
			statistics[stat_name] = save_data.statistics[stat_name]

	# 加载成就数据
	for achievement_id in save_data.achievements:
		if achievements.has(achievement_id):
			var achievement_data = save_data.achievements[achievement_id]
			achievements[achievement_id].unlocked = achievement_data.unlocked
			achievements[achievement_id].progress = achievement_data.progress
			achievements[achievement_id].unlock_time = achievement_data.unlock_time

	return true

# 重置游戏统计数据
func reset_game_statistics():
	# 更新持久性统计数据
	statistics.games_played += 1
	statistics.highest_level = max(statistics.highest_level, statistics.player_level)
	statistics.longest_survival_time = max(statistics.longest_survival_time, statistics.time_survived)

	# 重置游戏特定统计数据
	statistics.enemies_defeated = 0
	statistics.player_level = 1
	statistics.time_survived = 0
	statistics.experience_collected = 0
	statistics.damage_dealt = 0
	statistics.damage_taken = 0
	statistics.levels_gained = 0

# 保存成就到文件
func save_achievements_to_file(file_path: String = "user://achievements.save") -> bool:
	var save_data = save_achievements()

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("Error saving achievements: ", FileAccess.get_open_error())
		return false

	file.store_var(save_data)
	file.close()

	print("Achievements saved to: ", file_path)
	return true

# 从文件加载成就
func load_achievements_from_file(file_path: String = "user://achievements.save") -> bool:
	if not FileAccess.file_exists(file_path):
		print("Achievement save file not found: ", file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Error loading achievements: ", FileAccess.get_open_error())
		return false

	var save_data = file.get_var()
	file.close()

	if not save_data is Dictionary:
		print("Invalid achievement save data format")
		return false

	var result = load_achievements(save_data)
	if result:
		print("Achievements loaded from: ", file_path)

	return result

# 连接成就解锁信号
func _on_achievement_unlocked(achievement_id: String, achievement_name: String, achievement_description: String):
	show_achievement_notification(achievement_id)
