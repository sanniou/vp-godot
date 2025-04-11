extends AbstractAchievement
class_name RelicAchievement

# 遗物成就特定属性
var required_relics: int
var specific_relics: Array = []  # 空数组表示任何遗物

func _init(achievement_id: String, relics_count: int, relics_list: Array = [], achievement_icon: String = "🔮", is_secret: bool = false):
	super._init(achievement_id, achievement_icon, is_secret)
	required_relics = relics_count
	specific_relics = relics_list
	
	# 存储特定元数据
	metadata["required_relics"] = required_relics
	metadata["specific_relics"] = specific_relics

# 重写：检查成就是否应该解锁
func check_unlock(statistics: Dictionary) -> bool:
	if unlocked:
		return false
	
	if specific_relics.is_empty():
		# 检查总遗物数
		if statistics.has("relics_collected") and statistics.relics_collected >= required_relics:
			unlock()
			return true
	else:
		# 检查特定遗物
		var collected_count = 0
		for relic in specific_relics:
			var key = "relic_collected_" + relic
			if statistics.has(key) and statistics[key]:
				collected_count += 1
		
		if collected_count >= required_relics:
			unlock()
			return true
	
	return false

# 重写：更新成就进度
func update_from_statistics(statistics: Dictionary) -> void:
	if unlocked:
		return
	
	if specific_relics.is_empty():
		# 检查总遗物数
		if statistics.has("relics_collected"):
			update_progress(float(statistics.relics_collected) / float(required_relics))
	else:
		# 检查特定遗物
		var collected_count = 0
		for relic in specific_relics:
			var key = "relic_collected_" + relic
			if statistics.has(key) and statistics[key]:
				collected_count += 1
		
		update_progress(float(collected_count) / float(required_relics))

# 重写：获取成就描述（多语言支持）
func get_description(language_manager = null) -> String:
	if language_manager:
		var desc_key = "achievement_" + id + "_desc"
		
		if specific_relics.is_empty():
			var default_desc = "Collect %d relics"
			var translated_desc = language_manager.get_translation(desc_key, default_desc)
			return translated_desc.replace("%d", str(required_relics))
		else:
			var relic_names = []
			for relic in specific_relics:
				var relic_name = language_manager.get_translation("relic_" + relic + "_name", relic.capitalize())
				relic_names.append(relic_name)
			
			var relics_text = ", ".join(relic_names)
			var default_desc = "Collect the following relics: %s"
			var translated_desc = language_manager.get_translation(desc_key, default_desc)
			return translated_desc.replace("%s", relics_text)
	
	if specific_relics.is_empty():
		return "Collect %d relics" % required_relics
	else:
		var relic_names = []
		for relic in specific_relics:
			relic_names.append(relic.capitalize())
		
		var relics_text = ", ".join(relic_names)
		return "Collect the following relics: %s" % relics_text
