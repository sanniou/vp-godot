extends Node

# 效果管理器 - 用于安全地创建和管理临时视觉效果

# 单例实例
var _instance = null

# 活跃的效果列表
var active_effects = []

# 获取单例实例
static func get_instance():
	var main = Engine.get_main_loop().root.get_node_or_null("Main")
	if main:
		var effect_manager = main.get_node_or_null("EffectManager")
		if effect_manager:
			return effect_manager
	
	return null

# 创建并添加一个安全的粒子效果
static func create_safe_particles(position: Vector2, config: Dictionary = {}) -> CPUParticles2D:
	var instance = get_instance()
	if instance:
		return instance._create_safe_particles(position, config)
	
	# 如果没有实例，创建一个临时的粒子效果
	return _create_temporary_particles(position, config)

# 创建并添加一个安全的多边形效果
static func create_safe_polygon(position: Vector2, config: Dictionary = {}) -> Node2D:
	var instance = get_instance()
	if instance:
		return instance._create_safe_polygon(position, config)
	
	# 如果没有实例，创建一个临时的多边形效果
	return _create_temporary_polygon(position, config)

# 内部方法：创建安全的粒子效果
func _create_safe_particles(position: Vector2, config: Dictionary = {}) -> CPUParticles2D:
	# 创建一个容器节点
	var container = Node2D.new()
	container.name = "ParticleEffect"
	container.global_position = position
	add_child(container)
	
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.name = "Particles"
	
	# 设置基本属性
	particles.emitting = config.get("emitting", true)
	particles.one_shot = config.get("one_shot", true)
	particles.explosiveness = config.get("explosiveness", 0.8)
	particles.amount = config.get("amount", 20)
	particles.lifetime = config.get("lifetime", 0.5)
	
	# 设置发射形状
	var emission_shape = config.get("emission_shape", CPUParticles2D.EMISSION_SHAPE_SPHERE)
	particles.emission_shape = emission_shape
	if emission_shape == CPUParticles2D.EMISSION_SHAPE_SPHERE:
		particles.emission_sphere_radius = config.get("emission_radius", 10.0)
	
	# 设置方向和重力
	particles.direction = config.get("direction", Vector2(0, -1))
	particles.spread = config.get("spread", 180.0)
	particles.gravity = config.get("gravity", Vector2(0, 0))
	
	# 设置速度
	particles.initial_velocity_min = config.get("velocity_min", 30.0)
	particles.initial_velocity_max = config.get("velocity_max", 50.0)
	
	# 设置缩放 (使用 set_param 方法)
	var scale_value = config.get("scale", 3.0)
	particles.set_param_min(CPUParticles2D.PARAM_SCALE, float(scale_value))
	particles.set_param_max(CPUParticles2D.PARAM_SCALE, float(scale_value))
	
	# 设置颜色
	particles.color = config.get("color", Color(1.0, 1.0, 1.0, 0.7))
	
	# 添加到容器
	container.add_child(particles)
	
	# 添加自动清理脚本
	var script = GDScript.new()
	script.source_code = """
extends Node2D

var lifetime = 0.0
var max_lifetime = 1.0
var fade_start = 0.7

func _ready():
	max_lifetime = $Particles.lifetime + 0.5
	fade_start = $Particles.lifetime * 0.8

func _process(delta):
	lifetime += delta
	
	# 安全地检查粒子是否存在
	var particles = get_node_or_null("Particles")
	if particles:
		# 淡出效果
		if lifetime > fade_start:
			var fade_factor = 1.0 - (lifetime - fade_start) / (max_lifetime - fade_start)
			particles.modulate.a = max(0.0, fade_factor)
	
	# 当生命周期结束时销毁
	if lifetime >= max_lifetime:
		queue_free()
"""
	script.reload()
	container.set_script(script)
	
	# 添加到活跃效果列表
	active_effects.append(container)
	
	return particles

# 内部方法：创建安全的多边形效果
func _create_safe_polygon(position: Vector2, config: Dictionary = {}) -> Node2D:
	# 创建一个容器节点
	var container = Node2D.new()
	container.name = "PolygonEffect"
	container.global_position = position
	add_child(container)
	
	# 创建多边形效果
	var polygon = Polygon2D.new()
	polygon.name = "Polygon"
	
	# 设置多边形点
	var radius = config.get("radius", 30.0)
	var segments = config.get("segments", 32)
	var points = []
	
	for i in range(segments):
		var angle = 2 * PI * i / segments
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	polygon.polygon = points
	polygon.color = config.get("color", Color(1.0, 0.5, 0.0, 0.5))
	
	# 添加到容器
	container.add_child(polygon)
	
	# 添加自动清理脚本
	var script = GDScript.new()
	script.source_code = """
extends Node2D

var lifetime = 0.0
var max_lifetime = 1.0
var pulse_speed = 5.0
var rotation_speed = 1.0
var fade_start = 0.7

func _ready():
	max_lifetime = %s
	pulse_speed = %s
	rotation_speed = %s
	fade_start = max_lifetime * 0.7

func _process(delta):
	lifetime += delta
	
	# 安全地检查多边形是否存在
	var polygon = get_node_or_null("Polygon")
	if polygon:
		# 脉动效果
		var pulse = sin(lifetime * pulse_speed) * 0.1 + 0.9
		polygon.scale = Vector2(pulse, pulse)
		
		# 旋转效果
		rotation += delta * rotation_speed
		
		# 淡出效果
		if lifetime > fade_start:
			var fade_factor = 1.0 - (lifetime - fade_start) / (max_lifetime - fade_start)
			polygon.modulate.a = max(0.0, fade_factor)
	
	# 当生命周期结束时销毁
	if lifetime >= max_lifetime:
		queue_free()
""" % [
		str(config.get("lifetime", 1.0)),
		str(config.get("pulse_speed", 5.0)),
		str(config.get("rotation_speed", 1.0))
	]
	script.reload()
	container.set_script(script)
	
	# 添加到活跃效果列表
	active_effects.append(container)
	
	return container

# 静态方法：创建临时粒子效果（当管理器不可用时）
static func _create_temporary_particles(position: Vector2, config: Dictionary = {}) -> CPUParticles2D:
	# 创建一个容器节点
	var container = Node2D.new()
	container.global_position = position
	
	# 获取当前场景
	var current_scene = Engine.get_main_loop().root.get_child(0)
	current_scene.add_child(container)
	
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	
	# 设置基本属性
	particles.emitting = config.get("emitting", true)
	particles.one_shot = config.get("one_shot", true)
	particles.explosiveness = config.get("explosiveness", 0.8)
	particles.amount = config.get("amount", 20)
	particles.lifetime = config.get("lifetime", 0.5)
	
	# 设置发射形状
	var emission_shape = config.get("emission_shape", CPUParticles2D.EMISSION_SHAPE_SPHERE)
	particles.emission_shape = emission_shape
	if emission_shape == CPUParticles2D.EMISSION_SHAPE_SPHERE:
		particles.emission_sphere_radius = config.get("emission_radius", 10.0)
	
	# 设置方向和重力
	particles.direction = config.get("direction", Vector2(0, -1))
	particles.spread = config.get("spread", 180.0)
	particles.gravity = config.get("gravity", Vector2(0, 0))
	
	# 设置速度
	particles.initial_velocity_min = config.get("velocity_min", 30.0)
	particles.initial_velocity_max = config.get("velocity_max", 50.0)
	
	# 设置缩放 (使用 set_param 方法)
	var scale_value = config.get("scale", 3.0)
	particles.set_param_min(CPUParticles2D.PARAM_SCALE, float(scale_value))
	particles.set_param_max(CPUParticles2D.PARAM_SCALE, float(scale_value))
	
	# 设置颜色
	particles.color = config.get("color", Color(1.0, 1.0, 1.0, 0.7))
	
	# 添加到容器
	container.add_child(particles)
	
	# 添加自动清理计时器
	var timer = Timer.new()
	timer.wait_time = particles.lifetime + 0.5
	timer.one_shot = true
	timer.autostart = true
	container.add_child(timer)
	timer.timeout.connect(func(): container.queue_free())
	
	return particles

# 静态方法：创建临时多边形效果（当管理器不可用时）
static func _create_temporary_polygon(position: Vector2, config: Dictionary = {}) -> Node2D:
	# 创建一个容器节点
	var container = Node2D.new()
	container.global_position = position
	
	# 获取当前场景
	var current_scene = Engine.get_main_loop().root.get_child(0)
	current_scene.add_child(container)
	
	# 创建多边形效果
	var polygon = Polygon2D.new()
	
	# 设置多边形点
	var radius = config.get("radius", 30.0)
	var segments = config.get("segments", 32)
	var points = []
	
	for i in range(segments):
		var angle = 2 * PI * i / segments
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	polygon.polygon = points
	polygon.color = config.get("color", Color(1.0, 0.5, 0.0, 0.5))
	
	# 添加到容器
	container.add_child(polygon)
	
	# 添加自动清理计时器
	var timer = Timer.new()
	timer.wait_time = config.get("lifetime", 1.0)
	timer.one_shot = true
	timer.autostart = true
	container.add_child(timer)
	timer.timeout.connect(func(): container.queue_free())
	
	return container

# 清理所有活跃效果
func cleanup_effects():
	for effect in active_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	
	active_effects.clear()

# 当节点被移除时清理资源
func _exit_tree():
	cleanup_effects()
