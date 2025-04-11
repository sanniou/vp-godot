extends Node2D

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

# 升级武器
func upgrade(upgrade_type):
	match upgrade_type:
		"damage":
			damage_level += 1
			damage = 25 + (damage_level - 1) * 10  # 每级+10伤害
		"attack_rate":
			attack_rate_level += 1
			attack_rate = 1.0 + (attack_rate_level - 1) * 0.3  # 每级+0.3攻击速度
		"range":
			range_level += 1
			attack_range = 100 + (range_level - 1) * 20  # 每级+20范围
		"angle":
			angle_level += 1
			attack_angle = PI / 4 + (angle_level - 1) * (PI / 8)  # 每级+22.5度角度
