extends AbstractAchievement
class_name CompositeAchievement

# 复合成就特定属性
var required_achievements: Array = []  # 需要解锁的成就ID列表

func _init(achievement_id: String, achievements_list: Array, achievement_icon: String = "🏅", is_secret: bool = false):
	super._init(achievement_id, achievement_icon, is_secret)
	required_achievements = achievements_list
	
	# 存储特定元数据
	metadata["required_achievements"] = required_achievements

# 重写：检查成就是否应该解锁
func check_unlock(statistics: Dictionary, achievement_manager = null) -> bool:
	if unlocked or achievement_manager == null:
		return false
	
	var unlocked_count = 0
	for achievement_id in required_achievements:
		if achievement_manager.is_achievement_unlocked(achievement_id):
			unlocked_count += 1
	
	if unlocked_count >= required_achievements.size():
		unlock()
		return true
	
	return false

# 重写：更新成就进度
func update_from_statistics(statistics: Dictionary, achievement_manager = null) -> void:
	if unlocked or achievement_manager == null:
		return
	
	var unlocked_count = 0
	for achievement_id in required_achievements:
		if achievement_manager.is_achievement_unlocked(achievement_id):
			unlocked_count += 1
	
	update_progress(float(unlocked_count) / float(required_achievements.size()))

# 重写：获取成就描述（多语言支持）
func get_description(language_manager = null, achievement_manager = null) -> String:
	if language_manager:
		var desc_key = "achievement_" + id + "_desc"
		var default_desc = "Unlock all of the following achievements"
		
		var translated_desc = language_manager.get_translation(desc_key, default_desc)
		
		if achievement_manager:
			var achievement_names = []
			for achievement_id in required_achievements:
				var achievement = achievement_manager.get_achievement(achievement_id)
				if achievement:
					achievement_names.append(achievement.get_title(language_manager))
				else:
					achievement_names.append(achievement_id)
			
			var achievements_text = "\n- " + "\n- ".join(achievement_names)
			return translated_desc + ":" + achievements_text
		
		return translated_desc
	
	return "Unlock all of the following achievements"
