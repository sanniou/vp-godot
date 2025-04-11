extends Area2D

# 预加载抽象遗物类
const AbstractRelic = preload("res://scripts/relics/abstract_relic.gd")

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

# 信号
signal enemy_hit(enemy, damage)
signal damage_dealt(enemy, damage, is_critical)

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# 准备伤害数据
		var damage_data = {
			"damage": damage,
			"enemy": body,
			"weapon": get_parent(),
			"is_critical": false
		}

		# 触发伤害事件，应用遗物效果
		var main = get_tree().current_scene
		if main and main.relic_manager:
			damage_data = main.relic_manager.trigger_event(AbstractRelic.EventType.DAMAGE_DEALT, damage_data)

		# 应用最终伤害
		var final_damage = damage_data["damage"]
		body.take_damage(final_damage)

		# 发出信号
		enemy_hit.emit(body, final_damage)
		damage_dealt.emit(body, final_damage, damage_data["is_critical"])

		# 处理生命窃取遗物效果
		if damage_data.has("heal_player") and damage_data["heal_player"] and damage_data.has("heal_amount"):
			var player = main.player
			if player and is_instance_valid(player):
				player.heal(damage_data["heal_amount"])

		# 显示暴击效果
		if damage_data["is_critical"]:
			# 创建暴击文本
			var crit_label = Label.new()
			crit_label.text = "CRIT!"
			crit_label.position = Vector2(-20, -30)
			crit_label.modulate = Color(1.0, 0.0, 0.0, 1.0)
			crit_label.z_index = 10
			body.add_child(crit_label)

			# 动画效果
			var tween = body.create_tween()
			tween.tween_property(crit_label, "position:y", -50, 0.5)
			tween.parallel().tween_property(crit_label, "modulate:a", 0, 0.5)
			tween.tween_callback(func(): crit_label.queue_free())

		# 使用 call_deferred 延迟销毁子弹，避免在物理查询刷新时销毁
		call_deferred("queue_free")

func _on_screen_exited():
	# Destroy projectile if it goes off screen
	call_deferred("queue_free")
