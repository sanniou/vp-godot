extends "res://scripts/weapons/abstract_weapon.gd"
class_name BlackHoleBomb

# 黑洞属性
var damage_per_second = 15  # 每秒伤害
var explosion_damage = 50   # 爆炸伤害
var black_hole_radius = 80  # 黑洞半径
var pull_force = 150        # 拉力大小
var duration = 3.0          # 持续时间
var cooldown = 5.0          # 冷却时间

# 内部变量
var can_cast = true
var cooldown_timer = 0.0
var active_black_holes = []  # 活跃的黑洞

func _init():
    super._init(
        "black_hole_bomb",
        "黑洞炸弹",
        "创造一个黑洞，吸引并伤害周围的敌人",
        "🌑",
        "magic"
    )

func _process(delta):
    # 处理冷却
    if !can_cast:
        cooldown_timer += delta
        if cooldown_timer >= cooldown:
            can_cast = true
            cooldown_timer = 0.0

    # 如果可以施放，自动施放
    if can_cast:
        cast_black_hole()

    # 更新活跃的黑洞
    update_black_holes(delta)

# 施放黑洞
func cast_black_hole():
    can_cast = false

    # 寻找最佳位置（敌人最密集的地方）
    var target_position = find_best_position()

    # 创建黑洞
    var black_hole = create_black_hole()
    black_hole.position = target_position
    black_hole.lifetime = 0.0
    black_hole.max_lifetime = duration

    # 添加到场景
    get_tree().current_scene.add_child(black_hole)

    # 记录活跃的黑洞
    active_black_holes.append(black_hole)

    # 触发攻击事件
    var attack_data = {
        "position": target_position,
        "radius": black_hole_radius,
        "damage_per_second": damage_per_second,
        "explosion_damage": explosion_damage,
        "duration": duration
    }

    perform_attack()

# 寻找最佳位置（敌人最密集的地方）
func find_best_position():
    var enemies = get_tree().get_nodes_in_group("enemies")
    if enemies.size() == 0:
        # 如果没有敌人，在玩家前方施放
        var player = get_tree().current_scene.player
        if player:
            return player.global_position + Vector2(100, 0)
        return global_position

    # 计算敌人密度最高的位置
    var best_position = Vector2.ZERO
    var max_score = 0

    for enemy in enemies:
        var score = 0
        var pos = enemy.global_position

        # 计算这个位置的得分（周围敌人数量）
        for other in enemies:
            if other == enemy:
                continue

            var distance = pos.distance_to(other.global_position)
            if distance <= black_hole_radius * 1.5:
                score += 1

        if score > max_score:
            max_score = score
            best_position = pos

    # 如果没有找到好的位置，使用随机敌人的位置
    if max_score == 0 and enemies.size() > 0:
        best_position = enemies[randi() % enemies.size()].global_position

    return best_position

# 创建黑洞
func create_black_hole():
    var black_hole = Node2D.new()

    # 添加视觉效果
    var visual = Polygon2D.new()
    var points = []

    # 创建圆形
    var segments = 24
    for i in range(segments):
        var angle = 2 * PI * i / segments
        points.append(Vector2(cos(angle), sin(angle)) * black_hole_radius)

    visual.polygon = points
    visual.color = Color(0.1, 0.0, 0.2, 0.7)  # 深紫色
    black_hole.add_child(visual)

    # 添加发光效果
    var glow = visual.duplicate()
    glow.color = Color(0.5, 0.0, 0.8, 0.3)
    glow.scale = Vector2(1.2, 1.2)
    glow.z_index = -1
    black_hole.add_child(glow)

    # 添加粒子效果
    var particles = CPUParticles2D.new()
    particles.amount = 50
    particles.lifetime = 1.0
    particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    particles.emission_sphere_radius = black_hole_radius
    particles.direction = Vector2(0, 0)
    particles.spread = 180
    particles.gravity = Vector2(0, 0)
    particles.initial_velocity_min = 10
    particles.initial_velocity_max = 30
    particles.radial_accel_min = -100
    particles.radial_accel_max = -50
    particles.scale_amount = 3
    particles.color = Color(0.5, 0.0, 0.8, 0.5)
    black_hole.add_child(particles)

    # 添加碰撞区域
    var area = Area2D.new()
    var collision = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = black_hole_radius * 1.5  # 影响范围比视觉效果大
    collision.shape = shape
    area.add_child(collision)

    # 设置碰撞层
    area.collision_layer = 0
    area.collision_mask = 4  # 敌人层

    black_hole.add_child(area)

    # 添加脚本
    var script = GDScript.new()
    script.source_code = """
extends Node2D

var lifetime = 0.0
var max_lifetime = 3.0
var damage_per_second = 15
var explosion_damage = 50
var pull_force = 150
var affected_enemies = {}  # 记录已经受到伤害的敌人和时间

func _process(delta):
    lifetime += delta

    # 更新视觉效果
    var t = lifetime / max_lifetime
    var scale_factor = 1.0 - t * 0.3  # 逐渐缩小
    scale = Vector2(scale_factor, scale_factor)

    # 脉动效果
    var pulse = sin(lifetime * 10) * 0.1 + 0.9
    $Polygon2D.scale = Vector2(pulse, pulse)

    # 旋转效果
    rotation += delta * 0.5

    # 处理拉力和伤害
    var area = $Area2D
    var overlapping_bodies = area.get_overlapping_bodies()

    for body in overlapping_bodies:
        if body.is_in_group("enemies"):
            # 施加拉力
            var direction = global_position - body.global_position
            var distance = direction.length()
            if distance > 0:
                var force = direction.normalized() * pull_force * (1.0 - distance / (1.5 * $Area2D/CollisionShape2D.shape.radius))

                # 如果敌人有velocity属性，直接修改
                if "velocity" in body:
                    body.velocity += force * delta
                # 否则尝试移动敌人
                elif body.has_method("move_and_slide"):
                    body.position += force * delta

            # 造成持续伤害
            var enemy_id = body.get_instance_id()
            var current_time = Time.get_ticks_msec() / 1000.0

            if !affected_enemies.has(enemy_id) or current_time - affected_enemies[enemy_id] >= 0.5:
                body.take_damage(damage_per_second * delta * 2)  # 每0.5秒造成伤害
                affected_enemies[enemy_id] = current_time

    # 黑洞结束时爆炸
    if lifetime >= max_lifetime:
        explode()
        queue_free()

# 爆炸效果
func explode():
    # 创建爆炸视觉效果
    var explosion = CPUParticles2D.new()
    explosion.emitting = true
    explosion.one_shot = true
    explosion.explosiveness = 0.8
    explosion.amount = 100
    explosion.lifetime = 0.5
    explosion.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    explosion.emission_sphere_radius = $Area2D/CollisionShape2D.shape.radius
    explosion.direction = Vector2(0, 0)
    explosion.spread = 180
    explosion.gravity = Vector2(0, 0)
    explosion.initial_velocity_min = 100
    explosion.initial_velocity_max = 200
    explosion.scale_amount = 5
    explosion.color = Color(0.8, 0.2, 1.0, 0.7)
    get_tree().current_scene.add_child(explosion)
    explosion.global_position = global_position

    # 对范围内的敌人造成爆炸伤害
    var area = $Area2D
    var overlapping_bodies = area.get_overlapping_bodies()

    for body in overlapping_bodies:
        if body.is_in_group("enemies"):
            body.take_damage(explosion_damage)

    # 自动清理爆炸效果
    var timer = Timer.new()
    timer.wait_time = 1.0
    timer.one_shot = true
    timer.autostart = true
    explosion.add_child(timer)
    timer.timeout.connect(func(): explosion.queue_free())
"""
    script.reload()
    black_hole.set_script(script)

    # 设置黑洞属性
    black_hole.damage_per_second = damage_per_second
    black_hole.explosion_damage = explosion_damage
    black_hole.pull_force = pull_force

    return black_hole

# 更新活跃的黑洞
func update_black_holes(delta):
    var to_remove = []

    for black_hole in active_black_holes:
        if !is_instance_valid(black_hole):
            to_remove.append(black_hole)

    for black_hole in to_remove:
        active_black_holes.erase(black_hole)

# 获取升级选项
func get_upgrade_options() -> Array:
    return [
        {
            "type": UpgradeType.DAMAGE,
            "name": "伤害 +5/秒",
            "description": "增加黑洞每秒伤害",
            "icon": "💥"
        },
        {
            "type": UpgradeType.SPECIAL,
            "name": "爆炸伤害 +20",
            "description": "增加黑洞爆炸伤害",
            "icon": "💣"
        },
        {
            "type": UpgradeType.AREA,
            "name": "半径 +15",
            "description": "增加黑洞影响范围",
            "icon": "⭕"
        },
        {
            "type": UpgradeType.COOLDOWN,
            "name": "冷却 -0.5秒",
            "description": "减少黑洞冷却时间",
            "icon": "⏱️"
        },
        {
            "type": UpgradeType.EFFECT_DURATION,
            "name": "持续时间 +0.5秒",
            "description": "增加黑洞持续时间",
            "icon": "⌛"
        }
    ]

# 应用升级
func apply_upgrade(upgrade_type: int) -> void:
    match upgrade_type:
        UpgradeType.DAMAGE:
            damage_per_second += 5
        UpgradeType.SPECIAL:
            explosion_damage += 20
        UpgradeType.AREA:
            black_hole_radius += 15
        UpgradeType.COOLDOWN:
            cooldown = max(1.0, cooldown - 0.5)
        UpgradeType.EFFECT_DURATION:
            duration += 0.5

    # 调用父类方法
    super.apply_upgrade(upgrade_type)
