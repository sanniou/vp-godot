extends Node2D

# 基本属性
var damage = 15
var fire_rate = 0.5  # 每秒射击次数
var bullet_speed = 600
var bullet_count = 1  # 一次射击的子弹数量

# 升级属性
var damage_level = 1
var fire_rate_level = 1
var bullet_count_level = 1

# 内部变量
var can_attack = true
var attack_timer = 0
var target_position = Vector2.ZERO

func _ready():
	# 设置初始状态
	pass

func _process(delta):
	# 处理攻击冷却
	if !can_attack:
		attack_timer += delta
		if attack_timer >= 1.0 / fire_rate:
			can_attack = true
			attack_timer = 0
	
	# 获取目标位置（鼠标位置或最近的敌人）
	find_target()
	
	# 自动攻击
	if can_attack:
		attack()

# 寻找最近的敌人作为目标
func find_target():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_distance = 1000000  # 一个很大的初始值
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	if closest_enemy:
		target_position = closest_enemy.global_position

# 攻击函数
func attack():
	if target_position == Vector2.ZERO:
		return
	
	can_attack = false
	
	# 计算射击方向
	var direction = (target_position - global_position).normalized()
	
	# 根据bullet_count发射多个子弹
	for i in range(bullet_count):
		var bullet = create_bullet()
		
		# 如果有多个子弹，稍微改变方向
		var spread = 0
		if bullet_count > 1:
			spread = (i - (bullet_count - 1) / 2.0) * 0.1
		
		var bullet_direction = direction.rotated(spread)
		bullet.velocity = bullet_direction * bullet_speed
		bullet.damage = damage
		
		# 将子弹添加到场景
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position

# 创建子弹
func create_bullet():
	# 创建子弹视觉效果
	var bullet_visual = ColorRect.new()
	bullet_visual.color = Color(1, 1, 0, 1)  # 黄色子弹
	bullet_visual.size = Vector2(10, 4)
	bullet_visual.position = Vector2(-5, -2)  # 居中
	
	# 创建子弹容器
	var bullet = Area2D.new()
	bullet.add_child(bullet_visual)
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(10, 4)
	collision.shape = shape
	bullet.add_child(collision)
	
	# 设置碰撞层
	bullet.collision_layer = 0
	bullet.collision_mask = 4  # 敌人层
	
	# 添加脚本
	var script = GDScript.new()
	script.source_code = """
extends Area2D

var velocity = Vector2.ZERO
var damage = 0
var lifetime = 0
var max_lifetime = 2.0

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta):
	position += velocity * delta
	
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.take_damage(damage)
		queue_free()
"""
	script.reload()
	bullet.set_script(script)
	
	return bullet

# 升级武器
func upgrade(upgrade_type):
	match upgrade_type:
		"damage":
			damage_level += 1
			damage = 15 + (damage_level - 1) * 5  # 每级+5伤害
		"fire_rate":
			fire_rate_level += 1
			fire_rate = 0.5 + (fire_rate_level - 1) * 0.2  # 每级+0.2射速
		"bullet_count":
			bullet_count_level += 1
			bullet_count = 1 + (bullet_count_level - 1)  # 每级+1子弹
