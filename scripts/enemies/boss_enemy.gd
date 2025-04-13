extends "res://scripts/enemies/abstract_enemy.gd"

# 预加载生命条类
const HealthBarClass = preload("res://scripts/ui/health_bar.gd")

var phase = 1  # 当前阶段
var max_phases = 3  # 最大阶段数
var phase_health_threshold = 0.33  # 每个阶段的生命值阈值

# 阶段特有属性
var phase_attack_systems = []  # 每个阶段的攻击系统
var current_attack_system = null  # 当前使用的攻击系统

func _init():
    super._init("boss_enemy", "Boss敌人", EnemyType.BOSS)

# 重写初始化
func _ready():
    super._ready()

    # 设置阶段攻击系统
    setup_phase_attack_systems()

    # 设置当前攻击系统
    update_phase_attack_system()

# 重写视觉效果设置
func setup_visuals():
    # 创建敌人外观
    var visual = ColorRect.new()
    visual.color = Color(0.8, 0.0, 0.0, 1.0)  # 深红色
    visual.size = Vector2(80, 80)
    visual.position = Vector2(-40, -40)
    add_child(visual)

    # 血条和护盾条已经在基类中设置，不需要在这里创建
    # 调用基类的设置方法
    setup_health_bar()
    setup_shield_bar()

    # 添加阶段指示器
    var phase_indicator = Label.new()
    phase_indicator.text = "Phase " + str(phase) + "/" + str(max_phases)
    phase_indicator.position = Vector2(-30, -75)
    phase_indicator.name = "PhaseIndicator"
    add_child(phase_indicator)

# 设置阶段攻击系统
func setup_phase_attack_systems():
    # 第一阶段：近战攻击
    var melee_attack = load("res://scripts/enemies/attacks/melee_attack.gd").new()
    melee_attack.setup(self, attack_damage, attack_range)
    phase_attack_systems.append(melee_attack)

    # 第二阶段：范围攻击
    var area_attack = load("res://scripts/enemies/attacks/area_attack.gd").new()
    area_attack.setup(self, attack_damage * 1.5, attack_range * 1.5)
    phase_attack_systems.append(area_attack)

    # 第三阶段：特殊攻击
    var special_attack = load("res://scripts/enemies/attacks/special_attack.gd").new()
    special_attack.setup(self, attack_damage * 2, attack_range * 2)
    phase_attack_systems.append(special_attack)

# 更新阶段攻击系统
func update_phase_attack_system():
    # 移除当前攻击系统
    if current_attack_system and current_attack_system.get_parent() == self:
        remove_child(current_attack_system)

    # 设置新的攻击系统
    current_attack_system = phase_attack_systems[phase - 1]
    add_child(current_attack_system)

    # 更新攻击系统引用
    attack_system = current_attack_system

# 重写攻击系统设置
func setup_attack_system():
    # 在setup_phase_attack_systems中处理
    pass

# 重写更新护盾
func update_shield(delta):
    super.update_shield(delta)

    # 更新护盾条
    var shield_bar = find_child("ShieldBar")
    if shield_bar:
        shield_bar.value = shield

# 重写受到伤害
func take_damage(amount, damage_type = "physical"):
    # 调用父类方法
    super.take_damage(amount, damage_type)

    # 检查是否需要进入下一阶段
    check_phase_transition()

# 检查阶段转换
func check_phase_transition():
    # 计算当前生命值百分比
    var health_percent = current_health / max_health

    # 计算应该处于的阶段
    var new_phase = max_phases - floor(health_percent / phase_health_threshold)
    new_phase = clamp(new_phase, 1, max_phases)

    # 如果阶段变化，进行转换
    if new_phase != phase:
        transition_to_phase(new_phase)

# 转换到新阶段
func transition_to_phase(new_phase):
    # 更新阶段
    phase = new_phase

    # 更新阶段指示器
    var phase_indicator = find_child("PhaseIndicator")
    if phase_indicator:
        phase_indicator.text = "Phase " + str(phase) + "/" + str(max_phases)

    # 更新攻击系统
    update_phase_attack_system()

    # 播放阶段转换效果
    play_phase_transition_effect()

    # 根据阶段调整属性
    match phase:
        2:
            # 第二阶段：增加移动速度，减少护盾再生
            move_speed *= 1.2
            shield_regeneration *= 0.8
        3:
            # 第三阶段：增加伤害，减少移动速度
            attack_damage *= 1.5
            move_speed *= 0.8

# 播放阶段转换效果
func play_phase_transition_effect():
    # 创建爆发效果
    var burst = CPUParticles2D.new()
    burst.emitting = true
    burst.one_shot = true
    burst.explosiveness = 1.0
    burst.amount = 50
    burst.lifetime = 1.0
    burst.direction = Vector2(0, -1)
    burst.spread = 180
    burst.gravity = Vector2(0, 0)
    burst.initial_velocity_min = 100
    burst.initial_velocity_max = 200
    burst.scale_amount = 5

    # 根据阶段设置颜色
    match phase:
        2:
            burst.color = Color(1.0, 0.5, 0.0, 1.0)  # 橙色
        3:
            burst.color = Color(1.0, 0.0, 0.0, 1.0)  # 红色

    add_child(burst)

    # 添加震动效果
    var tween = create_tween()
    tween.tween_property(self, "position", Vector2(5, 0), 0.05)
    tween.tween_property(self, "position", Vector2(-5, 0), 0.05)
    tween.tween_property(self, "position", Vector2(0, 0), 0.05)

    # 自动删除粒子
    var timer = Timer.new()
    timer.wait_time = 2.0
    timer.one_shot = true
    timer.autostart = true
    add_child(timer)

    timer.timeout.connect(func():
        burst.queue_free()
        timer.queue_free()
    )

# 设置技能
func setup_skills():
    # 添加一个治疗技能：生命值低于30%时触发
    var heal_timer = Timer.new()
    heal_timer.wait_time = 15.0
    heal_timer.autostart = true
    heal_timer.timeout.connect(func():
        if current_health < max_health * 0.3:
            heal(max_health * 0.2)
    )
    add_child(heal_timer)

    # 添加一个护盾恢复技能：护盾耗尽时触发
    var shield_timer = Timer.new()
    shield_timer.wait_time = 20.0
    shield_timer.autostart = true
    shield_timer.timeout.connect(func():
        if shield <= 0:
            shield = max_health * 0.3
            play_shield_restore_effect()
    )
    add_child(shield_timer)

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

# 播放护盾恢复效果
func play_shield_restore_effect():
    # 创建护盾效果
    var shield_effect = Polygon2D.new()
    var points = []
    var segments = 32

    for i in range(segments):
        var angle = 2 * PI * i / segments
        points.append(Vector2(cos(angle), sin(angle)) * 50)

    shield_effect.polygon = points
    shield_effect.color = Color(0.2, 0.6, 1.0, 0.5)  # 蓝色半透明
    add_child(shield_effect)

    # 动画效果
    var tween = create_tween()
    tween.tween_property(shield_effect, "scale", Vector2(1.5, 1.5), 0.5)
    tween.parallel().tween_property(shield_effect, "modulate:a", 0, 0.5)
    tween.tween_callback(func(): shield_effect.queue_free())
