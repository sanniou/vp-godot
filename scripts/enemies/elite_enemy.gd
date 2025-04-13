extends "res://scripts/enemies/enemy.gd"
class_name EliteEnemy

func _init():
    super._init()
    enemy_id = "elite_enemy"
    enemy_name = "精英敌人"
    enemy_type = EnemyType.ELITE

# 重写视觉效果设置
func setup_visuals():
    # 创建敌人外观
    var visual = ColorRect.new()
    visual.color = Color(0.8, 0.8, 0.2, 1.0)  # 黄色
    visual.size = Vector2(50, 50)
    visual.position = Vector2(-25, -25)
    add_child(visual)

    # 血条和护盾条已经在基类中设置，不需要在这里创建
    # 调用基类的设置方法
    setup_health_bar()
    setup_shield_bar()

# 重写攻击系统设置
func setup_attack_system():
    attack_system = load("res://scripts/enemies/attacks/area_attack.gd").new()
    attack_system.setup(self, attack_damage, attack_range)
    add_child(attack_system)

# 重写更新护盾
func update_shield(delta):
    # 调用基类的更新护盾方法，已经包含了护盾条更新
    super.update_shield(delta)

# 设置技能
func setup_skills():
    # 添加一个简单的技能：每10秒恢复一次生命值
    var heal_timer = Timer.new()
    heal_timer.wait_time = 10.0
    heal_timer.autostart = true
    heal_timer.timeout.connect(func(): heal(max_health * 0.1))
    add_child(heal_timer)

# 治疗
func heal(amount):
    current_health = min(current_health + amount, max_health)

    # 更新生命条
    var health_bar = find_child("HealthBar")
    if health_bar and health_bar is HealthBarClass:
        health_bar.set_value(current_health)

    # 显示治疗效果
    show_heal_effect(amount)

# 显示治疗效果
func show_heal_effect(amount):
    var heal_label = Label.new()
    heal_label.text = "+" + str(int(amount))
    heal_label.position = Vector2(0, -40)
    heal_label.modulate = Color(0.3, 1.0, 0.3)  # 绿色
    add_child(heal_label)

    # 动画效果
    var tween = create_tween()
    tween.tween_property(heal_label, "position:y", -60, 0.5)
    tween.parallel().tween_property(heal_label, "modulate:a", 0, 0.5)
    tween.tween_callback(func(): heal_label.queue_free())
