extends Node2D

# 信号
signal weapon_upgraded(weapon_id, upgrade_type, new_level)
signal enemy_hit(enemy, damage)
signal enemy_killed(enemy)

# 武器标识
var weapon_id = "lightning"
var weapon_name = "闪电法杖"

# 基本属性
var damage = 30
var strike_rate = 0.8  # 每秒闪电次数
var chain_count = 2  # 闪电链数量
var chain_range = 150  # 闪电链范围

# 升级属性
var damage_level = 1
var strike_rate_level = 1
var chain_count_level = 1
var chain_range_level = 1

# 内部变量
var can_strike = true
var strike_timer = 0

func _ready():
	# 设置初始状态
	pass

func _process(delta):
	# 处理攻击冷却
	if !can_strike:
		strike_timer += delta
		if strike_timer >= 1.0 / strike_rate:
			can_strike = true
			strike_timer = 0

	# 自动攻击
	if can_strike:
		strike_lightning()

# 闪电攻击
func strike_lightning():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return

	can_strike = false

	# 选择一个随机敌人作为主要目标
	var primary_target = enemies[randi() % enemies.size()]

	# 造成伤害并创建闪电效果
	var damage_dealt = damage
	primary_target.take_damage(damage_dealt)
	create_lightning_effect(global_position, primary_target.global_position)

	# 发出信号
	enemy_hit.emit(weapon_id, primary_target, damage_dealt)

	# 检查敌人是否死亡
	if primary_target.current_health <= 0:
		enemy_killed.emit(weapon_id, primary_target, primary_target.global_position)

	# 处理闪电链
	var hit_enemies = [primary_target]
	var current_target = primary_target

	for i in range(chain_count):
		var next_target = find_next_chain_target(current_target, hit_enemies)
		if next_target:
			# 造成伤害并创建闪电效果
			var chain_damage = damage * 0.7  # 链式伤害降低
			next_target.take_damage(chain_damage)
			create_lightning_effect(current_target.global_position, next_target.global_position)

			# 发出信号
			enemy_hit.emit(weapon_id, next_target, chain_damage)

			# 检查敌人是否死亡
			if next_target.current_health <= 0:
				enemy_killed.emit(weapon_id, next_target, next_target.global_position)

			hit_enemies.append(next_target)
			current_target = next_target
		else:
			break  # 没有更多可链接的目标

# 寻找下一个闪电链目标
func find_next_chain_target(current_target, hit_enemies):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_targets = []

	for enemy in enemies:
		# 检查是否已经被击中
		if enemy in hit_enemies:
			continue

		# 检查是否在链接范围内
		var distance = current_target.global_position.distance_to(enemy.global_position)
		if distance <= chain_range:
			valid_targets.append({"enemy": enemy, "distance": distance})

	# 按距离排序
	valid_targets.sort_custom(func(a, b): return a.distance < b.distance)

	# 返回最近的有效目标
	if valid_targets.size() > 0:
		return valid_targets[0].enemy

	return null

# 创建闪电效果
func create_lightning_effect(start_pos, end_pos):
	var lightning = Line2D.new()
	lightning.width = 3
	lightning.default_color = Color(0.5, 0.8, 1.0, 0.8)  # 淡蓝色

	# 创建锯齿状闪电路径
	var points = []
	points.append(start_pos)

	var distance = start_pos.distance_to(end_pos)
	var direction = (end_pos - start_pos).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)

	var segments = 5
	for i in range(1, segments):
		var t = float(i) / segments
		var pos = start_pos.lerp(end_pos, t)

		# 添加随机偏移
		var offset = perpendicular * (randf() * 20 - 10)
		pos += offset

		points.append(pos)

	points.append(end_pos)
	lightning.points = points

	get_tree().current_scene.add_child(lightning)

	# 添加闪电消失动画
	var script = GDScript.new()
	script.source_code = """
extends Line2D

var lifetime = 0
var max_lifetime = 0.2

func _process(delta):
	lifetime += delta

	# 淡出效果
	modulate.a = 1.0 - (lifetime / max_lifetime)

	if lifetime >= max_lifetime:
		call_deferred(\"queue_free\")
"""
	script.reload()
	lightning.set_script(script)

# 升级武器
func upgrade(upgrade_type):
	# 调试输出
	print("Lightning upgrading: ", upgrade_type, " (type: ", typeof(upgrade_type), ")")

	# 如果升级类型是整数，尝试将其转换为字符串
	var type_str = upgrade_type
	var type_int = -1

	if typeof(upgrade_type) == TYPE_INT:
		match upgrade_type:
			0: # DAMAGE
				type_str = "damage"
				type_int = 0
			1: # ATTACK_SPEED
				type_str = "strike_rate"
				type_int = 1
			3: # PROJECTILE_COUNT
				type_str = "chain_count"
				type_int = 2
			2: # AREA
				type_str = "chain_range"
				type_int = 3

	# 处理升级
	match type_str:
		"damage":
			var old_damage = damage
			damage_level += 1
			damage = 30 + (damage_level - 1) * 10  # 每级+10伤害
			print("Increased lightning damage from ", old_damage, " to ", damage)
			type_int = 0
		"strike_rate", "attack_speed":
			var old_rate = strike_rate
			strike_rate_level += 1
			strike_rate = 0.8 + (strike_rate_level - 1) * 0.2  # 每级+0.2攻击速度
			print("Increased lightning strike rate from ", old_rate, " to ", strike_rate)
			type_int = 1
		"chain_count", "projectile_count":
			var old_count = chain_count
			chain_count_level += 1
			chain_count = 2 + (chain_count_level - 1)  # 每级+1链数
			print("Increased lightning chain count from ", old_count, " to ", chain_count)
			type_int = 2
		"chain_range", "range", "area":
			var old_range = chain_range
			chain_range_level += 1
			chain_range = 150 + (chain_range_level - 1) * 30  # 每级+30范围
			print("Increased lightning chain range from ", old_range, " to ", chain_range)
			type_int = 3
		_:
			print("Unknown upgrade type for lightning: ", upgrade_type)

	# 发出升级信号
	if type_int >= 0:
		weapon_upgraded.emit(weapon_id, type_int, damage_level)

# 获取武器升级选项
func get_upgrade_options():
	return [
		{"type": 0, "name": "伤害 +10", "description": "增加闪电伤害", "icon": "💥"},
		{"type": 1, "name": "攻击速度 +20%", "description": "增加闪电攻击速度", "icon": "⚡"},
		{"type": 2, "name": "链数 +1", "description": "增加闪电链数", "icon": "🔗"},
		{"type": 3, "name": "范围 +30", "description": "增加闪电链范围", "icon": "💫"}
	]
