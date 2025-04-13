extends Node

# 遗物工具类
# 提供遗物相关的通用功能，如图标映射、信息获取等

# 获取遗物图标
static func get_relic_icon(relic_id: String) -> String:
	# 根据ID返回对应的图标
	match relic_id:
		"phoenix_feather":
			return "🔥"
		"wisdom_crystal":
			return "💎"
		"magnetic_amulet":
			return "🧲"
		"heart_amulet":
			return "❤️"
		"lucky_clover":
			return "🍀"
		"shadow_cloak":
			return "👻"
		"upgrade_enhancer":
			return "🔮"
		"time_warper":
			return "⏱️"
		"elemental_resonance":
			return "🔄"
		"experience_catalyst":
			return "✨"
		"critical_amulet":
			return "🔮"
		"life_steal":
			return "💉"
		_:
			return "💫"  # 默认图标

# 格式化遗物名称（将下划线替换为空格并将首字母大写）
static func format_relic_name(relic_id: String) -> String:
	# 将下划线替换为空格
	var formatted_name = relic_id.replace("_", " ")

	# 将首字母大写
	if formatted_name.length() > 0:
		formatted_name = formatted_name.substr(0, 1).to_upper() + formatted_name.substr(1)

	return formatted_name

# 获取遗物名称的翻译
static func get_relic_name(relic_id: String, language_manager = null) -> String:
	# 使用通用翻译辅助工具
	var Tr = load("res://scripts/language/tr.gd")
	return Tr.relic_name(relic_id)

# 获取遗物描述的翻译
static func get_relic_description(relic_id: String, language_manager = null) -> String:
	# 使用通用翻译辅助工具
	var Tr = load("res://scripts/language/tr.gd")
	return Tr.relic_desc(relic_id)

# 获取遗物稀有度颜色
static func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color(0.7, 0.7, 0.7)  # 灰色
		"uncommon":
			return Color(0.2, 0.8, 0.2)  # 绿色
		"rare":
			return Color(0.2, 0.4, 1.0)  # 蓝色
		"epic":
			return Color(0.8, 0.2, 0.8)  # 紫色
		"legendary":
			return Color(1.0, 0.6, 0.1)  # 橙色
		_:
			return Color(1.0, 1.0, 1.0)  # 白色
