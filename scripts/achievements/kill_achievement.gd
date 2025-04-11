extends AbstractAchievement
class_name KillAchievement

# 击杀成就特定属性
var required_kills: int
var enemy_type: String = ""  # 空字符串表示任何敌人类型

func _init(achievement_id: String, kills: int, enemy: String = "", achievement_icon: String = "🔪", is_secret: bool = false):
	super._init(achievement_id, achievement_icon, is_secret)
	required_kills = kills
	enemy_type = enemy
	
	# 存储特定元数据
	metadata["required_kills"] = required_kills
	metadata["enemy_type"] = enemy_type

# 重写：检查成就是否应该解锁
func check_unlock(statistics: Dictionary) -> bool:
	if unlocked:
		return false
	
	var kills = 0
	if enemy_type.is_empty():
		# 检查总击杀数
		if statistics.has("enemies_defeated"):
			kills = statistics.enemies_defeated
	else:
		# 检查特定敌人类型的击杀数
		var key = "enemies_defeated_" + enemy_type
		if statistics.has(key):
			kills = statistics[key]
	
	if kills >= required_kills:
		unlock()
		return true
	
	return false

# 重写：更新成就进度
func update_from_statistics(statistics: Dictionary) -> void:
	if unlocked:
		return
	
	var kills = 0
	if enemy_type.is_empty():
		# 检查总击杀数
		if statistics.has("enemies_defeated"):
			kills = statistics.enemies_defeated
	else:
		# 检查特定敌人类型的击杀数
		var key = "enemies_defeated_" + enemy_type
		if statistics.has(key):
			kills = statistics[key]
	
	update_progress(float(kills) / float(required_kills))

# 重写：获取成就描述（多语言支持）
func get_description(language_manager = null) -> String:
	if language_manager:
		var desc_key = "achievement_" + id + "_desc"
		var default_desc = ""
		
		if enemy_type.is_empty():
			default_desc = "Defeat %d enemies" % required_kills
			var translated_desc = language_manager.get_translation(desc_key, default_desc)
			return translated_desc.replace("%d", str(required_kills))
		else:
			var enemy_name = language_manager.get_translation("enemy_" + enemy_type + "_name", enemy_type.capitalize())
			default_desc = "Defeat %d %s enemies" % [required_kills, enemy_name]
			var translated_desc = language_manager.get_translation(desc_key, default_desc)
			return translated_desc.replace("%d", str(required_kills))
	
	if enemy_type.is_empty():
		return "Defeat %d enemies" % required_kills
	else:
		return "Defeat %d %s enemies" % [required_kills, enemy_type.capitalize()]
