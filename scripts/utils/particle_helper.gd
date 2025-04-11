extends Node

# 粒子辅助工具 - 用于处理粒子效果的兼容性问题

# 设置粒子缩放
static func set_particle_scale(particles: CPUParticles2D, scale_value: float) -> void:
	# 在 Godot 4 中，使用 set_param 方法设置粒子缩放
	particles.set_param_min(CPUParticles2D.PARAM_SCALE, scale_value)
	particles.set_param_max(CPUParticles2D.PARAM_SCALE, scale_value)

# 设置粒子随机缩放
static func set_particle_random_scale(particles: CPUParticles2D, min_scale: float, max_scale: float) -> void:
	particles.set_param_min(CPUParticles2D.PARAM_SCALE, min_scale)
	particles.set_param_max(CPUParticles2D.PARAM_SCALE, max_scale)

# 创建通用的击中效果
static func create_hit_effect(position: Vector2, color: Color = Color(1.0, 1.0, 1.0, 0.7), scale: float = 3.0) -> CPUParticles2D:
	var effect = CPUParticles2D.new()
	effect.emitting = true
	effect.one_shot = true
	effect.explosiveness = 0.8
	effect.amount = 10
	effect.lifetime = 0.3
	effect.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	effect.emission_sphere_radius = 5
	effect.direction = Vector2(0, 0)
	effect.spread = 180
	effect.gravity = Vector2(0, 0)
	effect.initial_velocity_min = 30
	effect.initial_velocity_max = 50
	
	# 使用兼容的方式设置缩放
	set_particle_scale(effect, scale)
	
	effect.color = color
	effect.global_position = position
	
	# 添加自动清理
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true
	effect.add_child(timer)
	timer.timeout.connect(func(): effect.queue_free())
	
	return effect

# 创建通用的爆炸效果
static func create_explosion_effect(position: Vector2, color: Color = Color(1.0, 0.5, 0.0, 1.0), scale: float = 3.0, amount: int = 30) -> CPUParticles2D:
	var effect = CPUParticles2D.new()
	effect.emitting = true
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.amount = amount
	effect.lifetime = 0.5
	effect.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	effect.emission_sphere_radius = 10
	effect.direction = Vector2(0, 0)
	effect.spread = 180
	effect.gravity = Vector2(0, 0)
	effect.initial_velocity_min = 50
	effect.initial_velocity_max = 100
	
	# 使用兼容的方式设置缩放
	set_particle_scale(effect, scale)
	
	effect.color = color
	effect.global_position = position
	
	# 添加自动清理
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true
	effect.add_child(timer)
	timer.timeout.connect(func(): effect.queue_free())
	
	return effect
