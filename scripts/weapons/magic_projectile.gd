extends Area2D

var damage = 10
var speed = 400
var target = null
var max_lifetime = 5.0  # Maximum lifetime in seconds
var lifetime = 0

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)

	# 在下一帧启用碰撞
	call_deferred("_enable_collision")

# 启用碰撞检测
func _enable_collision():
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func _process(delta):
	if target == null or !is_instance_valid(target):
		# 目标无效，使用 call_deferred 延迟销毁子弹
		call_deferred("queue_free")
		return

	# Move towards target
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta

	# Update lifetime
	lifetime += delta
	if lifetime >= max_lifetime:
		call_deferred("queue_free")

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# Deal damage to enemy
		body.take_damage(damage)

		# 使用 call_deferred 延迟销毁子弹，避免在物理查询刷新时销毁
		call_deferred("queue_free")

func _on_screen_exited():
	# Destroy projectile if it goes off screen
	call_deferred("queue_free")
