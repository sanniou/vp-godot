extends "res://scripts/weapons/abstract_weapon.gd"
class_name ToxicSpray

# 毒素属性
var initial_damage = 5       # 初始伤害
var dot_damage = 3           # 每秒持续伤害
var dot_duration = 3.0       # 持续伤害持续时间
var spray_range = 150        # 喷雾范围
var spray_angle = PI / 3     # 喷雾角度（弧度）
var attack_rate = 1.0        # 每秒攻击次数

# 内部变量
var can_attack = true
var attack_timer = 0.0
var poisoned_enemies = {}    # 中毒的敌人 {enemy_id: {time_remaining, damage}}

func _init():
    super._init(
        "toxic_spray",
        "毒素喷雾",
        "喷射毒素，对敌人造成持续伤害",
        "☣️",
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
        spray_toxin()

    # 更新中毒效果
    update_poison_effects(delta)

# 喷射毒素
func spray_toxin():
    can_attack = false

    # 获取攻击方向（朝向最近的敌人）
    var attack_direction = get_attack_direction()

    # 创建喇雾效果
    var spray = create_spray_effect(attack_direction)

    # 检查喇雾对象是否有效
    if spray != null:
        get_tree().current_scene.add_child(spray)
        spray.global_position = global_position
    else:
        print("Warning: Failed to create spray effect")

    # 检测范围内的敌人并造成伤害
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        var to_enemy = enemy.global_position - global_position
        var distance = to_enemy.length()

        # 检查敌人是否在攻击范围内
        if distance <= spray_range:
            # 检查敌人是否在攻击角度内
            var angle_to_enemy = attack_direction.angle_to(to_enemy.normalized())
            if abs(angle_to_enemy) <= spray_angle / 2:
                # 造成初始伤害
                handle_enemy_hit(enemy, initial_damage)

                # 添加中毒效果
                apply_poison(enemy)

    # 触发攻击事件
    perform_attack()

# 获取攻击方向
func get_attack_direction():
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

# 创建喷雾效果
func create_spray_effect(direction):
    var spray = Node2D.new()

    # 设置旋转
    spray.rotation = direction.angle()

    # 创建粒子效果
    var particles = CPUParticles2D.new()
    particles.amount = 100
    particles.lifetime = 0.8
    particles.explosiveness = 0.2
    particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    particles.emission_sphere_radius = 5
    particles.direction = Vector2(1, 0)  # 向前喷射
    particles.spread = spray_angle * 180 / PI  # 转换为角度
    particles.gravity = Vector2(0, 0)
    particles.initial_velocity_min = spray_range / particles.lifetime * 0.8
    particles.initial_velocity_max = spray_range / particles.lifetime
    # 设置粒子缩放范围（随机缩放）
    particles.set_param_min(CPUParticles2D.PARAM_SCALE, 1.5)
    particles.set_param_max(CPUParticles2D.PARAM_SCALE, 3.0)
    particles.color = Color(0.2, 0.8, 0.2, 0.7)  # 绿色
    spray.add_child(particles)

    # 添加脚本
    var script = GDScript.new()
    script.source_code = """
extends Node2D

var lifetime = 0.0
var max_lifetime = 0.8

func _process(delta):
    lifetime += delta

    # 淡出效果
    $CPUParticles2D.modulate.a = 1.0 - (lifetime / max_lifetime)

    if lifetime >= max_lifetime:
        queue_free()
"""
    script.reload()
    spray.set_script(script)

    return spray

# 应用中毒效果
func apply_poison(enemy):
    var enemy_id = enemy.get_instance_id()

    # 如果敌人已经中毒，刷新持续时间并增加伤害
    if enemy_id in poisoned_enemies:
        poisoned_enemies[enemy_id].time_remaining = dot_duration
        poisoned_enemies[enemy_id].damage = max(poisoned_enemies[enemy_id].damage, dot_damage)
    else:
        # 添加新的中毒效果
        poisoned_enemies[enemy_id] = {
            "time_remaining": dot_duration,
            "damage": dot_damage,
            "enemy": enemy,
            "last_tick": 0.0
        }

        # 添加视觉效果
        if is_instance_valid(enemy):
            var poison_effect = create_poison_effect()
            enemy.add_child(poison_effect)

# 创建中毒视觉效果
func create_poison_effect():
    var effect = CPUParticles2D.new()
    effect.amount = 10
    effect.lifetime = 1.0
    effect.local_coords = false
    effect.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    effect.emission_sphere_radius = 20
    effect.direction = Vector2(0, -1)
    effect.spread = 90
    effect.gravity = Vector2(0, -20)
    effect.initial_velocity_min = 5
    effect.initial_velocity_max = 10
    effect.set_param_min(CPUParticles2D.PARAM_SCALE, 2.0)
    effect.set_param_max(CPUParticles2D.PARAM_SCALE, 2.0)
    effect.color = Color(0.2, 0.8, 0.2, 0.5)  # 绿色

    # 添加脚本
    var script = GDScript.new()
    script.source_code = """
extends CPUParticles2D

var parent_id = 0

func _ready():
    parent_id = get_parent().get_instance_id()

func _process(_delta):
    # 如果父节点不再中毒，自动销毁
    var weapon = get_tree().current_scene.find_child("toxic_spray", true, false)
    if weapon and !weapon.poisoned_enemies.has(parent_id):
        queue_free()
"""
    script.reload()
    effect.set_script(script)

    return effect

# 更新中毒效果
func update_poison_effects(delta):
    var to_remove = []

    for enemy_id in poisoned_enemies:
        var poison_data = poisoned_enemies[enemy_id]

        # 减少剩余时间
        poison_data.time_remaining -= delta

        # 检查是否应该移除
        if poison_data.time_remaining <= 0 or !is_instance_valid(poison_data.enemy):
            to_remove.append(enemy_id)
            continue

        # 每秒造成伤害
        poison_data.last_tick += delta
        if poison_data.last_tick >= 1.0:
            poison_data.last_tick = 0.0

            # 造成持续伤害
            if is_instance_valid(poison_data.enemy):
                poison_data.enemy.take_damage(poison_data.damage)

                # 检查是否击杀
                if poison_data.enemy.current_health <= 0:
                    handle_enemy_killed(poison_data.enemy, poison_data.enemy.global_position)

    # 移除过期的中毒效果
    for enemy_id in to_remove:
        poisoned_enemies.erase(enemy_id)

# 获取升级选项
func get_upgrade_options() -> Array:
    return [
        {
            "type": UpgradeType.DAMAGE,
            "name": "初始伤害 +3",
            "description": "增加毒素初始伤害",
            "icon": "💥"
        },
        {
            "type": UpgradeType.SPECIAL,
            "name": "中毒伤害 +2/秒",
            "description": "增加毒素持续伤害",
            "icon": "☣️"
        },
        {
            "type": UpgradeType.EFFECT_DURATION,
            "name": "中毒持续 +1秒",
            "description": "增加中毒持续时间",
            "icon": "⌛"
        },
        {
            "type": UpgradeType.AREA,
            "name": "喷雾范围 +30",
            "description": "增加喷雾范围",
            "icon": "⭕"
        },
        {
            "type": UpgradeType.ATTACK_SPEED,
            "name": "喷射速度 +20%",
            "description": "增加喷射频率",
            "icon": "🔄"
        }
    ]

# 应用升级
func apply_upgrade(upgrade_type: int) -> void:
    match upgrade_type:
        UpgradeType.DAMAGE:
            initial_damage += 3
        UpgradeType.SPECIAL:
            dot_damage += 2
        UpgradeType.EFFECT_DURATION:
            dot_duration += 1.0
        UpgradeType.AREA:
            spray_range += 30
        UpgradeType.ATTACK_SPEED:
            attack_rate *= 1.2

    # 调用父类方法
    super.apply_upgrade(upgrade_type)
