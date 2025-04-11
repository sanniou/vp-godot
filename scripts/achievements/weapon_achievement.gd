extends AbstractAchievement
class_name WeaponAchievement

# 武器成就特定属性
var required_weapons: int
var specific_weapons: Array = []  # 空数组表示任何武器

func _init(achievement_id: String, weapons_count: int, weapons_list: Array = [], achievement_icon: String = "🔫", is_secret: bool = false):
	super._init(achievement_id, achievement_icon, is_secret)
	required_weapons = weapons_count
	specific_weapons = weapons_list
	
	# 存储特定元数据
	metadata["required_weapons"] = required_weapons
	metadata["specific_weapons"] = specific_weapons

# 重写：检查成就是否应该解锁
func check_unlock(statistics: Dictionary) -> bool:
	if unlocked:
		return false
	
	if specific_weapons.is_empty():
		# 检查总武器数
		if statistics.has("weapons_unlocked") and statistics.weapons_unlocked >= required_weapons:
			unlock()
			return true
	else:
		# 检查特定武器
		var unlocked_count = 0
		for weapon in specific_weapons:
			var key = "weapon_unlocked_" + weapon
			if statistics.has(key) and statistics[key]:
				unlocked_count += 1
		
		if unlocked_count >= required_weapons:
			unlock()
			return true
	
	return false

# 重写：更新成就进度
func update_from_statistics(statistics: Dictionary) -> void:
	if unlocked:
		return
	
	if specific_weapons.is_empty():
		# 检查总武器数
		if statistics.has("weapons_unlocked"):
			update_progress(float(statistics.weapons_unlocked) / float(required_weapons))
	else:
		# 检查特定武器
		var unlocked_count = 0
		for weapon in specific_weapons:
			var key = "weapon_unlocked_" + weapon
			if statistics.has(key) and statistics[key]:
				unlocked_count += 1
		
		update_progress(float(unlocked_count) / float(required_weapons))

# 重写：获取成就描述（多语言支持）
func get_description(language_manager = null) -> String:
	if language_manager:
		var desc_key = "achievement_" + id + "_desc"
		
		if specific_weapons.is_empty():
			var default_desc = "Unlock %d weapons"
			var translated_desc = language_manager.get_translation(desc_key, default_desc)
			return translated_desc.replace("%d", str(required_weapons))
		else:
			var weapon_names = []
			for weapon in specific_weapons:
				var weapon_name = language_manager.get_translation("weapon_" + weapon + "_name", weapon.capitalize())
				weapon_names.append(weapon_name)
			
			var weapons_text = ", ".join(weapon_names)
			var default_desc = "Unlock the following weapons: %s"
			var translated_desc = language_manager.get_translation(desc_key, default_desc)
			return translated_desc.replace("%s", weapons_text)
	
	if specific_weapons.is_empty():
		return "Unlock %d weapons" % required_weapons
	else:
		var weapon_names = []
		for weapon in specific_weapons:
			weapon_names.append(weapon.capitalize())
		
		var weapons_text = ", ".join(weapon_names)
		return "Unlock the following weapons: %s" % weapons_text
