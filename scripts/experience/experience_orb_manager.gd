extends Node

# 经验球管理器 - 处理经验球的生成、合并和收集

# 信号
signal orb_spawned(orb, position, value)
signal orb_collected(orb, value)
signal orb_merged(orb1, orb2, new_orb)

# 经验球配置
var config = {
	"base_value": 1,  # 基础经验值
	"base_attraction_range": 200,  # 基础吸引范围
	"base_max_speed": 400,  # 基础最大速度
	"base_acceleration": 800,  # 基础加速度
	"merge_enabled": true,  # 是否启用经验球合并
	"merge_range": 50,  # 合并范围
	"merge_max_value": 100,  # 单个经验球最大值
	"merge_cooldown": 0.5,  # 合并冷却时间
	"visual_scale_factor": 0.1,  # 视觉缩放因子
	"spawn_offset_range": 20,  # 生成位置偏移范围
	"pool_size": 100,  # 对象池大小
	"pool_expansion_size": 20,  # 池扩展大小
	"max_pool_size": 300,  # 最大池大小
	"auto_merge_threshold": 150,  # 自动合并阈值（当活跃经验球超过这个数量时强制合并）
	"debug_mode": false  # 调试模式
}

# 经验球场景
var experience_orb_scene = preload("res://scenes/experience_orb.tscn")

# 活跃的经验球
var active_orbs = []

# 经验球对象池
var orb_pool = []

# 池统计信息
var pool_stats = {
	"created": 0,  # 创建的经验球总数
	"reused": 0,  # 重用的经验球数量
	"active_peak": 0,  # 活跃经验球峰值
	"forced_merges": 0  # 强制合并次数
}

# 主场景引用
var main_scene = null

# 经验管理器引用
var experience_manager = null

# 容器节点
var container_node = null

# 初始化
func _init(main_ref = null, exp_manager = null):
	main_scene = main_ref
	experience_manager = exp_manager

	# 创建容器节点
	_create_container_node()

	# 初始化对象池
	_initialize_pool()

# 创建容器节点
func _create_container_node():
	# 创建一个专用容器节点来存放所有经验球
	container_node = Node2D.new()
	container_node.name = "ExperienceOrbPool"

	# 添加到场景
	if main_scene and main_scene.has_node("GameWorld"):
		main_scene.get_node("GameWorld").add_child(container_node)
	else:
		# 如果主场景不可用，延迟添加
		call_deferred("_add_container_to_scene")

# 延迟添加容器到场景
func _add_container_to_scene():
	if not container_node.is_inside_tree():
		get_tree().current_scene.add_child(container_node)

# 初始化对象池
func _initialize_pool():
	# 预创建经验球对象
	for i in range(config.pool_size):
		_create_orb_for_pool()

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 初始化对象池，大小: %d" % [config.pool_size])

# 为池创建经验球
func _create_orb_for_pool():
	# 创建新经验球
	var orb = experience_orb_scene.instantiate()

	# 设置初始状态
	orb.set_process(false)
	orb.visible = false
	orb.monitoring = false
	orb.monitorable = false

	# 连接信号
	orb.collected.connect(_on_orb_collected)

	# 添加到容器
	if container_node:
		container_node.add_child(orb)
	else:
		# 如果容器不可用，添加到场景
		if main_scene and main_scene.has_node("GameWorld"):
			main_scene.get_node("GameWorld").add_child(orb)
		else:
			get_tree().current_scene.add_child(orb)

	# 添加到池中
	orb_pool.append(orb)

	# 更新统计信息
	pool_stats.created += 1

	return orb

# 处理经验球合并
func _process(delta):
	# 更新活跃经验球峰值
	pool_stats.active_peak = max(pool_stats.active_peak, active_orbs.size())

	# 如果不启用合并或活跃经验球少于2个，直接返回
	if not config.merge_enabled or active_orbs.size() < 2:
		return

	# 检查是否需要强制合并
	var force_merge = active_orbs.size() > config.auto_merge_threshold
	if force_merge and config.debug_mode:
		print("经验球管理器: 活跃经验球数量(%d)超过阈值(%d)，强制合并" % [active_orbs.size(), config.auto_merge_threshold])
		pool_stats.forced_merges += 1

	# 检查经验球合并
	var orbs_to_merge = {}
	var orbs_to_remove = []

	# 查找可以合并的经验球
	for i in range(active_orbs.size()):
		var orb1 = active_orbs[i]

		# 跳过无效的经验球
		if not is_instance_valid(orb1) or orb1.is_queued_for_deletion():
			orbs_to_remove.append(orb1)
			continue

		# 跳过已经在合并列表中的经验球
		if orb1 in orbs_to_merge:
			continue

		# 跳过已经达到最大值的经验球
		if orb1.experience_value >= config.merge_max_value:
			continue

		# 如果不是强制合并，跳过正在被吸引的经验球
		if not force_merge and orb1.is_attracting:
			continue

		# 查找附近可以合并的经验球
		for j in range(i + 1, active_orbs.size()):
			var orb2 = active_orbs[j]

			# 跳过无效的经验球
			if not is_instance_valid(orb2) or orb2.is_queued_for_deletion():
				orbs_to_remove.append(orb2)
				continue

			# 跳过已经在合并列表中的经验球
			if orb2 in orbs_to_merge:
				continue

			# 如果不是强制合并，跳过正在被吸引的经验球
			if not force_merge and orb2.is_attracting:
				continue

			# 如果是强制合并，不检查距离
			if force_merge:
				# 将这两个经验球添加到合并列表
				orbs_to_merge[orb1] = orb2
				break
			else:
				# 检查距离
				var distance = orb1.global_position.distance_to(orb2.global_position)
				if distance <= config.merge_range:
					# 将这两个经验球添加到合并列表
					orbs_to_merge[orb1] = orb2
					break

	# 移除无效的经验球
	for orb in orbs_to_remove:
		active_orbs.erase(orb)

	# 合并经验球
	for orb1 in orbs_to_merge:
		var orb2 = orbs_to_merge[orb1]

		# 确保两个经验球都有效
		if is_instance_valid(orb1) and is_instance_valid(orb2) and not orb1.is_queued_for_deletion() and not orb2.is_queued_for_deletion():
			merge_orbs(orb1, orb2)

# 生成经验球
func spawn_experience_orb(position, value = config.base_value, source = "default"):
	# 添加随机偏移
	var offset = Vector2(
		randf_range(-config.spawn_offset_range, config.spawn_offset_range),
		randf_range(-config.spawn_offset_range, config.spawn_offset_range)
	)
	var spawn_position = position + offset

	# 从对象池中获取经验球
	var orb = _get_orb_from_pool()

	# 设置经验球属性
	orb.global_position = spawn_position
	orb.set_value(value)
	orb.set("source", source)  # 使用 set 方法设置 source

	# 激活经验球
	orb.set_process(true)
	orb.visible = true
	orb.set_deferred("monitoring", false)  # 初始不启用碰撞，由经验球自身在定时器后启用
	orb.set_deferred("monitorable", false)
	# 使用属性设置方法而不是直接设置
	orb.set("can_be_collected", false)
	orb.set("can_be_merged", false)

	# 重置经验球状态
	orb.is_attracting = false
	orb.target = null
	orb.set("merge_cooldown", 0.0)  # 使用 set 方法设置 merge_cooldown

	# 添加到活跃经验球列表
	active_orbs.append(orb)

	# 手动创建生成动画，而不是调用内部方法
	# 初始缩放为0
	var initial_scale = orb.scale
	orb.scale = Vector2.ZERO

	# 创建弹出动画
	var tween = create_tween()
	tween.tween_property(orb, "scale", initial_scale, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# 创建定时器在一段时间后启用碰撞
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func():
		# 检查经验球是否有效
		if is_instance_valid(orb) and not orb.is_queued_for_deletion():
			# 安全地启用碰撞
			orb.set_deferred("monitoring", true)
			orb.set_deferred("monitorable", true)
			orb.set("can_be_collected", true)
			orb.set("can_be_merged", true)
	)

	# 发出信号
	orb_spawned.emit(orb, spawn_position, value)

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 生成经验球，位置: %s, 价值: %d, 来源: %s" % [spawn_position, value, source])

	return orb

# 从对象池中获取经验球
func _get_orb_from_pool():
	# 如果池中有可用的经验球，返回它
	for orb in orb_pool:
		if is_instance_valid(orb) and not orb.visible and not orb.is_queued_for_deletion():
			# 更新统计信息
			pool_stats.reused += 1
			return orb

	# 如果池中没有可用的经验球，扩展池
	if orb_pool.size() < config.max_pool_size:
		# 扩展池
		var expansion_size = min(config.pool_expansion_size, config.max_pool_size - orb_pool.size())

		# 调试输出
		if config.debug_mode:
			print("经验球管理器: 池中没有可用的经验球，扩展池大小: %d" % [expansion_size])

		# 创建新经验球
		for i in range(expansion_size):
			_create_orb_for_pool()

		# 返回最后创建的经验球
		return orb_pool[orb_pool.size() - 1]

	# 如果池已达到最大大小，尝试强制回收一些经验球
	if active_orbs.size() > 0:
		# 强制回收最早生成的经验球
		var oldest_orb = active_orbs[0]

		# 从活跃列表中移除
		active_orbs.erase(oldest_orb)

		# 重置经验球状态
		_reset_orb(oldest_orb)

		# 调试输出
		if config.debug_mode:
			print("经验球管理器: 池已满，强制回收最早的经验球")

		return oldest_orb

	# 如果没有可用的经验球，创建一个新的（应急措施）
	var new_orb = _create_orb_for_pool()

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 所有措施失败，创建新经验球")

	return new_orb

# 重置经验球状态
func _reset_orb(orb):
	# 重置经验球状态
	orb.set_process(false)
	orb.visible = false
	orb.set_deferred("monitoring", false)
	orb.set_deferred("monitorable", false)
	# 使用属性设置方法而不是直接设置
	orb.set("can_be_collected", false)
	orb.set("can_be_merged", false)
	orb.is_attracting = false
	orb.target = null
	orb.set("merge_cooldown", 0.0)  # 使用 set 方法设置 merge_cooldown
	orb.set("experience_value", 1)  # 重置经验值
	orb.modulate = Color(1, 1, 1, 1)  # 重置颜色
	orb.scale = Vector2(1, 1)  # 重置缩放

# 合并两个经验球
func merge_orbs(orb1, orb2):
	# 计算合并后的经验值
	var merged_value = orb1.experience_value + orb2.experience_value
	merged_value = min(merged_value, config.merge_max_value)

	# 计算合并位置（两个经验球的中点）
	var merged_position = (orb1.global_position + orb2.global_position) / 2

	# 从活跃列表中移除旧经验球
	active_orbs.erase(orb1)
	active_orbs.erase(orb2)

	# 将旧经验球返回到池中
	_return_orb_to_pool(orb1)
	_return_orb_to_pool(orb2)

	# 生成新的合并经验球
	var new_orb = spawn_experience_orb(merged_position, merged_value, "merged")

	# 添加合并视觉效果
	_add_merge_effect(new_orb)

	# 发出信号
	orb_merged.emit(orb1, orb2, new_orb)

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 合并经验球，新价值: %d, 位置: %s" % [merged_value, merged_position])

	return new_orb

# 添加合并视觉效果
func _add_merge_effect(orb):
	# 创建闪光效果
	var flash = Sprite2D.new()

	# 安全地获取纹理
	var sprite = orb.get_node_or_null("Sprite2D")
	if sprite and is_instance_valid(sprite) and sprite.texture:
		flash.texture = sprite.texture
	else:
		# 使用默认纹理
		# 不使用 preload，因为我们不确定纹理路径
		# 直接创建一个空纹理
		var image = Image.new()
		image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color(1, 1, 1, 1))

		var default_texture = ImageTexture.create_from_image(image)
		flash.texture = default_texture

	flash.modulate = Color(1, 1, 1, 0.8)
	flash.scale = Vector2(1.5, 1.5)

	# 使用 call_deferred 安全地添加子节点
	call_deferred("_safely_add_child", orb, flash)

	# 创建动画（在下一帧执行，确保子节点已添加）
	call_deferred("_create_flash_animation", orb, flash)

# 安全地添加子节点
func _safely_add_child(parent, child):
	if is_instance_valid(parent) and not parent.is_queued_for_deletion() and is_instance_valid(child):
		parent.add_child(child)

# 创建闪光动画
func _create_flash_animation(orb, flash):
	if is_instance_valid(orb) and not orb.is_queued_for_deletion() and is_instance_valid(flash):
		var tween = orb.create_tween()
		tween.tween_property(flash, "scale", Vector2(2.5, 2.5), 0.3)
		tween.parallel().tween_property(flash, "modulate", Color(1, 1, 1, 0), 0.3)
		tween.tween_callback(func(): if is_instance_valid(flash): flash.queue_free())

# 收集所有经验球
func collect_all_orbs():
	var collected_count = 0

	# 复制列表，因为我们会在迭代过程中修改它
	var orbs_to_collect = active_orbs.duplicate()

	# 收集所有经验球
	for orb in orbs_to_collect:
		if is_instance_valid(orb) and not orb.is_queued_for_deletion():
			# 找到玩家
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				var player = players[0]

				# 开始吸引
				orb.start_attracting(player)
				collected_count += 1

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 收集所有经验球，数量: %d" % [collected_count])

	return collected_count

# 生成经验球爆发
func spawn_experience_burst(position, total_value, orb_count, radius = 100, source = "burst"):
	var orbs = []

	# 计算每个经验球的价值
	var value_per_orb = max(1, int(total_value / orb_count))
	var remaining_value = total_value

	# 生成经验球
	for i in range(orb_count):
		# 计算最后一个经验球的价值（确保总和正确）
		var orb_value = value_per_orb
		if i == orb_count - 1:
			orb_value = remaining_value

		# 计算随机位置
		var angle = randf() * TAU
		var distance = randf() * radius
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var spawn_position = position + offset

		# 生成经验球
		var orb = spawn_experience_orb(spawn_position, orb_value, source)
		orbs.append(orb)

		# 更新剩余价值
		remaining_value -= orb_value

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 生成经验爆发，总价值: %d, 数量: %d, 位置: %s" % [total_value, orb_count, position])

	return orbs

# 更新经验球配置
func update_config(new_config):
	# 更新配置
	for key in new_config:
		if config.has(key):
			config[key] = new_config[key]

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 更新配置")

# 清理所有经验球
func clear_all_orbs():
	# 复制列表，因为我们会在迭代过程中修改它
	var orbs_to_clear = active_orbs.duplicate()

	# 将所有经验球返回到池中
	for orb in orbs_to_clear:
		if is_instance_valid(orb) and not orb.is_queued_for_deletion():
			_return_orb_to_pool(orb)

	# 清空活跃列表
	active_orbs.clear()

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 清理所有经验球")

# 重置经验球管理器
func reset():
	# 清理所有活跃经验球
	clear_all_orbs()

	# 重置配置
	config = {
		"base_value": 1,
		"base_attraction_range": 200,
		"base_max_speed": 400,
		"base_acceleration": 800,
		"merge_enabled": true,
		"merge_range": 50,
		"merge_max_value": 100,
		"merge_cooldown": 0.5,
		"visual_scale_factor": 0.1,
		"spawn_offset_range": 20,
		"pool_size": 100,
		"pool_expansion_size": 20,
		"max_pool_size": 300,
		"auto_merge_threshold": 150,
		"debug_mode": false
	}

	# 重置池统计信息
	reset_pool_stats()

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 重置")

# 将经验球返回到池中
func _return_orb_to_pool(orb):
	# 检查经验球是否有效
	if not is_instance_valid(orb) or orb.is_queued_for_deletion():
		return

	# 重置经验球状态
	_reset_orb(orb)

	# 从活跃列表中移除（如果存在）
	if orb in active_orbs:
		active_orbs.erase(orb)

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 将经验球返回到池中")

# 经验球收集回调
func _on_orb_collected(value, source, orb, _extra_arg = null):
	# 检查经验球是否有效
	if not is_instance_valid(orb) or orb.is_queued_for_deletion():
		return

	# 从活跃列表中移除
	if orb in active_orbs:
		active_orbs.erase(orb)

	# 添加经验
	if experience_manager:
		experience_manager.add_experience(value, source)

	# 发出信号
	orb_collected.emit(orb, value)

	# 在动画完成后将经验球返回到池中
	await get_tree().create_timer(0.3).timeout
	_return_orb_to_pool(orb)

	# 调试输出
	if config.debug_mode:
		print("经验球管理器: 收集经验球，价值: %d, 来源: %s" % [value, source])

# 安全地连接信号
func _safely_connect_signal(orb):
	if is_instance_valid(orb) and not orb.is_queued_for_deletion():
		# 检查信号是否已经连接
		if not orb.collected.is_connected(_on_orb_collected):
			orb.collected.connect(_on_orb_collected)

# 获取调试信息
func get_debug_info():
	var info = {
		"active_orbs_count": active_orbs.size(),
		"pool_size": orb_pool.size(),
		"pool_stats": pool_stats.duplicate(),
		"config": config.duplicate(),
		"memory_usage": {
			"total_orbs": orb_pool.size(),
			"active_orbs": active_orbs.size(),
			"inactive_orbs": orb_pool.size() - active_orbs.size(),
			"reuse_ratio": pool_stats.reused / max(1, pool_stats.created) * 100.0
		}
	}

	return info

# 重置池统计信息
func reset_pool_stats():
	pool_stats = {
		"created": 0,
		"reused": 0,
		"active_peak": 0,
		"forced_merges": 0
	}
