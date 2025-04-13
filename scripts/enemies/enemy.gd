extends "res://scripts/enemies/abstract_enemy.gd"
class_name Enemy

# 构造函数
func _init():
	super._init("enemy", "敌人", EnemyType.BASIC)

func _ready():
	# 调用父类的 _ready 方法
	super._ready()

# 重写父类的 _physics_process 方法
func _physics_process(delta):
	# 调用父类的 _physics_process 方法
	super._physics_process(delta)

# 重写父类的 setup_visuals 方法
func setup_visuals():
	# 创建敌人外观
	var visual = ColorRect.new()
	visual.color = Color(0.8, 0.2, 0.2, 1.0)  # 红色
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	add_child(visual)

	# 调用基类的生命条设置方法
	setup_health_bar()
	setup_shield_bar()
