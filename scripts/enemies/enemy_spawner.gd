extends Node2D
class_name EnemySpawner

# 预加载类
const EnemyFactory = preload("res://scripts/enemies/enemy_factory.gd")
const HealthBarClass = preload("res://scripts/ui/health_bar.gd")

# 敌人类型
enum EnemyType {
    BASIC,      # 基本敌人（近战）
    RANGED,     # 远程敌人
    ELITE,      # 精英敌人
    BOSS        # Boss敌人
}

# 敌人生成器
var enemy_factory = null

# Load scenes in _ready to avoid preload errors
# Spawn settings
var spawn_radius = 800  # Distance from player to spawn enemies
var min_spawn_distance = 400  # Minimum distance from player
var max_enemies = 100  # Maximum number of enemies at once
var difficulty = 0  # Increases over time

# 遗物效果修改器
var enemy_speed_modifier = 0.0  # 敌人速度修改器，负值减速，正值加速

# References
var player = null

func _ready():
	# 初始化敌人工厂
	enemy_factory = EnemyFactory.new()

	# 查找玩家
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# 在玩家周围随机位置生成敌人
func spawn_enemy():
	# print("EnemySpawner: spawn_enemy called, player: ", player)
	if player == null or !is_instance_valid(player):
		# 尝试重新查找玩家
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			return  # 没有玩家，不生成敌人

	# 检查是否达到最大敌人数量
	var current_enemies = get_tree().get_nodes_in_group("enemies")
	if current_enemies.size() >= max_enemies:
		return

	# 根据难度确定敌人类型
	var enemy_type = EnemyType.BASIC
	var enemy_level = 1 + int(difficulty / 2)  # 每2分钟提升一级
	var random_value = randf()

	# 开始时只生成基本敌人
	if difficulty == 0:
		enemy_type = EnemyType.BASIC
	# 10分钟后，有小概率生成Boss
	elif difficulty >= 10 and random_value < 0.05:
		enemy_type = EnemyType.BOSS
	# 5分钟后，有概率生成精英敌人
	elif difficulty >= 5 and random_value < 0.15 + (difficulty * 0.005):
		enemy_type = EnemyType.ELITE
	# 2分钟后，有概率生成远程敌人
	elif difficulty >= 2 and random_value < 0.2 + (difficulty * 0.01):
		enemy_type = EnemyType.RANGED
	# 默认生成基本敌人
	else:
		enemy_type = EnemyType.BASIC

	# 创建敌人实例
	var enemy = enemy_factory.create_enemy(enemy_type, enemy_level)

	# 设置生成位置
	var spawn_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var spawn_distance = randf_range(min_spawn_distance, spawn_radius)
	var spawn_position = player.global_position + (spawn_direction * spawn_distance)

	# 检查敌人是否有效
	if enemy == null:
		push_error("Enemy creation failed")
		return

	# 设置敌人属性
	enemy.global_position = spawn_position

	# 安全地设置目标
	if "target" in enemy:
		enemy.target = player

	# 根据难度安全地调整敌人属性
	if "max_health" in enemy:
		enemy.max_health = int(enemy.max_health * (1 + difficulty * 0.1))

	if "current_health" in enemy and "max_health" in enemy:
		enemy.current_health = enemy.max_health

	if "attack_damage" in enemy:
		enemy.attack_damage = int(enemy.attack_damage * (1 + difficulty * 0.05))

	if "experience_value" in enemy:
		enemy.experience_value = int(enemy.experience_value * (1 + difficulty * 0.02))

	# 应用遗物效果修改器
	if "move_speed" in enemy and enemy_speed_modifier != 0.0:
		# 计算新的移动速度，确保不会变成负数
		var speed_multiplier = 1.0 + enemy_speed_modifier
		enemy.move_speed = max(10, enemy.move_speed * speed_multiplier)
		print("应用敌人速度修改器，原速度:", enemy.move_speed / speed_multiplier, "新速度:", enemy.move_speed)

	# 更新生命条
	var health_bar = enemy.find_child("HealthBar")
	if health_bar and health_bar is HealthBarClass and "max_health" in enemy and "current_health" in enemy:
		health_bar.set_max_value(enemy.max_health)
		health_bar.set_value(enemy.current_health)

	# 安全地连接信号
	if enemy.has_signal("died"):
		if not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)

	# 添加到场景
	get_tree().current_scene.add_child(enemy)

	# print("EnemySpawner: Enemy spawned at position: ", spawn_position)

# 创建特定类型的敌人
func create_enemy(enemy_type, level = 1):
	# 使用敌人工厂创建敌人
	return enemy_factory.create_enemy(enemy_type, level)

# Increase difficulty
func increase_difficulty():
	# Note: difficulty is already incremented in main.gd

	# Increase max enemies as difficulty increases
	max_enemies = min(200, max_enemies + 5)

# Signal for enemy death
signal enemy_died(position, experience)

# Handle enemy death
func _on_enemy_died(position, experience):
	# Debug output
	# print("Enemy spawner received death signal at position: ", position, " with experience: ", experience)

	# Forward the signal to the main scene
	enemy_died.emit(position, experience)

# 在节点被移除时清理资源
func _exit_tree():
	# 清理敌人工厂
	if enemy_factory != null:
		enemy_factory = null

	# 清理敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
