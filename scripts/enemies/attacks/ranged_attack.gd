extends "res://scripts/enemies/attacks/abstract_attack.gd"

var projectile_speed = 200.0
var projectile_lifetime = 3.0

func _init():
    super._init(AttackType.RANGED)

    # 设置远程攻击特有属性
    cooldown = 1.5
    slow_chance = 0.2
    slow_factor = 0.7
    slow_duration = 1.0

# 重写远程攻击实现
func perform_ranged_attack():
    if !owner_enemy or !owner_enemy.target:
        return

    # 创建投射物
    var projectile = create_projectile()
    if projectile:
        # 设置投射物属性
        projectile.damage = damage
        projectile.speed = projectile_speed
        projectile.max_lifetime = projectile_lifetime
        projectile.source = owner_enemy
        projectile.target = owner_enemy.target

        # 设置状态效果
        projectile.slow_chance = slow_chance
        projectile.slow_factor = slow_factor
        projectile.slow_duration = slow_duration

        # 计算方向
        var direction = (owner_enemy.target.global_position - owner_enemy.global_position).normalized()
        projectile.direction = direction

        # 添加到场景
        owner_enemy.get_tree().current_scene.add_child(projectile)
        projectile.global_position = owner_enemy.global_position

        # 播放攻击动画
        play_attack_animation()

# 重写创建投射物
func create_projectile():
    var projectile = EnemyProjectile.new()
    return projectile

# 重写攻击动画
func play_attack_animation():
    if !owner_enemy:
        return

    # 创建攻击效果
    var attack_effect = ColorRect.new()
    attack_effect.color = Color(0.5, 0.5, 1.0, 0.7)  # 蓝色半透明

    # 计算朝向目标的方向
    var direction = Vector2.RIGHT
    if owner_enemy.target:
        direction = (owner_enemy.target.global_position - owner_enemy.global_position).normalized()

    # 设置攻击效果的大小和位置
    attack_effect.size = Vector2(20, 5)
    attack_effect.position = Vector2(0, -2.5)

    # 创建容器节点以便旋转
    var container = Node2D.new()
    container.rotation = direction.angle()
    container.add_child(attack_effect)

    owner_enemy.add_child(container)

    # 动画效果
    var tween = owner_enemy.create_tween()
    tween.tween_property(attack_effect, "modulate:a", 0, 0.2)
    tween.tween_callback(func(): container.queue_free())
