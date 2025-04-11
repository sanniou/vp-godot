extends "res://scripts/enemies/attacks/abstract_attack.gd"

var attack_phases = 3  # 攻击阶段数
var current_phase = 0  # 当前阶段
var phase_timer = 0.0  # 阶段计时器
var phase_duration = 0.5  # 每个阶段的持续时间

func _init():
    super._init(AttackType.SPECIAL)

    # 设置特殊攻击特有属性
    cooldown = 5.0
    damage *= 1.5
    stun_chance = 0.4
    stun_duration = 1.5
    knockback_force = 200.0

# 重写特殊攻击实现
func perform_special_attack():
    if !owner_enemy:
        return

    # 开始多阶段攻击
    current_phase = 0
    phase_timer = 0.0

    # 设置处理阶段的计时器
    owner_enemy.set_process(false)  # 暂停敌人的正常处理
    set_process(true)  # 启用此攻击的处理

    # 播放特殊攻击准备动画
    play_special_attack_preparation()

# 处理特殊攻击阶段
func _process(delta):
    if current_phase >= attack_phases:
        # 攻击完成
        finish_special_attack()
        return

    # 更新阶段计时器
    phase_timer += delta
    if phase_timer >= phase_duration:
        # 执行当前阶段
        execute_attack_phase(current_phase)

        # 进入下一阶段
        current_phase += 1
        phase_timer = 0.0

# 执行攻击阶段
func execute_attack_phase(phase):
    if !owner_enemy or !owner_enemy.target:
        return

    match phase:
        0:  # 第一阶段：冲向目标
            # 计算方向
            var direction = (owner_enemy.target.global_position - owner_enemy.global_position).normalized()

            # 冲刺
            owner_enemy.velocity = direction * owner_enemy.move_speed * 3

            # 播放冲刺效果
            play_dash_effect(direction)

        1:  # 第二阶段：范围攻击
            # 获取范围内的所有玩家
            var players = owner_enemy.get_tree().get_nodes_in_group("player")
            for player in players:
                var distance = owner_enemy.global_position.distance_to(player.global_position)
                if distance <= range * 1.5:  # 增加范围
                    # 造成伤害
                    if player.has_method("take_damage"):
                        player.take_damage(damage * 0.7)  # 减少伤害

                    # 应用状态效果
                    apply_status_effects(player)

            # 播放范围攻击效果
            play_area_attack_animation()

        2:  # 第三阶段：强力单体攻击
            if owner_enemy.target and owner_enemy.global_position.distance_to(owner_enemy.target.global_position) <= range * 2:
                # 造成伤害
                if owner_enemy.target.has_method("take_damage"):
                    owner_enemy.target.take_damage(damage * 1.5)  # 增加伤害

                # 应用击退
                if knockback_force > 0 and owner_enemy.target.has_method("apply_knockback"):
                    var direction = (owner_enemy.target.global_position - owner_enemy.global_position).normalized()
                    owner_enemy.target.apply_knockback(direction, knockback_force * 1.5)

                # 应用状态效果
                apply_status_effects(owner_enemy.target)

            # 播放强力攻击效果
            play_powerful_attack_effect()

# 完成特殊攻击
func finish_special_attack():
    if owner_enemy:
        # 恢复敌人的正常处理
        owner_enemy.set_process(true)

    # 停止此攻击的处理
    set_process(false)

# 播放特殊攻击准备动画
func play_special_attack_preparation():
    if !owner_enemy:
        return

    # 创建准备效果
    var prep_effect = Node2D.new()
    owner_enemy.add_child(prep_effect)
    prep_effect.name = "SpecialAttackPrep"

    # 创建充能圆环
    var ring = Polygon2D.new()
    var outer_points = []
    var inner_points = []
    var segments = 32

    for i in range(segments):
        var angle = 2 * PI * i / segments
        outer_points.append(Vector2(cos(angle), sin(angle)) * 30)
        inner_points.append(Vector2(cos(angle), sin(angle)) * 25)

    # 反转内环点顺序并添加到多边形
    inner_points.reverse()
    var all_points = outer_points + inner_points

    ring.polygon = all_points
    ring.color = Color(1, 0, 0, 0.7)  # 红色半透明
    prep_effect.add_child(ring)

    # 动画效果
    var tween = owner_enemy.create_tween()
    tween.tween_property(ring, "rotation", 2 * PI, phase_duration * attack_phases)
    tween.parallel().tween_property(ring, "scale", Vector2(1.5, 1.5), phase_duration * attack_phases)
    tween.tween_callback(func(): prep_effect.queue_free())

# 播放冲刺效果
func play_dash_effect(direction):
    if !owner_enemy:
        return

    # 创建拖尾效果
    var trail = Line2D.new()
    trail.width = 10
    trail.default_color = Color(1, 0, 0, 0.5)  # 半透明红色
    owner_enemy.add_child(trail)

    # 添加点
    trail.add_point(Vector2.ZERO)
    trail.add_point(-direction * 50)

    # 动画效果
    var tween = owner_enemy.create_tween()
    tween.tween_property(trail, "modulate:a", 0, 0.5)
    tween.tween_callback(func(): trail.queue_free())

# 播放强力攻击效果
func play_powerful_attack_effect():
    if !owner_enemy:
        return

    # 创建攻击效果
    var attack_effect = Node2D.new()
    owner_enemy.add_child(attack_effect)

    # 创建冲击波
    var shockwave = Polygon2D.new()
    var points = []
    var segments = 32

    for i in range(segments):
        var angle = 2 * PI * i / segments
        points.append(Vector2(cos(angle), sin(angle)) * 20)

    shockwave.polygon = points
    shockwave.color = Color(1, 0, 0, 0.7)  # 红色半透明
    attack_effect.add_child(shockwave)

    # 创建粒子效果
    var particles = CPUParticles2D.new()
    particles.amount = 30
    particles.lifetime = 0.5
    particles.explosiveness = 1.0
    particles.direction = Vector2(0, -1)
    particles.spread = 180
    particles.gravity = Vector2(0, 0)
    particles.initial_velocity_min = 50
    particles.initial_velocity_max = 100
    particles.scale_amount = 3
    particles.color = Color(1.0, 0.0, 0.0, 1.0)  # 红色
    particles.emitting = true
    particles.one_shot = true

    attack_effect.add_child(particles)

    # 动画效果
    var tween = owner_enemy.create_tween()
    tween.tween_property(shockwave, "scale", Vector2(3, 3), 0.3)
    tween.parallel().tween_property(shockwave, "modulate:a", 0, 0.3)
    tween.tween_callback(func(): attack_effect.queue_free())
