extends Node

# 遗物列表
var relics = {
	"phoenix_feather": {
		"name": "凤凰之羽",
		"description": "死亡时自动复活一次，恢复50%生命值",
		"icon": "🔥",
		"effect": "resurrection",
		"used": false
	},
	"wisdom_crystal": {
		"name": "智慧水晶",
		"description": "游戏开始时自动获得一级",
		"icon": "💎",
		"effect": "start_level_up",
		"used": false
	},
	"magnetic_amulet": {
		"name": "磁力护符",
		"description": "经验球吸取范围增加50%，经验值增加20%",
		"icon": "🧲",
		"effect": "exp_boost",
		"value": 0.2
	},
	"ancient_scroll": {
		"name": "远古卷轴",
		"description": "所有武器伤害增加15%",
		"icon": "📜",
		"effect": "damage_boost",
		"value": 0.15
	},
	"swift_boots": {
		"name": "迅捷之靴",
		"description": "移动速度增加15%",
		"icon": "👢",
		"effect": "speed_boost",
		"value": 0.15
	},
	"heart_amulet": {
		"name": "生命护符",
		"description": "最大生命值增加25",
		"icon": "❤️",
		"effect": "health_boost",
		"value": 25
	},
	"lucky_clover": {
		"name": "幸运四叶草",
		"description": "升级时获得4个选项而不是3个",
		"icon": "🍀",
		"effect": "more_options",
		"value": 4
	},
	"time_hourglass": {
		"name": "时间沙漏",
		"description": "武器冷却时间减少10%",
		"icon": "⌛",
		"effect": "cooldown_reduction",
		"value": 0.1
	},
	"iron_shield": {
		"name": "钢铁护盾",
		"description": "受到的伤害减少15%",
		"icon": "🛡️",
		"effect": "damage_reduction",
		"value": 0.15
	},
	"vampiric_fang": {
		"name": "吸血獠牙",
		"description": "击败敌人时有10%几率恢复1点生命值",
		"icon": "🧛",
		"effect": "life_steal",
		"value": 0.1,
		"heal_amount": 1
	},
	"golden_apple": {
		"name": "黄金苹果",
		"description": "每60秒自动恢复10点生命值",
		"icon": "🍎",
		"effect": "regeneration",
		"interval": 60,
		"value": 10
	},
	"shadow_cloak": {
		"name": "暗影披风",
		"description": "10%几率闪避敌人攻击",
		"icon": "👻",
		"effect": "dodge",
		"value": 0.1
	},
	"berserker_blood": {
		"name": "狂战士之血",
		"description": "生命值低于30%时，伤害增加25%",
		"icon": "💉",
		"effect": "low_health_damage",
		"threshold": 0.3,
		"value": 0.25
	},
	"alchemist_stone": {
		"name": "炼金石",
		"description": "升级所需经验减少10%",
		"icon": "🧪",
		"effect": "exp_reduction",
		"value": 0.1
	},
	"crown_of_thorns": {
		"name": "荆棘王冠",
		"description": "受到攻击时，对攻击者造成5点反伤",
		"icon": "👑",
		"effect": "thorns",
		"value": 5
	}
}

# 已装备的遗物
var equipped_relics = []

# 初始化
func _ready():
	pass

# 装备遗物
func equip_relic(relic_id):
	if relics.has(relic_id) and not equipped_relics.has(relic_id):
		equipped_relics.append(relic_id)
		print("Equipped relic: ", relic_id, " - ", relics[relic_id].name)
		return true
	return false

# 卸下遗物
func unequip_relic(relic_id):
	if equipped_relics.has(relic_id):
		equipped_relics.erase(relic_id)
		return true
	return false

# 检查是否装备了特定遗物
func has_relic(relic_id):
	return equipped_relics.has(relic_id)

# 获取遗物信息
func get_relic(relic_id):
	if relics.has(relic_id):
		return relics[relic_id]
	return null

# 获取所有已装备遗物
func get_equipped_relics():
	var result = []
	for relic_id in equipped_relics:
		if relics.has(relic_id):
			var relic = relics[relic_id].duplicate()
			relic["id"] = relic_id
			result.append(relic)
	return result

# 应用遗物效果：经验值增益
func apply_exp_boost(base_exp):
	var modified_exp = base_exp

	for relic_id in equipped_relics:
		var relic = relics[relic_id]
		if relic.effect == "exp_boost":
			modified_exp += base_exp * relic.value

	return modified_exp

# 应用遗物效果：伤害增益
func apply_damage_boost(base_damage, player = null):
	var modified_damage = base_damage

	for relic_id in equipped_relics:
		var relic = relics[relic_id]
		if relic.effect == "damage_boost":
			modified_damage += base_damage * relic.value
		elif relic.effect == "low_health_damage" and player != null:
			# 检查玩家生命值是否低于阈值
			var health_percent = float(player.current_health) / player.max_health
			if health_percent <= relic.threshold:
				modified_damage += base_damage * relic.value

	return modified_damage

# 应用遗物效果：伤害减免
func apply_damage_reduction(incoming_damage):
	var modified_damage = incoming_damage

	for relic_id in equipped_relics:
		var relic = relics[relic_id]
		if relic.effect == "damage_reduction":
			modified_damage -= incoming_damage * relic.value

	return max(1, modified_damage)  # 确保至少造成1点伤害

# 应用遗物效果：闪避
func apply_dodge():
	for relic_id in equipped_relics:
		var relic = relics[relic_id]
		if relic.effect == "dodge":
			if randf() < relic.value:
				return true  # 成功闪避

	return false  # 未闪避

# 应用遗物效果：复活
func apply_resurrection(player):
	for relic_id in equipped_relics:
		var relic = relics[relic_id]
		if relic.effect == "resurrection" and not relic.used:
			# 标记为已使用
			relic.used = true
			# 恢复50%生命值
			player.current_health = player.max_health * 0.5
			return true

	return false

# 应用遗物效果：反伤
func apply_thorns(attacker):
	for relic_id in equipped_relics:
		var relic = relics[relic_id]
		if relic.effect == "thorns" and attacker != null:
			attacker.take_damage(relic.value)

# 应用遗物效果：吸血
func apply_life_steal(player):
	for relic_id in equipped_relics:
		var relic = relics[relic_id]
		if relic.effect == "life_steal":
			if randf() < relic.value:
				player.heal(relic.heal_amount)
				return true

	return false

# 获取升级选项数量
func get_upgrade_options_count():
	for relic_id in equipped_relics:
		var relic = relics[relic_id]
		if relic.effect == "more_options":
			return relic.value

	return 3  # 默认值
