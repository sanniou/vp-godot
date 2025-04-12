extends Node2D

# 信号
signal weapon_upgraded(weapon_id, upgrade_type, new_level)
signal enemy_hit(weapon_id, enemy, damage)
signal enemy_killed(weapon_id, enemy, position)

# 武器标识
var weapon_id = "knife"

# 基本属性
var damage = 25
var attack_rate = 1.0  # 每秒攻击次数
var attack_range = 100  # 攻击范围
var attack_angle = PI / 4  # 攻击角度（弧度）

# 升级属性
var damage_level = 1
var attack_rate_level = 1
var range_level = 1
var angle_level = 1

# 内部变量
var can_attack = true
var attack_timer = 0
var attack_direction = Vector2.RIGHT  # 默认向右攻击

func _ready():
	# 设置初始状态
	pass

func _process(delta):
	# 处理攻击冷却
	if !can_attack:
		attack_timer += delta
		if attack_timer >= 1.0 / attack_rate:
			can_attack = true
			attack_timer = 0

	# 更新攻击方向（朝向最近的敌人）
	update_attack_direction()

	# 自动攻击
	if can_attack:
		attack()

# 更新攻击方向
func update_attack_direction():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_distance = 1000000  # 一个很大的初始值

	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy

	if closest_enemy:
		attack_direction = (closest_enemy.global_position - global_position).normalized()

# 攻击函数
func attack():
	can_attack = false

	# 创建刀光效果
	var knife_slash = create_knife_slash()
	get_tree().current_scene.add_child(knife_slash)
	knife_slash.global_position = global_position

	# 设置刀光旋转
	knife_slash.rotation = attack_direction.angle()

	# 检测范围内的敌人并造成伤害
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var to_enemy = enemy.global_position - global_position
		var distance = to_enemy.length()

		# 检查敌人是否在攻击范围内
		if distance <= attack_range:
			# 检查敌人是否在攻击角度内
			var angle_to_enemy = attack_direction.angle_to(to_enemy.normalized())
			if abs(angle_to_enemy) <= attack_angle / 2:
				enemy.take_damage(damage)

# 创建刀光效果
func create_knife_slash():
	var slash = Node2D.new()

	# 创建刀光视觉效果
	var slash_visual = Polygon2D.new()
	var points = []
	points.append(Vector2(0, 0))  # 起点

	# 创建扇形
	var segments = 10
	for i in range(segments + 1):
		var angle = -attack_angle / 2 + attack_angle * i / segments
		var point = Vector2(cos(angle), sin(angle)) * attack_range
		points.append(point)

	slash_visual.polygon = points
	slash_visual.color = Color(1, 1, 1, 0.5)  # 半透明白色
	slash.add_child(slash_visual)

	# 添加动画脚本
	var script = GDScript.new()
	script.source_code = """
extends Node2D

var lifetime = 0
var max_lifetime = 0.3

func _process(delta):
	lifetime += delta

	# 淡出效果
	modulate.a = 1.0 - (lifetime / max_lifetime)

	if lifetime >= max_lifetime:
		call_deferred(\"queue_free\")
"""
	script.reload()
	slash.set_script(script)

	return slash

# 获取升级选项
func get_upgrade_options() -> Array:
	# 使用通用翻译辅助工具
	var Tr = load("res://scripts/language/tr.gd")

	return [
		{
			"type": "damage",
			"name": Tr.weapon_upgrade("damage", "伤害 +10"),
			"description": Tr.weapon_upgrade_desc("damage", "增加飞刀伤害"),
			"icon": "💥"
		},
		{
			"type": "attack_rate",
			"name": Tr.weapon_upgrade("attack_speed", "攻击速度 +30%"),
			"description": Tr.weapon_upgrade_desc("attack_speed", "增加飞刀投掷频率"),
			"icon": "⚡"
		},
		{
			"type": "range",
			"name": Tr.weapon_upgrade("range", "范围 +20"),
			"description": Tr.weapon_upgrade_desc("range", "增加飞刀攻击范围"),
			"icon": "↔️"
		},
		{
			"type": "angle",
			"name": Tr.weapon_upgrade("special", "角度 +22.5°"),
			"description": Tr.weapon_upgrade_desc("special", "增加飞刀攻击角度"),
			"icon": "🔍"
		}
	]

# 升级武器
func upgrade(upgrade_type):
	# 调试输出
	print("Knife upgrading: ", upgrade_type, " (type: ", typeof(upgrade_type), ")")

	# 如果升级类型是整数，尝试将其转换为字符串
	var type_str = upgrade_type
	if typeof(upgrade_type) == TYPE_INT:
		match upgrade_type:
			0: # DAMAGE
				type_str = "damage"
			1: # ATTACK_SPEED
				type_str = "attack_rate"
			2: # AREA
				type_str = "range"
			7: # SPECIAL
				type_str = "angle"

	# 处理升级
	match type_str:
		"damage":
			var old_damage = damage
			damage_level += 1
			damage = 25 + (damage_level - 1) * 10  # 每级+10伤害
			print("Increased knife damage from ", old_damage, " to ", damage)
		"attack_rate", "attack_speed":
			var old_rate = attack_rate
			attack_rate_level += 1
			attack_rate = 1.0 + (attack_rate_level - 1) * 0.3  # 每级+0.3攻击速度
			print("Increased knife attack rate from ", old_rate, " to ", attack_rate)
		"range", "area":
			var old_range = attack_range
			range_level += 1
			attack_range = 100 + (range_level - 1) * 20  # 每级+20范围
			print("Increased knife attack range from ", old_range, " to ", attack_range)
		"angle", "special":
			var old_angle = attack_angle
			angle_level += 1
			attack_angle = PI / 4 + (angle_level - 1) * (PI / 8)  # 每级+22.5度角度
			print("Increased knife attack angle from ", old_angle, " to ", attack_angle)
		_:
			print("Unknown upgrade type for knife: ", upgrade_type)

	# 发出升级信号（如果有）
	if has_signal("weapon_upgraded"):
		emit_signal("weapon_upgraded", "knife", type_str, damage_level)
