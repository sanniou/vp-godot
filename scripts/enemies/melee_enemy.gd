extends "res://scripts/enemies/abstract_enemy.gd"

func _init():
    super._init("melee_enemy", "近战敌人", EnemyType.MELEE)

# 重写视觉效果设置
func setup_visuals():
    # 创建敌人外观
    var visual = ColorRect.new()
    visual.color = Color(0.8, 0.2, 0.2, 1.0)  # 红色
    visual.size = Vector2(40, 40)
    visual.position = Vector2(-20, -20)
    add_child(visual)

    # 添加生命条
    var health_bar = ProgressBar.new()
    health_bar.max_value = max_health
    health_bar.value = current_health
    health_bar.size = Vector2(40, 5)
    health_bar.position = Vector2(-20, -30)
    add_child(health_bar)

# 重写攻击系统设置
func setup_attack_system():
    attack_system = load("res://scripts/enemies/attacks/melee_attack.gd").new()
    attack_system.setup(self, attack_damage, attack_range)
    add_child(attack_system)
