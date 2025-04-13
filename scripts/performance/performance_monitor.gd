extends Node
class_name PerformanceMonitor

# 注意：GDScript 中不支持在类内部使用类名的静态方法
# 所以我们不使用静态方法，而是直接在 main.gd 中创建实例

# 性能监控器 - 用于监控游戏性能并动态调整游戏参数

# 性能指标
var fps_history = []
var fps_history_max_size = 60  # 保存最近60帧的FPS
var physics_history = []
var physics_history_max_size = 60  # 保存最近60帧的物理处理时间

# 性能目标
var target_fps = 60
var min_acceptable_fps = 30

# 调整参数
var adjustment_interval = 5.0  # 每5秒调整一次
var adjustment_timer = 0.0
var last_adjustment_time = 0.0

# 敌人数量限制
var max_enemies = 100  # 默认最大敌人数量
var min_enemies = 20   # 最小敌人数量
var enemies_step = 10  # 每次调整的敌人数量

# 对象池大小
var max_pool_size = 300  # 默认最大池大小
var min_pool_size = 50   # 最小池大小
var pool_step = 20       # 每次调整的池大小

# 调试模式
var debug_mode = false

# 初始化
func _ready():
	# 设置进程模式，确保在暂停时也能工作
	process_mode = Node.PROCESS_MODE_ALWAYS

# 处理每一帧
func _process(delta):
	# 收集性能数据
	collect_performance_data()

	# 定期调整游戏参数
	adjustment_timer += delta
	if adjustment_timer >= adjustment_interval:
		adjustment_timer = 0.0
		adjust_game_parameters()

# 收集性能数据
func collect_performance_data():
	# 收集FPS
	var current_fps = Engine.get_frames_per_second()
	fps_history.append(current_fps)
	if fps_history.size() > fps_history_max_size:
		fps_history.pop_front()

	# 收集物理处理时间
	var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	physics_history.append(physics_time)
	if physics_history.size() > physics_history_max_size:
		physics_history.pop_front()

# 获取平均FPS
func get_average_fps() -> float:
	if fps_history.size() == 0:
		return target_fps

	var sum = 0.0
	for fps in fps_history:
		sum += fps

	return sum / fps_history.size()

# 获取平均物理处理时间
func get_average_physics_time() -> float:
	if physics_history.size() == 0:
		return 0.0

	var sum = 0.0
	for time in physics_history:
		sum += time

	return sum / physics_history.size()

# 调整游戏参数
func adjust_game_parameters():
	# 获取平均FPS
	var avg_fps = get_average_fps()

	# 获取平均物理处理时间
	var avg_physics_time = get_average_physics_time()

	# 获取敌人生成器
	var enemy_spawner = _get_enemy_spawner()

	# 获取经验球管理器
	var orb_manager = _get_experience_orb_manager()

	# 如果FPS低于目标，减少敌人数量和池大小
	if avg_fps < min_acceptable_fps:
		# 大幅减少敌人数量
		if enemy_spawner and enemy_spawner.has("max_enemies"):
			enemy_spawner.max_enemies = max(min_enemies, enemy_spawner.max_enemies - enemies_step * 2)

		# 减少经验球池大小
		if orb_manager and orb_manager.has("config"):
			orb_manager.config.pool_size = max(min_pool_size, orb_manager.config.pool_size - pool_step * 2)
			orb_manager.config.max_pool_size = max(min_pool_size * 2, orb_manager.config.max_pool_size - pool_step * 2)

		if debug_mode:
			print("性能监控器: FPS过低 (%d)，大幅减少游戏参数" % avg_fps)

	# 如果FPS低于目标但可接受，小幅减少敌人数量
	elif avg_fps < target_fps * 0.9:
		# 小幅减少敌人数量
		if enemy_spawner and enemy_spawner.has("max_enemies"):
			enemy_spawner.max_enemies = max(min_enemies, enemy_spawner.max_enemies - enemies_step)

		if debug_mode:
			print("性能监控器: FPS略低 (%d)，小幅减少敌人数量" % avg_fps)

	# 如果FPS高于目标，增加敌人数量
	elif avg_fps > target_fps * 1.1 and avg_physics_time < 1.0/target_fps * 0.5:
		# 增加敌人数量
		if enemy_spawner and enemy_spawner.has("max_enemies"):
			enemy_spawner.max_enemies = min(max_enemies, enemy_spawner.max_enemies + enemies_step)

		# 增加经验球池大小
		if orb_manager and orb_manager.has("config"):
			orb_manager.config.pool_size = min(max_pool_size, orb_manager.config.pool_size + pool_step)
			orb_manager.config.max_pool_size = min(max_pool_size * 2, orb_manager.config.max_pool_size + pool_step)

		if debug_mode:
			print("性能监控器: FPS良好 (%d)，增加游戏参数" % avg_fps)

	# 记录调整时间
	last_adjustment_time = Time.get_ticks_msec() / 1000.0

# 获取敌人生成器
func _get_enemy_spawner():
	var main = get_tree().get_root().get_node_or_null("Main")
	if main:
		return main.get_node_or_null("EnemySpawner")
	return null

# 获取经验球管理器
func _get_experience_orb_manager():
	var main = get_tree().get_root().get_node_or_null("Main")
	if main:
		return main.get_node_or_null("ExperienceOrbManager")
	return null

# 获取性能报告
func get_performance_report() -> String:
	var report = "性能监控报告:\n"
	report += "当前FPS: " + str(Engine.get_frames_per_second()) + "\n"
	report += "平均FPS: " + str(get_average_fps()).pad_decimals(1) + "\n"
	report += "物理处理时间: " + str(get_average_physics_time() * 1000).pad_decimals(2) + " ms\n"

	# 获取敌人数量
	var enemies = get_tree().get_nodes_in_group("enemies")
	report += "敌人数量: " + str(enemies.size()) + "\n"

	# 获取敌人生成器信息
	var enemy_spawner = _get_enemy_spawner()
	if enemy_spawner and enemy_spawner.has("max_enemies"):
		report += "最大敌人数量: " + str(enemy_spawner.max_enemies) + "\n"

	# 获取经验球管理器信息
	var orb_manager = _get_experience_orb_manager()
	if orb_manager:
		var stats = orb_manager.get_debug_info()
		report += "活跃经验球: " + str(stats.active_orbs_count) + "\n"
		report += "经验球池大小: " + str(stats.pool_size) + "\n"

	# 获取内存使用情况
	var memory_static = Performance.get_monitor(Performance.MEMORY_STATIC)
	# 注意：Godot 4.4.1 中不再使用 MEMORY_DYNAMIC
	# 改用总内存和静态内存的差值作为动态内存的估计值
	var total_memory = OS.get_static_memory_usage()
	var memory_dynamic = total_memory - memory_static
	report += "静态内存: " + str(memory_static / 1024 / 1024).pad_decimals(2) + " MB\n"
	report += "动态内存: " + str(memory_dynamic / 1024 / 1024).pad_decimals(2) + " MB\n"

	# 获取对象数量
	var object_count = Performance.get_monitor(Performance.OBJECT_COUNT)
	report += "对象数量: " + str(object_count) + "\n"

	# 获取节点数量
	var node_count = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	report += "节点数量: " + str(node_count) + "\n"

	# 获取资源数量
	var resource_count = Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	report += "资源数量: " + str(resource_count) + "\n"

	# 获取最后调整时间
	report += "最后调整时间: " + str(last_adjustment_time).pad_decimals(1) + " 秒前\n"

	return report
