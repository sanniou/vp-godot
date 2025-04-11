extends AbstractAchievement
class_name StatisticAchievement

# 统计成就特定属性
var statistic_key: String
var required_value: float
var comparison_type: String = "greater_equal"  # greater_equal, equal, less_equal

func _init(achievement_id: String, stat_key: String, value: float, compare_type: String = "greater_equal", achievement_icon: String = "📊", is_secret: bool = false):
	super._init(achievement_id, achievement_icon, is_secret)
	statistic_key = stat_key
	required_value = value
	comparison_type = compare_type
	
	# 存储特定元数据
	metadata["statistic_key"] = statistic_key
	metadata["required_value"] = required_value
	metadata["comparison_type"] = comparison_type

# 重写：检查成就是否应该解锁
func check_unlock(statistics: Dictionary) -> bool:
	if unlocked:
		return false
	
	if not statistics.has(statistic_key):
		return false
	
	var current_value = statistics[statistic_key]
	var should_unlock = false
	
	match comparison_type:
		"greater_equal":
			should_unlock = current_value >= required_value
		"equal":
			should_unlock = current_value == required_value
		"less_equal":
			should_unlock = current_value <= required_value
	
	if should_unlock:
		unlock()
		return true
	
	return false

# 重写：更新成就进度
func update_from_statistics(statistics: Dictionary) -> void:
	if unlocked:
		return
	
	if not statistics.has(statistic_key):
		return
	
	var current_value = statistics[statistic_key]
	var progress_value = 0.0
	
	match comparison_type:
		"greater_equal":
			progress_value = clamp(current_value / required_value, 0.0, 1.0)
		"equal":
			progress_value = 1.0 if current_value == required_value else 0.0
		"less_equal":
			if required_value == 0:
				progress_value = 1.0 if current_value <= 0 else 0.0
			else:
				# 反向进度：值越小，进度越高
				progress_value = clamp(1.0 - (current_value / required_value), 0.0, 1.0)
	
	update_progress(progress_value)

# 重写：获取成就描述（多语言支持）
func get_description(language_manager = null) -> String:
	if language_manager:
		var desc_key = "achievement_" + id + "_desc"
		var stat_name = language_manager.get_translation("stat_" + statistic_key, statistic_key.capitalize())
		
		var comparison_text = ""
		match comparison_type:
			"greater_equal":
				comparison_text = language_manager.get_translation("comparison_greater_equal", "at least %s")
			"equal":
				comparison_text = language_manager.get_translation("comparison_equal", "exactly %s")
			"less_equal":
				comparison_text = language_manager.get_translation("comparison_less_equal", "at most %s")
		
		comparison_text = comparison_text.replace("%s", str(required_value))
		
		var default_desc = "Achieve %s %s"
		var translated_desc = language_manager.get_translation(desc_key, default_desc)
		return translated_desc.replace("%s", stat_name).replace("%s", comparison_text)
	
	var comparison_text = ""
	match comparison_type:
		"greater_equal":
			comparison_text = "at least %s" % required_value
		"equal":
			comparison_text = "exactly %s" % required_value
		"less_equal":
			comparison_text = "at most %s" % required_value
	
	return "Achieve %s %s" % [statistic_key.capitalize(), comparison_text]
