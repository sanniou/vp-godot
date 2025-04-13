extends "res://scripts/enemies/abstract_enemy.gd"
class_name SimpleEnemy

# 预加载抽象敌人类
const AbstractEnemy = preload("res://scripts/enemies/abstract_enemy.gd")

func _init():
    super._init("simple_enemy", "简单敌人", AbstractEnemy.EnemyType.BASIC)

func _ready():
    # 调用父类的 _ready 方法
    super._ready()

    # 设置基本敌人属性
    max_health = 30
    current_health = max_health
    move_speed = 100
    attack_damage = 10
    experience_value = 5

# 重写视觉效果设置
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

# 重写攻击系统设置
func setup_attack_system():
    attack_system = load("res://scripts/enemies/attacks/melee_attack.gd").new()
    attack_system.setup(self, attack_damage, attack_range)
    add_child(attack_system)
