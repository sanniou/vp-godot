extends "res://scripts/weapons/abstract_weapon.gd"
class_name FrostStaff

# 冰霜属性
var damage = 15              # 伤害
var slow_percent = 0.3       # 减速百分比
var slow_duration = 2.0      # 减速持续时间
var attack_rate = 0.8        # 每秒攻击次数
var projectile_speed = 300   # 冰霜弹速度
var projectile_count = 1     # 每次发射的冰霜弹数量
var pierce_count = 0         # 穿透敌人数量

# 内部变量
var can_attack = true
var attack_timer = 0.0
var slowed_enemies = {}      # 被减速的敌人 {enemy_id: {time_remaining, slow_percent}}

func _init():
    super._init(
        "frost_staff",
        "冰霜法杖",
        "减缓敌人移动速度并造成伤害",
        "❄️",
        "magic"
    )

func _process(delta):
    # 处理攻击冷却
    if !can_attack:
        attack_timer += delta
        if attack_timer >= 1.0 / attack_rate:
            can_attack = true
            attack_timer = 0.0

    # 自动攻击
    if can_attack:
        cast_frost()

    # 更新减速效果
    update_slow_effects(delta)

# 施放冰霜
func cast_frost():
    can_attack = false

    # 获取目标（最近的敌人）
    var targets = get_targets()
    if targets.size() == 0:
        return

    # 发射冰霜弹
    for i in range(projectile_count):
        var target = targets[i % targets.size()]
        var projectile = create_frost_projectile()

        # 设置目标和属性
        projectile.target = target
        projectile.damage = damage
        projectile.speed = projectile_speed
        projectile.pierce_count = pierce_count
        projectile.slow_percent = slow_percent
        projectile.slow_duration = slow_duration
        projectile.weapon = self

        # 添加到场景
        get_tree().current_scene.add_child(projectile)
        projectile.global_position = global_position

    # 触发攻击事件
    perform_attack()

# 获取目标
func get_targets():
    var enemies = get_tree().get_nodes_in_group("enemies")
    if enemies.size() == 0:
        return []

    # 按距离排序
    enemies.sort_custom(func(a, b):
        return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
    )

    # 返回最近的几个敌人
    return enemies.slice(0, min(projectile_count, enemies.size()))

# 创建冰霜弹
func create_frost_projectile():
    var projectile = Area2D.new()

    # 添加视觉效果
    var visual = Polygon2D.new()
    var points = []

    # 创建冰晶形状
    var sides = 6
    var radius = 10
    for i in range(sides):
        var angle = 2 * PI * i / sides
        points.append(Vector2(cos(angle), sin(angle)) * radius)

    visual.polygon = points
    visual.color = Color(0.7, 0.9, 1.0, 0.8)  # 淡蓝色
    projectile.add_child(visual)

    # 添加发光效果
    var glow = visual.duplicate()
    glow.color = Color(0.8, 0.95, 1.0, 0.4)
    glow.scale = Vector2(1.5, 1.5)
    glow.z_index = -1
    projectile.add_child(glow)

    # 添加粒子效果
    var particles = CPUParticles2D.new()
    particles.amount = 20
    particles.lifetime = 0.5
    particles.local_coords = false
    particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    particles.emission_sphere_radius = 5
    particles.direction = Vector2(0, 0)
    particles.spread = 180
    particles.gravity = Vector2(0, 0)
    particles.initial_velocity_min = 10
    particles.initial_velocity_max = 20
    particles.scale_amount = 2
    particles.color = Color(0.8, 0.95, 1.0, 0.5)  # 淡蓝色
    projectile.add_child(particles)

    # 添加碰撞形状
    var collision = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = radius
    collision.shape = shape
    projectile.add_child(collision)

    # 设置碰撞层
    projectile.collision_layer = 0
    projectile.collision_mask = 4  # 敌人层

    # 添加脚本
    var script = GDScript.new()
    script.source_code = """
extends Area2D

var target = null
var damage = 0
var speed = 300
var pierce_count = 0
var slow_percent = 0.3
var slow_duration = 2.0
var weapon = null
var pierced_enemies = []
var lifetime = 0.0
var max_lifetime = 5.0

func _ready():
    body_entered.connect(_on_body_entered)

func _process(delta):
    lifetime += delta

    # 如果目标无效，自动销毁
    if !is_instance_valid(target):
        queue_free()
        return

    # 移动向目标
    var direction = (target.global_position - global_position).normalized()
    position += direction * speed * delta

    # 旋转效果
    rotation += delta * 3

    # 如果超过最大生命周期，自动销毁
    if lifetime >= max_lifetime:
        queue_free()

func _on_body_entered(body):
    if body.is_in_group("enemies") and !pierced_enemies.has(body):
        # 造成伤害
        if weapon:
            weapon.handle_enemy_hit(body, damage)
        else:
            body.take_damage(damage)

        # 应用减速效果
        apply_slow(body)

        # 记录已穿透的敌人
        pierced_enemies.append(body)

        # 检查是否需要销毁
        if pierce_count <= 0 or pierced_enemies.size() > pierce_count:
            # 创建冰冻效果
            create_freeze_effect()
            queue_free()

# 应用减速效果
func apply_slow(enemy):
    if !weapon:
        return

    var enemy_id = enemy.get_instance_id()

    # 如果敌人已经被减速，刷新持续时间并使用较大的减速值
    if enemy_id in weapon.slowed_enemies:
        weapon.slowed_enemies[enemy_id].time_remaining = slow_duration
        weapon.slowed_enemies[enemy_id].slow_percent = max(weapon.slowed_enemies[enemy_id].slow_percent, slow_percent)
    else:
        # 添加新的减速效果
        weapon.slowed_enemies[enemy_id] = {
            "time_remaining": slow_duration,
            "slow_percent": slow_percent,
            "enemy": enemy,
            "original_speed": get_enemy_speed(enemy)
        }

        # 减缓敌人速度
        set_enemy_speed(enemy, get_enemy_speed(enemy) * (1 - slow_percent))

        # 添加视觉效果
        var slow_effect = create_slow_effect()
        enemy.add_child(slow_effect)

# 获取敌人速度
func get_enemy_speed(enemy):
    if "move_speed" in enemy:
        return enemy.move_speed
    return 100  # 默认值

# 设置敌人速度
func set_enemy_speed(enemy, speed):
    if "move_speed" in enemy:
        enemy.move_speed = speed

# 创建冰冻效果
func create_freeze_effect():
    var effect = CPUParticles2D.new()
    effect.emitting = true
    effect.one_shot = true
    effect.explosiveness = 0.8
    effect.amount = 20
    effect.lifetime = 0.5
    effect.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    effect.emission_sphere_radius = 10
    effect.direction = Vector2(0, 0)
    effect.spread = 180
    effect.gravity = Vector2(0, 0)
    effect.initial_velocity_min = 30
    effect.initial_velocity_max = 50
    effect.scale_amount = 3
    effect.color = Color(0.8, 0.95, 1.0, 0.7)  # 淡蓝色
    get_tree().current_scene.add_child(effect)
    effect.global_position = global_position

    # 自动清理
    var timer = Timer.new()
    timer.wait_time = 1.0
    timer.one_shot = true
    timer.autostart = true
    effect.add_child(timer)
    timer.timeout.connect(func(): effect.queue_free())

# 创建减速视觉效果
func create_slow_effect():
    var effect = Polygon2D.new()
    var points = []

    # 创建雪花形状
    var sides = 6
    var radius = 15
    for i in range(sides):
        var angle = 2 * PI * i / sides
        points.append(Vector2(cos(angle), sin(angle)) * radius)

    effect.polygon = points
    effect.color = Color(0.8, 0.95, 1.0, 0.3)  # 半透明淡蓝色

    # 添加脚本
    var script = GDScript.new()
    script.source_code = '''
extends Polygon2D

var parent_id = 0
var pulse_time = 0.0

func _ready():
    parent_id = get_parent().get_instance_id()

func _process(delta):
    # 脉动效果
    pulse_time += delta
    var pulse = sin(pulse_time * 3) * 0.2 + 0.8
    scale = Vector2(pulse, pulse)

    # 如果父节点不再减速，自动销毁
    var weapon = get_tree().current_scene.find_child("frost_staff", true, false)
    if weapon and !weapon.slowed_enemies.has(parent_id):
        queue_free()
'''
    script.reload()
    effect.set_script(script)

    return effect
"""
    script.reload()
    projectile.set_script(script)

    return projectile

# 更新减速效果
func update_slow_effects(delta):
    var to_remove = []

    for enemy_id in slowed_enemies:
        var slow_data = slowed_enemies[enemy_id]

        # 减少剩余时间
        slow_data.time_remaining -= delta

        # 检查是否应该移除
        if slow_data.time_remaining <= 0 or !is_instance_valid(slow_data.enemy):
            to_remove.append(enemy_id)
            continue

    # 移除过期的减速效果
    for enemy_id in to_remove:
        var slow_data = slowed_enemies[enemy_id]

        # 恢复敌人原始速度
        if is_instance_valid(slow_data.enemy):
            if "move_speed" in slow_data.enemy:
                slow_data.enemy.move_speed = slow_data.original_speed

        slowed_enemies.erase(enemy_id)

# 获取升级选项
func get_upgrade_options() -> Array:
    return [
        {
            "type": UpgradeType.DAMAGE,
            "name": "伤害 +5",
            "description": "增加冰霜伤害",
            "icon": "💥"
        },
        {
            "type": UpgradeType.SPECIAL,
            "name": "减速 +10%",
            "description": "增加减速效果",
            "icon": "❄️"
        },
        {
            "type": UpgradeType.EFFECT_DURATION,
            "name": "减速持续 +1秒",
            "description": "增加减速持续时间",
            "icon": "⌛"
        },
        {
            "type": UpgradeType.PROJECTILE_COUNT,
            "name": "冰霜弹 +1",
            "description": "增加每次发射的冰霜弹数量",
            "icon": "🔷"
        },
        {
            "type": UpgradeType.PROJECTILE_SPEED,
            "name": "弹速 +50",
            "description": "增加冰霜弹速度",
            "icon": "💨"
        },
        {
            "type": UpgradeType.ATTACK_SPEED,
            "name": "攻击速度 +20%",
            "description": "增加攻击频率",
            "icon": "🔄"
        }
    ]

# 应用升级
func apply_upgrade(upgrade_type: int) -> void:
    match upgrade_type:
        UpgradeType.DAMAGE:
            damage += 5
        UpgradeType.SPECIAL:
            slow_percent = min(0.8, slow_percent + 0.1)  # 最大减速80%
        UpgradeType.EFFECT_DURATION:
            slow_duration += 1.0
        UpgradeType.PROJECTILE_COUNT:
            projectile_count += 1
        UpgradeType.PROJECTILE_SPEED:
            projectile_speed += 50
        UpgradeType.ATTACK_SPEED:
            attack_rate *= 1.2

    # 调用父类方法
    super.apply_upgrade(upgrade_type)
