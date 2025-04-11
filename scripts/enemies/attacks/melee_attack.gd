extends "res://scripts/enemies/attacks/abstract_attack.gd"

func _init():
    super._init(AttackType.MELEE)

    # 设置近战攻击特有属性
    knockback_force = 100.0
    stun_chance = 0.1
    stun_duration = 0.5

# 重写近战攻击实现
func perform_melee_attack():
    if !owner_enemy or !owner_enemy.target:
        return

    # 检查距离
    var distance = owner_enemy.global_position.distance_to(owner_enemy.target.global_position)
    if distance <= range:
        # 造成伤害
        if owner_enemy.target.has_method("take_damage"):
            owner_enemy.target.take_damage(damage)

        # 应用击退
        if knockback_force > 0 and owner_enemy.target.has_method("apply_knockback"):
            var direction = (owner_enemy.target.global_position - owner_enemy.global_position).normalized()
            owner_enemy.target.apply_knockback(direction, knockback_force)

        # 应用状态效果
        apply_status_effects(owner_enemy.target)

        # 播放攻击动画
        play_attack_animation()

# 重写攻击动画
func play_attack_animation():
    if !owner_enemy:
        return

    # 创建攻击效果
    var attack_effect = ColorRect.new()
    attack_effect.color = Color(1, 0.5, 0, 0.7)  # 橙色半透明

    # 计算朝向目标的方向
    var direction = Vector2.RIGHT
    if owner_enemy.target:
        direction = (owner_enemy.target.global_position - owner_enemy.global_position).normalized()

    # 设置攻击效果的大小和位置
    attack_effect.size = Vector2(range, 10)
    attack_effect.position = Vector2(0, -5)

    # 创建容器节点以便旋转
    var container = Node2D.new()
    container.rotation = direction.angle()
    container.add_child(attack_effect)

    owner_enemy.add_child(container)

    # 动画效果
    var tween = owner_enemy.create_tween()
    tween.tween_property(attack_effect, "modulate:a", 0, 0.2)
    tween.tween_callback(func(): container.queue_free())
