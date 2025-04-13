extends "res://scripts/enemies/enemy.gd"
class_name StrongEnemy

func _init():
	super._init()
	enemy_id = "strong_enemy"
	enemy_name = "强壮敌人"
	enemy_type = EnemyType.ELITE

	# 设置强壮敌人属性
	max_health = 80
	current_health = max_health
	move_speed = 80
	attack_damage = 20
	experience_value = 15

# 重写父类的 setup_visuals 方法
func setup_visuals():
	# 创建敌人外观
	var visual = ColorRect.new()
	visual.color = Color(0.6, 0.3, 0.8, 1.0)  # 紫色
	visual.size = Vector2(45, 45)
	visual.position = Vector2(-22.5, -22.5)
	add_child(visual)

	# 调用基类的生命条设置方法
	setup_health_bar()
	setup_shield_bar()
