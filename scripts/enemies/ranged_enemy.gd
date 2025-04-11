extends "res://scripts/enemies/enemy.gd"
class_name RangedEnemy

# Ranged enemy specific properties
var attack_range = 300
var attack_cooldown = 2.0
var attack_timer = 0
var projectile_speed = 150

# 设置碰撞
# 重写父类的 setup_collision 方法
func setup_collision():
	# 创建碰撞形状
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision_shape.shape = shape
	add_child(collision_shape)

	# 设置碰撞层
	collision_layer = 4  # 敌人层
	collision_mask = 3   # 玩家层和墙壁层

# 设置视觉效果
# 重写父类的 setup_visuals 方法
func setup_visuals():
	# 创建视觉效果
	var visual = ColorRect.new()
	visual.color = Color(0.8, 0.2, 0.8, 1.0)  # 紫色
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	add_child(visual)

	# 添加生命条
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"  # 给生命条命名，便于查找
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.size = Vector2(40, 5)
	health_bar.position = Vector2(-20, -30)

	# 设置生命条样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.8, 0, 0, 1)  # 红色生命条
	style_box.corner_radius_top_left = 2
	style_box.corner_radius_top_right = 2
	style_box.corner_radius_bottom_left = 2
	style_box.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("fill", style_box)

	# 设置背景样式
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # 灰色背景
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("background", bg_style)

	# 添加到敌人
	add_child(health_bar)

func _ready():
	# Call parent ready function
	super._ready()

	# Set ranged enemy stats
	max_health = 50
	current_health = max_health
	move_speed = 70
	damage = 15
	experience_value = 10

func _physics_process(delta):
	if target == null or !is_instance_valid(target):
		# Try to find player if target is lost
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
		else:
			return  # No target, don't move

	# Calculate distance to target
	var distance_to_target = global_position.distance_to(target.global_position)

	# If within attack range, stop and attack
	if distance_to_target <= attack_range:
		# Update attack timer
		attack_timer += delta

		# Attack if cooldown is over
		if attack_timer >= attack_cooldown:
			attack_timer = 0
			fire_projectile()

		# Move away if too close
		if distance_to_target < attack_range * 0.7:
			var direction = (global_position - target.global_position).normalized()
			velocity = direction * move_speed
		else:
			velocity = Vector2.ZERO
	else:
		# Move towards target
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * move_speed

	# Apply movement
	move_and_slide()

# Fire a projectile at the target
func fire_projectile():
	# Create projectile
	var projectile = ColorRect.new()
	projectile.color = Color(0.8, 0.2, 0.8, 1.0)
	projectile.size = Vector2(10, 10)
	projectile.position = Vector2(-5, -5)  # Center the rect

	# Create projectile container
	var projectile_node = Area2D.new()
	projectile_node.global_position = global_position
	projectile_node.add_child(projectile)

	# Set up collision
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 5
	collision_shape.shape = shape
	projectile_node.add_child(collision_shape)

	# Set collision layers
	projectile_node.collision_layer = 0
	projectile_node.collision_mask = 2  # Player layer

	# Add to scene
	get_tree().current_scene.add_child(projectile_node)

	# Calculate direction to target
	var direction = (target.global_position - global_position).normalized()

	# Create script for projectile
	var script = GDScript.new()
	script.source_code = '''
extends Area2D

var velocity = Vector2.ZERO
var damage = 0
var lifetime = 0
var max_lifetime = 5.0

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	position += velocity * delta

	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()
'''
	script.reload()

	# Apply script to projectile
	projectile_node.set_script(script)

	# Set projectile properties
	projectile_node.velocity = direction * projectile_speed
	projectile_node.damage = damage
