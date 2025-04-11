extends Node

# 武器翻译工具 - 用于处理武器名称和描述的多语言翻译

# 获取武器名称的翻译
static func get_weapon_name(weapon_id: String, language_manager = null) -> String:
	# 使用通用翻译辅助工具
	var Tr = load("res://scripts/language/tr.gd")
	return Tr.weapon_name(weapon_id)

# 获取武器描述的翻译
static func get_weapon_description(weapon_id: String, language_manager = null) -> String:
	# 使用通用翻译辅助工具
	var Tr = load("res://scripts/language/tr.gd")
	return Tr.weapon_desc(weapon_id)

# 获取武器升级选项的翻译
static func get_upgrade_option_name(option_type: int, language_manager = null) -> String:
	# 使用通用翻译辅助工具
	var Tr = load("res://scripts/language/tr.gd")

	# 将数字类型转换为字符串类型
	var upgrade_type = ""

	match option_type:
		0: upgrade_type = "damage"
		1: upgrade_type = "attack_speed"
		2: upgrade_type = "range"
		3: upgrade_type = "duration"
		4: upgrade_type = "penetration"
		5: upgrade_type = "bounce"
		6: upgrade_type = "projectile_count"
		7: upgrade_type = "projectile_speed"
		8: upgrade_type = "hit_count"
		9: upgrade_type = "cooldown"
		10: upgrade_type = "special"
		_: upgrade_type = "unknown"

	return Tr.weapon_upgrade(upgrade_type)

# 获取武器升级选项的描述翻译
static func get_upgrade_option_description(option_type: int, language_manager = null) -> String:
	# 使用通用翻译辅助工具
	var Tr = load("res://scripts/language/tr.gd")

	# 将数字类型转换为字符串类型
	var upgrade_type = ""

	match option_type:
		0: upgrade_type = "damage"
		1: upgrade_type = "attack_speed"
		2: upgrade_type = "range"
		3: upgrade_type = "duration"
		4: upgrade_type = "penetration"
		5: upgrade_type = "bounce"
		6: upgrade_type = "projectile_count"
		7: upgrade_type = "projectile_speed"
		8: upgrade_type = "hit_count"
		9: upgrade_type = "cooldown"
		10: upgrade_type = "special"
		_: upgrade_type = "unknown"

	return Tr.weapon_upgrade_desc(upgrade_type)
