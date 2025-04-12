extends Node

# 经验管理器 - 处理所有与经验相关的功能

# 信号
signal experience_gained(amount, total, source)
signal level_up(new_level, overflow_exp)
signal experience_multiplier_changed(new_multiplier)

# 经验系统配置
var config = {
	"base_exp_to_level": 100,  # 基础升级所需经验
	"level_scaling_type": "exponential",  # 升级曲线类型: linear, exponential, custom
	"level_scaling_factor": 1.2,  # 每级增加的经验倍数
	"max_level": 99,  # 最大等级
	"exp_overflow_enabled": true,  # 是否允许经验溢出到下一级
	"exp_overflow_penalty": 0.0,  # 经验溢出惩罚 (0.0 表示没有惩罚)
	"exp_sources_enabled": true,  # 是否启用经验来源跟踪
	"debug_mode": false  # 调试模式
}

# 经验状态
var current_experience = 0
var current_level = 1
var experience_to_level = 100
var experience_multiplier = 1.0
var experience_sources = {}  # 跟踪不同来源的经验

# 临时经验加成
var temporary_multipliers = {}  # 格式: { "id": { "value": 1.2, "duration": 10.0, "remaining": 10.0 } }

# 主场景引用
var main_scene = null

# 初始化
func _init(main_ref = null):
	main_scene = main_ref
	experience_to_level = config.base_exp_to_level

# 处理临时经验加成
func _process(delta):
	var keys_to_remove = []
	var multiplier_changed = false
	
	# 更新所有临时加成的剩余时间
	for id in temporary_multipliers:
		var multiplier_data = temporary_multipliers[id]
		multiplier_data.remaining -= delta
		
		# 如果加成已过期，标记为移除
		if multiplier_data.remaining <= 0:
			keys_to_remove.append(id)
			multiplier_changed = true
	
	# 移除过期的加成
	for id in keys_to_remove:
		temporary_multipliers.erase(id)
	
	# 如果有加成变化，重新计算总乘数
	if multiplier_changed:
		_recalculate_experience_multiplier()

# 添加经验
func add_experience(amount, source = "default"):
	# 应用经验乘数
	var modified_amount = int(amount * experience_multiplier)
	
	# 记录经验来源
	if config.exp_sources_enabled:
		if not experience_sources.has(source):
			experience_sources[source] = 0
		experience_sources[source] += modified_amount
	
	# 更新总经验
	current_experience += modified_amount
	
	# 发出经验获取信号
	experience_gained.emit(modified_amount, current_experience, source)
	
	# 调试输出
	if config.debug_mode:
		print("经验管理器: 获得 %d 经验 (来源: %s), 总经验: %d, 升级所需: %d" % 
			[modified_amount, source, current_experience, experience_to_level])
	
	# 检查是否可以升级
	check_level_up()
	
	return modified_amount

# 检查是否可以升级
func check_level_up():
	# 如果已达到最大等级，不再升级
	if current_level >= config.max_level:
		# 限制经验值不超过当前等级所需经验
		current_experience = min(current_experience, experience_to_level)
		return false
	
	# 如果经验足够升级
	if current_experience >= experience_to_level:
		# 计算溢出经验
		var overflow_exp = current_experience - experience_to_level
		
		# 应用溢出惩罚（如果启用）
		if config.exp_overflow_enabled and config.exp_overflow_penalty > 0:
			overflow_exp = int(overflow_exp * (1.0 - config.exp_overflow_penalty))
		
		# 升级
		current_level += 1
		
		# 计算新的升级所需经验
		calculate_next_level_exp()
		
		# 重置当前经验
		if config.exp_overflow_enabled:
			current_experience = overflow_exp
		else:
			current_experience = 0
		
		# 发出升级信号
		level_up.emit(current_level, overflow_exp)
		
		# 调试输出
		if config.debug_mode:
			print("经验管理器: 升级到 %d 级! 溢出经验: %d, 下一级所需: %d" % 
				[current_level, overflow_exp, experience_to_level])
		
		# 递归检查是否可以再次升级（处理连续升级）
		if current_experience >= experience_to_level:
			check_level_up()
		
		return true
	
	return false

# 计算下一级所需经验
func calculate_next_level_exp():
	match config.level_scaling_type:
		"linear":
			# 线性增长: base + (level * factor)
			experience_to_level = config.base_exp_to_level + int(current_level * config.base_exp_to_level * (config.level_scaling_factor - 1.0))
		"exponential":
			# 指数增长: base * (factor ^ level)
			experience_to_level = int(config.base_exp_to_level * pow(config.level_scaling_factor, current_level - 1))
		"custom":
			# 自定义公式，可以在子类中重写
			experience_to_level = _custom_level_exp_formula(current_level)
	
	return experience_to_level

# 自定义升级经验公式（可重写）
func _custom_level_exp_formula(level):
	# 默认实现：二次方增长
	return int(config.base_exp_to_level * (1 + 0.5 * level * level))

# 添加临时经验加成
func add_temporary_multiplier(id, value, duration):
	temporary_multipliers[id] = {
		"value": value,
		"duration": duration,
		"remaining": duration
	}
	
	_recalculate_experience_multiplier()
	
	# 调试输出
	if config.debug_mode:
		print("经验管理器: 添加临时经验加成 %s: x%f, 持续 %f 秒" % [id, value, duration])
	
	return true

# 移除临时经验加成
func remove_temporary_multiplier(id):
	if temporary_multipliers.has(id):
		temporary_multipliers.erase(id)
		_recalculate_experience_multiplier()
		
		# 调试输出
		if config.debug_mode:
			print("经验管理器: 移除临时经验加成 %s" % [id])
		
		return true
	
	return false

# 重新计算总经验乘数
func _recalculate_experience_multiplier():
	var new_multiplier = 1.0
	
	# 应用所有临时加成
	for id in temporary_multipliers:
		new_multiplier *= temporary_multipliers[id].value
	
	# 如果乘数发生变化，更新并发出信号
	if new_multiplier != experience_multiplier:
		experience_multiplier = new_multiplier
		experience_multiplier_changed.emit(experience_multiplier)
		
		# 调试输出
		if config.debug_mode:
			print("经验管理器: 经验乘数更新为 x%f" % [experience_multiplier])

# 设置等级（用于调试或特殊情况）
func set_level(level, keep_overflow = false):
	# 确保等级在有效范围内
	level = clamp(level, 1, config.max_level)
	
	# 如果等级没有变化，直接返回
	if level == current_level:
		return
	
	# 保存当前经验（用于溢出）
	var overflow_exp = 0
	if keep_overflow:
		overflow_exp = current_experience
	
	# 设置新等级
	current_level = level
	
	# 计算新的升级所需经验
	calculate_next_level_exp()
	
	# 重置当前经验
	if keep_overflow:
		current_experience = min(overflow_exp, experience_to_level - 1)
	else:
		current_experience = 0
	
	# 调试输出
	if config.debug_mode:
		print("经验管理器: 设置等级为 %d, 当前经验: %d, 升级所需: %d" % 
			[current_level, current_experience, experience_to_level])

# 获取当前等级进度（0.0 到 1.0）
func get_level_progress():
	return float(current_experience) / experience_to_level

# 获取经验来源统计
func get_experience_sources():
	return experience_sources.duplicate()

# 重置经验系统
func reset():
	current_experience = 0
	current_level = 1
	experience_to_level = config.base_exp_to_level
	experience_multiplier = 1.0
	experience_sources.clear()
	temporary_multipliers.clear()
	
	# 调试输出
	if config.debug_mode:
		print("经验管理器: 重置经验系统")

# 更新配置
func update_config(new_config):
	# 更新配置
	for key in new_config:
		if config.has(key):
			config[key] = new_config[key]
	
	# 重新计算升级所需经验
	calculate_next_level_exp()
	
	# 调试输出
	if config.debug_mode:
		print("经验管理器: 更新配置")

# 获取调试信息
func get_debug_info():
	var info = {
		"current_level": current_level,
		"current_experience": current_experience,
		"experience_to_level": experience_to_level,
		"progress": get_level_progress(),
		"experience_multiplier": experience_multiplier,
		"temporary_multipliers": temporary_multipliers.duplicate(),
		"experience_sources": experience_sources.duplicate(),
		"config": config.duplicate()
	}
	
	return info
