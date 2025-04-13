extends "res://scripts/enemies/abstract_enemy.gd"
class_name RangedEnemy

func _init():
    super._init("ranged_enemy", "远程敌人", EnemyType.RANGED)

    # 从配置中加载属性，已在父类中实现

# Ranged enemy specific properties
var attack_range = 200  # 远程敌人的攻击范围

# 注意：不需要重写 setup_collision 方法，因为基类的实现已经足够

# 设置视觉效果
# 重写父类的 setup_visuals 方法
func setup_visuals():
	# 创建视觉效果
	var visual = ColorRect.new()
	visual.color = Color(0.8, 0.2, 0.8, 1.0)  # 紫色
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	add_child(visual)

	# 血条和护盾条已经在基类中设置，不需要在这里创建
	# 调用基类的设置方法
	setup_health_bar()
	setup_shield_bar()

func _ready():
	# Call parent ready function
	super._ready()

# 重写父类的 _physics_process 方法
func _physics_process(delta):
	# 调用父类的 _physics_process 方法
	super._physics_process(delta)

	# 如果没有目标，不做任何事情
	if target == null or !is_instance_valid(target):
		return

	# 计算与目标的距离
	var distance_to_target = global_position.distance_to(target.global_position)

	# 如果距离过近，尝试保持距离
	if distance_to_target < attack_range * 0.7:
		var direction = (global_position - target.global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()

# 重写父类的 setup_attack_system 方法
func setup_attack_system():
	# 使用远程攻击系统
	attack_system = load("res://scripts/enemies/attacks/ranged_attack.gd").new()
	attack_system.setup(self, attack_damage, attack_range)

	# 设置投射物属性
	if "projectile_speed" in attack_system:
		attack_system.projectile_speed = 200.0

	add_child(attack_system)
