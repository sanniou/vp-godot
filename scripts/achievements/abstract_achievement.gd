extends RefCounted
class_name AbstractAchievement

# 成就基本属性
var id: String
var icon: String
var unlocked: bool = false
var unlock_time: int = 0  # Unix timestamp
var progress: float = 0.0  # 0.0 to 1.0
var secret: bool = false  # 是否为隐藏成就

# 成就元数据
var metadata = {}  # 可以存储任何额外数据

# 初始化成就
func _init(achievement_id: String, achievement_icon: String = "🏆", is_secret: bool = false):
	id = achievement_id
	icon = achievement_icon
	secret = is_secret

# 获取成就标题（多语言支持）
func get_title(language_manager = null) -> String:
	if language_manager:
		return language_manager.get_translation("achievement_" + id + "_title", id.capitalize())
	return id.capitalize()

# 获取成就描述（多语言支持）
func get_description(language_manager = null) -> String:
	if language_manager:
		return language_manager.get_translation("achievement_" + id + "_desc", "Achievement description")
	return "Achievement description"

# 检查成就是否已解锁
func is_unlocked() -> bool:
	return unlocked

# 解锁成就
func unlock(timestamp: int = 0):
	if not unlocked:
		unlocked = true
		unlock_time = timestamp if timestamp > 0 else int(Time.get_unix_time_from_system())
		progress = 1.0
		return true
	return false

# 更新成就进度
func update_progress(value: float):
	if not unlocked:
		progress = clamp(value, 0.0, 1.0)
		if progress >= 1.0:
			unlock()
			return true
	return false

# 重置成就进度（但保持解锁状态）
func reset_progress():
	if not unlocked:
		progress = 0.0

# 完全重置成就（包括解锁状态）
func full_reset():
	unlocked = false
	unlock_time = 0
	progress = 0.0

# 获取成就数据（用于保存）
func get_save_data() -> Dictionary:
	return {
		"id": id,
		"unlocked": unlocked,
		"unlock_time": unlock_time,
		"progress": progress,
		"metadata": metadata
	}

# 从保存数据加载成就
func load_from_save_data(data: Dictionary):
	if data.has("unlocked"):
		unlocked = data.unlocked
	if data.has("unlock_time"):
		unlock_time = data.unlock_time
	if data.has("progress"):
		progress = data.progress
	if data.has("metadata"):
		metadata = data.metadata

# 获取格式化的解锁时间
func get_formatted_unlock_time() -> String:
	if not unlocked:
		return ""
	
	var datetime = Time.get_datetime_dict_from_unix_time(unlock_time)
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

# 获取格式化的进度
func get_formatted_progress(language_manager = null) -> String:
	var percent = int(progress * 100)
	if language_manager:
		return language_manager.get_translation("progress_format", "%d%%").replace("%d", str(percent))
	return str(percent) + "%"

# 虚方法：检查成就是否应该解锁
# 子类应该重写这个方法
func check_unlock(statistics: Dictionary) -> bool:
	return false

# 虚方法：更新成就进度
# 子类应该重写这个方法
func update_from_statistics(statistics: Dictionary) -> void:
	pass
