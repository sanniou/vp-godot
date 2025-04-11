extends "res://scripts/enemies/attacks/abstract_attack.gd"

func _init():
    super._init(AttackType.AREA)

    # 设置范围攻击特有属性
    cooldown = 3.0
    burn_chance = 0.3
    burn_damage = 5.0
    burn_duration = 2.0

# 重写范围攻击实现
func perform_area_attack():
    if !owner_enemy:
        return

    # 获取范围内的所有玩家
    var players = owner_enemy.get_tree().get_nodes_in_group("player")
    for player in players:
        var distance = owner_enemy.global_position.distance_to(player.global_position)
        if distance <= range:
            # 计算伤害衰减
            var damage_factor = 1.0 - (distance / range) * 0.5  # 最小伤害为50%
            var final_damage = damage * damage_factor

            # 造成伤害
            if player.has_method("take_damage"):
                player.take_damage(final_damage)

            # 应用状态效果
            apply_status_effects(player)

    # 播放范围攻击动画
    play_area_attack_animation()

# 重写范围攻击动画
func play_area_attack_animation():
    if !owner_enemy:
        return

    # 创建攻击效果容器
    var attack_effect = Node2D.new()
    owner_enemy.add_child(attack_effect)

    # 创建圆形效果
    var circle = Polygon2D.new()
    var points = []
    var segments = 32

    for i in range(segments):
        var angle = 2 * PI * i / segments
        var point = Vector2(cos(angle), sin(angle)) * range
        points.append(point)

    circle.polygon = points
    circle.color = Color(1, 0.3, 0, 0.5)  # 橙红色半透明
    attack_effect.add_child(circle)

    # 创建粒子效果
    var particles = CPUParticles2D.new()
    particles.amount = 50
    particles.lifetime = 0.5
    particles.explosiveness = 0.8
    particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_CIRCLE
    particles.emission_sphere_radius = range
    particles.direction = Vector2(0, -1)
    particles.spread = 180
    particles.gravity = Vector2(0, 0)
    particles.initial_velocity_min = 10
    particles.initial_velocity_max = 30
    particles.scale_amount = 3
    particles.color = Color(1.0, 0.5, 0.0, 1.0)  # 橙色
    particles.emitting = true
    particles.one_shot = true

    attack_effect.add_child(particles)

    # 动画效果
    var tween = owner_enemy.create_tween()
    tween.tween_property(circle, "scale", Vector2(1.2, 1.2), 0.5)
    tween.parallel().tween_property(circle, "modulate:a", 0, 0.5)
    tween.tween_callback(func(): attack_effect.queue_free())
