extends "res://scripts/weapons/abstract_weapon.gd"
class_name Boomerang

# 回旋镖属性
var damage = 25              # 伤害
var throw_speed = 400        # 投掷速度
var return_speed = 500       # 返回速度
var max_distance = 300       # 最大投掷距离
var attack_rate = 0.7        # 每秒攻击次数
var boomerang_count = 1      # 回旋镖数量
var hit_count = 3            # 可以击中的敌人数量

# 内部变量
var can_attack = true
var attack_timer = 0.0
var active_boomerangs = []   # 活跃的回旋镖

func _init():
    super._init(
        "boomerang",
        "回旋镖",
        "投掷后会返回玩家，沿途伤害敌人",
        "🪃",
        "special"
    )

func _process(delta):
    # 处理攻击冷却
    if !can_attack:
        attack_timer += delta
        if attack_timer >= 1.0 / attack_rate:
            can_attack = true
            attack_timer = 0.0

    # 如果可以攻击且没有活跃的回旋镖，自动攻击
    if can_attack and active_boomerangs.size() < boomerang_count:
        throw_boomerang()

    # 更新活跃的回旋镖
    update_boomerangs()

# 投掷回旋镖
func throw_boomerang():
    can_attack = false

    # 获取目标方向（最近的敌人）
    var target_direction = get_target_direction()

    # 创建回旋镖
    var boomerang = create_boomerang()

    # 设置属性
    boomerang.damage = damage
    boomerang.throw_speed = throw_speed
    boomerang.return_speed = return_speed
    boomerang.max_distance = max_distance
    boomerang.hit_count = hit_count
    boomerang.direction = target_direction
    boomerang.weapon = self

    # 添加到场景
    get_tree().current_scene.add_child(boomerang)
    boomerang.global_position = global_position

    # 记录活跃的回旋镖
    active_boomerangs.append(boomerang)

    # 触发攻击事件
    perform_attack()

# 获取目标方向
func get_target_direction():
    var enemies = get_tree().get_nodes_in_group("enemies")
    var closest_enemy = null
    var closest_distance = 1000000  # 一个很大的初始值

    for enemy in enemies:
        var distance = global_position.distance_to(enemy.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest_enemy = enemy

    if closest_enemy:
        return (closest_enemy.global_position - global_position).normalized()

    # 如果没有敌人，默认向右
    return Vector2.RIGHT

# 创建回旋镖
func create_boomerang():
    var boomerang = Area2D.new()

    # 添加视觉效果
    var visual = Polygon2D.new()
    var points = []

    # 创建回旋镖形状
    points.append(Vector2(0, -15))
    points.append(Vector2(15, 0))
    points.append(Vector2(0, 15))
    points.append(Vector2(-15, 0))

    visual.polygon = points
    visual.color = Color(1.0, 0.8, 0.2, 0.9)  # 金黄色
    boomerang.add_child(visual)

    # 添加发光效果
    var glow = visual.duplicate()
    glow.color = Color(1.0, 0.9, 0.3, 0.4)
    glow.scale = Vector2(1.3, 1.3)
    glow.z_index = -1
    boomerang.add_child(glow)

    # 添加碰撞形状
    var collision = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = 15
    collision.shape = shape
    boomerang.add_child(collision)

    # 设置碰撞层
    boomerang.collision_layer = 0
    boomerang.collision_mask = 4  # 敌人层

    # 添加脚本
    var script = GDScript.new()
    script.source_code = """
extends Area2D

var damage = 0
var throw_speed = 0
var return_speed = 0
var max_distance = 0
var hit_count = 0
var direction = Vector2.RIGHT
var weapon = null

var state = "throwing"  # throwing, returning
var distance_traveled = 0
var hit_enemies = []
var start_position = Vector2.ZERO

func _ready():
    body_entered.connect(_on_body_entered)
    start_position = global_position

func _process(delta):
    # 旋转效果
    rotation += delta * 10

    # 根据状态移动
    if state == "throwing":
        # 向前移动
        position += direction * throw_speed * delta

        # 计算已行进距离
        distance_traveled = global_position.distance_to(start_position)

        # 检查是否达到最大距离
        if distance_traveled >= max_distance:
            state = "returning"
    else:  # returning
        # 获取返回方向
        var return_direction = Vector2.ZERO
        if weapon and is_instance_valid(weapon):
            return_direction = (weapon.global_position - global_position).normalized()
        else:
            return_direction = (start_position - global_position).normalized()

        # 向玩家移动
        position += return_direction * return_speed * delta

        # 检查是否返回到玩家
        var return_distance = 0
        if weapon and is_instance_valid(weapon):
            return_distance = global_position.distance_to(weapon.global_position)
        else:
            return_distance = global_position.distance_to(start_position)

        if return_distance < 20:
            # 回到玩家，销毁自己
            if weapon and is_instance_valid(weapon):
                # 从活跃列表中移除
                weapon.active_boomerangs.erase(self)
            queue_free()

func _on_body_entered(body):
    if body.is_in_group("enemies") and !hit_enemies.has(body):
        # 造成伤害
        if weapon:
            weapon.handle_enemy_hit(body, damage)
        else:
            body.take_damage(damage)

        # 记录已击中的敌人
        hit_enemies.append(body)

        # 创建击中效果
        create_hit_effect(body.global_position)

        # 检查是否达到最大击中数
        if hit_enemies.size() >= hit_count and state == "throwing":
            state = "returning"

# 创建击中效果
func create_hit_effect(pos):
    var effect = CPUParticles2D.new()
    effect.emitting = true
    effect.one_shot = true
    effect.explosiveness = 0.8
    effect.amount = 10
    effect.lifetime = 0.3
    effect.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    effect.emission_sphere_radius = 5
    effect.direction = Vector2(0, 0)
    effect.spread = 180
    effect.gravity = Vector2(0, 0)
    effect.initial_velocity_min = 30
    effect.initial_velocity_max = 50
    effect.scale_amount = 3
    effect.color = Color(1.0, 0.8, 0.2, 0.7)  # 金黄色
    get_tree().current_scene.add_child(effect)
    effect.global_position = pos

    # 自动清理
    var timer = Timer.new()
    timer.wait_time = 0.5
    timer.one_shot = true
    timer.autostart = true
    effect.add_child(timer)
    timer.timeout.connect(func(): effect.queue_free())
"""
    script.reload()
    boomerang.set_script(script)

    return boomerang

# 更新活跃的回旋镖
func update_boomerangs():
    var to_remove = []

    for boomerang in active_boomerangs:
        if !is_instance_valid(boomerang):
            to_remove.append(boomerang)

    for boomerang in to_remove:
        active_boomerangs.erase(boomerang)

# 获取升级选项
func get_upgrade_options() -> Array:
    return [
        {
            "type": UpgradeType.DAMAGE,
            "name": "伤害 +8",
            "description": "增加回旋镖伤害",
            "icon": "💥"
        },
        {
            "type": UpgradeType.PROJECTILE_COUNT,
            "name": "回旋镖 +1",
            "description": "增加回旋镖数量",
            "icon": "🪃"
        },
        {
            "type": UpgradeType.SPECIAL,
            "name": "击中 +1",
            "description": "增加可击中敌人数量",
            "icon": "🎯"
        },
        {
            "type": UpgradeType.AREA,
            "name": "距离 +50",
            "description": "增加最大投掷距离",
            "icon": "↔️"
        },
        {
            "type": UpgradeType.PROJECTILE_SPEED,
            "name": "速度 +50",
            "description": "增加投掷和返回速度",
            "icon": "💨"
        },
        {
            "type": UpgradeType.ATTACK_SPEED,
            "name": "攻击速度 +20%",
            "description": "增加投掷频率",
            "icon": "🔄"
        }
    ]

# 应用升级
func apply_upgrade(upgrade_type: int) -> void:
    match upgrade_type:
        UpgradeType.DAMAGE:
            damage += 8
        UpgradeType.PROJECTILE_COUNT:
            boomerang_count += 1
        UpgradeType.SPECIAL:
            hit_count += 1
        UpgradeType.AREA:
            max_distance += 50
        UpgradeType.PROJECTILE_SPEED:
            throw_speed += 50
            return_speed += 50
        UpgradeType.ATTACK_SPEED:
            attack_rate *= 1.2

    # 调用父类方法
    super.apply_upgrade(upgrade_type)
