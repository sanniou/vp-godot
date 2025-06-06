extends Area2D

# 信号
signal collected(value, source, orb)

# 经验球属性
var experience_value = 1
var move_speed = 0
var max_speed = 400
var acceleration = 800
var attraction_range = 200
var source = "default"  # 经验来源
var merge_cooldown = 0.0

# 状态
var target = null
var is_attracting = false
var can_be_collected = false
var can_be_merged = false

# 初始化
func _ready():
	# 连接信号（只在第一次连接）
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not $AttractTimer.timeout.is_connected(_on_attract_timer_timeout):
		$AttractTimer.timeout.connect(_on_attract_timer_timeout)

	# 初始状态
	monitoring = false
	monitorable = false

	# 注意：不在这里创建定时器和播放生成动画
	# 这些操作将由经验球管理器在生成经验球时处理

	# 设置初始视觉效果
	_update_visual()

# 启用碰撞检测
func _enable_collision():
	# 使用 call_deferred 来确保在物理处理外调用
	call_deferred("_safely_enable_collision")
	can_be_collected = true
	can_be_merged = true

# 安全地启用碰撞检测
func _safely_enable_collision():
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

# 处理移动和合并冷却
func _process(delta):
	# 更新合并冷却
	if merge_cooldown > 0:
		merge_cooldown -= delta

	# 处理吸引移动
	if is_attracting and target != null and is_instance_valid(target):
		# 计算方向
		var direction = (target.global_position - global_position).normalized()

		# 加速
		move_speed = min(move_speed + acceleration * delta, max_speed)

		# 移动
		global_position += direction * move_speed * delta

		# 旋转效果
		rotation += delta * move_speed * 0.01

# 设置经验值
func set_value(value):
	experience_value = value
	_update_visual()

# 更新视觉效果
func _update_visual():
	# 根据经验值调整大小
	var base_scale = 1.0
	var scale_factor = base_scale + (experience_value / 10.0)
	scale = Vector2(scale_factor, scale_factor)

	# 根据经验值调整颜色
	var visual = $OrbVisual
	if visual:
		# 基础颜色为绿色
		var base_color = Color(0.2, 0.8, 0.4, 1.0)
		var glow_color = Color(0.2, 0.8, 0.4, 0.5)
		var particle_color = Color(0.2, 0.8, 0.4, 0.5)

		# 根据价值调整颜色
		if experience_value >= 50:
			# 紫色（高价值）
			base_color = Color(0.8, 0.3, 1.0, 1.0)
			glow_color = Color(0.8, 0.3, 1.0, 0.5)
			particle_color = Color(0.8, 0.3, 1.0, 0.5)
			# 增加粒子数量
			if visual.has_node("Particles"):
				visual.get_node("Particles").amount = 24
		elif experience_value >= 20:
			# 蓝色（中高价值）
			base_color = Color(0.3, 0.5, 1.0, 1.0)
			glow_color = Color(0.3, 0.5, 1.0, 0.5)
			particle_color = Color(0.3, 0.5, 1.0, 0.5)
			# 增加粒子数量
			if visual.has_node("Particles"):
				visual.get_node("Particles").amount = 18
		elif experience_value >= 10:
			# 黄色（中价值）
			base_color = Color(1.0, 0.9, 0.3, 1.0)
			glow_color = Color(1.0, 0.9, 0.3, 0.5)
			particle_color = Color(1.0, 0.9, 0.3, 0.5)
			# 增加粒子数量
			if visual.has_node("Particles"):
				visual.get_node("Particles").amount = 16

		# 应用颜色
		if visual.has_node("Core"):
			visual.get_node("Core").color = base_color
		if visual.has_node("OuterGlow"):
			visual.get_node("OuterGlow").color = glow_color
		if visual.has_node("Particles"):
			visual.get_node("Particles").color = particle_color

# 播放生成动画
func _play_spawn_animation():
	# 初始缩放为0
	var initial_scale = scale
	scale = Vector2.ZERO

	# 创建弹出动画
	var tween = create_tween()
	tween.tween_property(self, "scale", initial_scale, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

# 开始吸引到玩家
func start_attracting(player):
	# 如果已经在吸引中，不重复设置
	if is_attracting:
		return

	target = player
	is_attracting = true

	# 应用遗物效果
	_apply_relic_effects()

	# 播放吸引动画
	_play_attract_animation()

# 应用遗物效果
func _apply_relic_effects():
	# 获取主场景
	var main = get_tree().current_scene
	if main and main.has_node("RelicManager"):
		var relic_manager = main.get_node("RelicManager")

		# 准备事件数据
		var event_data = {
			"type": "experience_orb",
			"max_speed": max_speed,
			"acceleration": acceleration
		}

		# 触发物品拾取事件
		var modified_data = relic_manager.trigger_event(6, event_data)  # 6 = ITEM_PICKUP

		# 应用修改后的数据
		if modified_data.has("max_speed"):
			max_speed = modified_data["max_speed"]

		if modified_data.has("acceleration"):
			acceleration = modified_data["acceleration"]

# 播放吸引动画
func _play_attract_animation():
	# 增加粒子数量和速度
	var visual = $OrbVisual
	if visual and visual.has_node("Particles"):
		var particles = visual.get_node("Particles")
		particles.amount *= 2
		particles.initial_velocity_min *= 1.5
		particles.initial_velocity_max *= 1.5

	# 创建闪光效果
	var flash = Node2D.new()
	visual.add_child(flash)

	# 复制核心和外光
	if visual.has_node("Core") and visual.has_node("OuterGlow"):
		var core_flash = visual.get_node("Core").duplicate()
		core_flash.color = Color(1, 1, 1, 0.8)
		flash.add_child(core_flash)

		var glow_flash = visual.get_node("OuterGlow").duplicate()
		glow_flash.color = Color(1, 1, 1, 0.5)
		flash.add_child(glow_flash)

	# 创建动画
	var tween = create_tween()
	tween.tween_property(flash, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(flash, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_callback(func(): flash.queue_free())

# 碰撞处理
func _on_body_entered(body):
	if body.is_in_group("player") and can_be_collected:
		# 发出收集信号
		collected.emit(experience_value, source, self)

		# 播放收集动画
		_play_collect_animation()

		# 禁用碰撞，防止多次触发
		monitoring = false
		monitorable = false
		can_be_collected = false

		# 注意：不再销毁经验球，而是由经验球管理器将其返回到池中

# 播放收集动画
func _play_collect_animation():
	# 增强粒子效果
	var visual = $OrbVisual
	if visual and visual.has_node("Particles"):
		var particles = visual.get_node("Particles")
		particles.amount *= 3
		particles.lifetime = 0.3
		particles.explosiveness = 0.8
		particles.initial_velocity_min *= 2.0
		particles.initial_velocity_max *= 2.0

	# 创建收集动画
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)

	# 旋转效果
	if visual:
		tween.parallel().tween_property(visual, "rotation", PI * 2, 0.3).set_ease(Tween.EASE_IN)

# 吸引计时器超时
func _on_attract_timer_timeout():
	# 查找玩家
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]

		# 应用遗物效果获取吸引范围
		var main = get_tree().current_scene
		if main and main.has_node("RelicManager"):
			var relic_manager = main.get_node("RelicManager")

			# 准备事件数据
			var event_data = {
				"type": "experience_orb",
				"attraction_range": attraction_range
			}

			# 触发物品拾取事件
			var modified_data = relic_manager.trigger_event(6, event_data)  # 6 = ITEM_PICKUP

			# 获取修改后的吸引范围
			if modified_data.has("attraction_range"):
				attraction_range = modified_data["attraction_range"]

		# 检查玩家是否在吸引范围内
		var distance = global_position.distance_to(player.global_position)
		if distance <= attraction_range:
			start_attracting(player)
