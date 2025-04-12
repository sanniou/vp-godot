extends Node2D

# 基本属性
var shield_amount = 20  # 护盾值
var burn_damage = 10  # 灼烧伤害
var burn_radius = 80  # 灼烧范围
var burn_rate = 0.5  # 每秒灼烧次数

# 升级属性
var shield_level = 1
var burn_damage_level = 1
var burn_radius_level = 1

# 内部变量
var shield_active = true
var burn_timer = 0
var shield_visual = null
var burn_area = null

func _ready():
	# 创建护盾视觉效果
	create_shield_visual()

	# 创建灼烧区域
	create_burn_area()

func _process(delta):
	# 处理灼烧计时器
	burn_timer += delta
	if burn_timer >= 1.0 / burn_rate:
		burn_timer = 0
		apply_burn_damage()

	# 更新护盾位置
	if shield_visual:
		shield_visual.global_position = global_position

	# 更新灼烧区域位置
	if burn_area:
		burn_area.global_position = global_position

# 创建护盾视觉效果
func create_shield_visual():
	shield_visual = Node2D.new()

	# 创建护盾圆形
	var shield_circle = Polygon2D.new()
	var points = []
	var segments = 32

	for i in range(segments):
		var angle = 2 * PI * i / segments
		var point = Vector2(cos(angle), sin(angle)) * 40  # 护盾半径
		points.append(point)

	shield_circle.polygon = points
	shield_circle.color = Color(0.2, 0.6, 1.0, 0.3)  # 半透明蓝色
	shield_visual.add_child(shield_circle)

	get_tree().current_scene.add_child(shield_visual)

# 创建灼烧区域
func create_burn_area():
	burn_area = Area2D.new()
	burn_area.collision_layer = 0
	burn_area.collision_mask = 4  # 敌人层

	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = burn_radius
	collision.shape = shape
	burn_area.add_child(collision)

	# 创建灼烧视觉效果
	var burn_visual = Polygon2D.new()
	var points = []
	var segments = 32

	for i in range(segments):
		var angle = 2 * PI * i / segments
		var point = Vector2(cos(angle), sin(angle)) * burn_radius
		points.append(point)

	burn_visual.polygon = points
	burn_visual.color = Color(1.0, 0.5, 0.0, 0.2)  # 半透明橙色
	burn_area.add_child(burn_visual)

	get_tree().current_scene.add_child(burn_area)

# 应用灼烧伤害
func apply_burn_damage():
	var enemies = []

	# 获取灼烧区域内的敌人
	for body in burn_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			enemies.append(body)

	# 对每个敌人造成灼烧伤害
	for enemy in enemies:
		enemy.take_damage(burn_damage)

		# 创建灼烧效果
		create_burn_effect(enemy.global_position)

# 创建灼烧效果
func create_burn_effect(position):
	# 使用效果管理器创建安全的粒子效果
	var EffectManager = load("res://scripts/utils/effect_manager.gd")
	var config = {
		"emitting": true,
		"one_shot": true,
		"explosiveness": 0.8,
		"amount": 10,
		"lifetime": 0.5,
		"direction": Vector2(0, -1),
		"spread": 180.0,
		"gravity": Vector2(0, 0),
		"velocity_min": 20.0,
		"velocity_max": 40.0,
		"scale": 2.0,
		"color": Color(1.0, 0.5, 0.0, 1.0)  # 橙色
	}
	var effect = EffectManager.create_safe_particles(position, config)

	effect.global_position = position
	get_tree().current_scene.add_child(effect)

	# 自动删除效果
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true
	effect.add_child(timer)

	timer.timeout.connect(func(): effect.call_deferred("queue_free"))

# 处理玩家受到伤害
func player_hit(damage):
	if shield_active and shield_amount > 0:
		# 减少护盾值而不是生命值
		shield_amount -= damage

		# 如果护盾耗尽，禁用护盾
		if shield_amount <= 0:
			shield_amount = 0
			shield_visual.visible = false
			shield_active = false

		# 返回实际造成的伤害（0，因为护盾吸收了）
		return 0

	# 如果没有护盾，返回原始伤害
	return damage

# 升级武器
func upgrade(upgrade_type):
	match upgrade_type:
		"shield":
			shield_level += 1
			shield_amount = 20 + (shield_level - 1) * 10  # 每级+10护盾

			# 重新激活护盾
			shield_visual.visible = true
			shield_active = true
		"burn_damage":
			burn_damage_level += 1
			burn_damage = 10 + (burn_damage_level - 1) * 5  # 每级+5灼烧伤害
		"burn_radius":
			burn_radius_level += 1
			burn_radius = 80 + (burn_radius_level - 1) * 20  # 每级+20灼烧范围

			# 更新灼烧区域大小
			if burn_area:
				var collision = burn_area.get_node("CollisionShape2D")
				if collision:
					var shape = collision.shape
					shape.radius = burn_radius

				# 更新视觉效果
				var visual = burn_area.get_node("Polygon2D")
				if visual:
					var points = []
					var segments = 32

					for i in range(segments):
						var angle = 2 * PI * i / segments
						var point = Vector2(cos(angle), sin(angle)) * burn_radius
						points.append(point)

					visual.polygon = points
