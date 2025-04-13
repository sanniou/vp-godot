extends "res://scripts/enemies/abstract_enemy.gd"
class_name BasicEnemy

func _init():
    super._init("basic_enemy", "基本敌人", EnemyType.BASIC)

    # 从配置中加载属性，已在父类中实现

func _ready():
    # Call parent ready function
    super._ready()

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
