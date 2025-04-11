extends AbstractAchievement
class_name LevelAchievement

# 等级成就特定属性
var required_level: int

func _init(achievement_id: String, level: int, achievement_icon: String = "⬆️", is_secret: bool = false):
	super._init(achievement_id, achievement_icon, is_secret)
	required_level = level
	
	# 存储特定元数据
	metadata["required_level"] = required_level

# 重写：检查成就是否应该解锁
func check_unlock(statistics: Dictionary) -> bool:
	if unlocked:
		return false
	
	if statistics.has("player_level") and statistics.player_level >= required_level:
		unlock()
		return true
	
	return false

# 重写：更新成就进度
func update_from_statistics(statistics: Dictionary) -> void:
	if unlocked:
		return
	
	if statistics.has("player_level"):
		update_progress(float(statistics.player_level) / float(required_level))

# 重写：获取成就描述（多语言支持）
func get_description(language_manager = null) -> String:
	if language_manager:
		var desc_key = "achievement_" + id + "_desc"
		var default_desc = "Reach level %d"
		var translated_desc = language_manager.get_translation(desc_key, default_desc)
		return translated_desc.replace("%d", str(required_level))
	
	return "Reach level %d" % required_level
