extends AbstractAchievement
class_name SurvivalAchievement

# 生存成就特定属性
var required_seconds: int

func _init(achievement_id: String, seconds: int, achievement_icon: String = "⏱️", is_secret: bool = false):
	super._init(achievement_id, achievement_icon, is_secret)
	required_seconds = seconds
	
	# 存储特定元数据
	metadata["required_seconds"] = required_seconds

# 重写：检查成就是否应该解锁
func check_unlock(statistics: Dictionary) -> bool:
	if unlocked:
		return false
	
	if statistics.has("time_survived") and statistics.time_survived >= required_seconds:
		unlock()
		return true
	
	return false

# 重写：更新成就进度
func update_from_statistics(statistics: Dictionary) -> void:
	if unlocked:
		return
	
	if statistics.has("time_survived"):
		update_progress(float(statistics.time_survived) / float(required_seconds))

# 重写：获取成就描述（多语言支持）
func get_description(language_manager = null) -> String:
	if language_manager:
		var desc_key = "achievement_" + id + "_desc"
		var default_desc = "Survive for %s"
		var translated_desc = language_manager.get_translation(desc_key, default_desc)
		return translated_desc.replace("%s", format_time(required_seconds, language_manager))
	
	return "Survive for %s" % format_time(required_seconds)

# 格式化时间
func format_time(seconds: int, language_manager = null) -> String:
	var minutes = seconds / 60
	
	if language_manager:
		if minutes == 1:
			return language_manager.get_translation("time_format_minute", "1 minute")
		else:
			var format = language_manager.get_translation("time_format_minutes", "%d minutes")
			return format.replace("%d", str(minutes))
	
	if minutes == 1:
		return "1 minute"
	else:
		return "%d minutes" % minutes
