extends Area2D

# 信号
signal collected(value, source, orb)

# 预加载抽象遗物类
const AbstractRelic = preload("res://scripts/relics/abstract_relic.gd")

var experience_value = 1
var move_speed = 0
var max_speed = 400
var acceleration = 800
var target = null
var is_attracting = false
var source = "default"  # 经验来源

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	$AttractTimer.timeout.connect(_on_attract_timer_timeout)

	# 创建定时器在一段时间后启用碰撞
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func(): call_deferred("_enable_collision"))

# 启用碰撞检测
func _enable_collision():
	# 使用 call_deferred 来确保在物理处理外调用
	call_deferred("_safely_enable_collision")

# 安全地启用碰撞检测
func _safely_enable_collision():
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func _process(delta):
	if is_attracting and target != null and is_instance_valid(target):
		# Calculate direction to player
		var direction = (target.global_position - global_position).normalized()

		# Accelerate towards player
		move_speed = min(move_speed + acceleration * delta, max_speed)

		# Move towards player
		global_position += direction * move_speed * delta

# Set the experience value
func set_value(value):
	experience_value = value

	# Scale the sprite based on value
	var scale_factor = 1.0 + (value / 10.0)
	scale = Vector2(scale_factor, scale_factor)

# Start attracting to player
func start_attracting(player):
	target = player
	is_attracting = true

	# 触发物品拾取事件，应用遗物效果
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

# Signal handlers
func _on_body_entered(body):
	# Debug output
	# print("Experience orb collided with: ", body, ", is in player group: ", body.is_in_group("player"))

	if body.is_in_group("player"):
		# Debug output
		# print("Adding experience: ", experience_value)

		# 触发遗物效果
		var main = get_tree().current_scene
		if main and main.has_node("RelicManager"):
			var relic_manager = main.get_node("RelicManager")

			# 准备事件数据
			var event_data = {
				"experience": experience_value,
				"player": body
			}

			# 触发经验球收集事件
			var modified_data = relic_manager.trigger_event(AbstractRelic.EventType.EXPERIENCE_ORB_COLLECTED, event_data)

			# 获取修改后的经验值
			experience_value = modified_data["experience"]

		# 禁用碰撞检测，防止多次触发
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)

		# 发出收集信号
		collected.emit(experience_value, source, self)

		# 播放收集动画
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_callback(func(): queue_free())

func _on_attract_timer_timeout():
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]

		# 触发物品拾取事件，获取吸引范围
		var attraction_range = 200  # 默认吸引范围
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
