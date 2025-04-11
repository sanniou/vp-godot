extends Node
class_name AbstractAttack

# 攻击类型枚举
enum AttackType {
    MELEE,      # 近战攻击
    RANGED,     # 远程攻击
    AREA,       # 范围攻击
    SPECIAL     # 特殊攻击
}

# 基本属性
var attack_type: int = AttackType.MELEE
var damage: float = 10.0
var range: float = 50.0
var cooldown: float = 1.0  # 冷却时间
var attack_speed: float = 1.0  # 攻击速度倍率

# 特殊属性
var knockback_force: float = 0.0  # 击退力度
var stun_chance: float = 0.0      # 眩晕几率 (0.0 - 1.0)
var stun_duration: float = 0.0    # 眩晕持续时间
var slow_chance: float = 0.0      # 减速几率 (0.0 - 1.0)
var slow_factor: float = 1.0      # 减速因子 (0.0 - 1.0)
var slow_duration: float = 0.0    # 减速持续时间
var burn_chance: float = 0.0      # 燃烧几率 (0.0 - 1.0)
var burn_damage: float = 0.0      # 每秒燃烧伤害
var burn_duration: float = 0.0    # 燃烧持续时间

# 引用
var owner_enemy = null  # 拥有此攻击的敌人

# 内部状态
var can_attack: bool = true
var cooldown_timer: float = 0.0

# 构造函数
func _init(type: int = AttackType.MELEE):
    attack_type = type

# 设置攻击
func setup(enemy, base_damage, attack_range):
    owner_enemy = enemy
    damage = base_damage
    range = attack_range
    
    # 根据攻击类型设置特殊属性
    match attack_type:
        AttackType.MELEE:
            knockback_force = 100.0
        AttackType.RANGED:
            cooldown = 1.5
        AttackType.AREA:
            cooldown = 2.0
            range *= 1.5
        AttackType.SPECIAL:
            cooldown = 3.0
            damage *= 2.0
            stun_chance = 0.3
            stun_duration = 1.0

# 执行攻击
func perform_attack():
    if !can_attack or !owner_enemy or !owner_enemy.target:
        return
    
    # 根据攻击类型执行不同的攻击逻辑
    match attack_type:
        AttackType.MELEE:
            perform_melee_attack()
        AttackType.RANGED:
            perform_ranged_attack()
        AttackType.AREA:
            perform_area_attack()
        AttackType.SPECIAL:
            perform_special_attack()
    
    # 设置冷却
    can_attack = false
    cooldown_timer = cooldown / attack_speed

# 近战攻击
func perform_melee_attack():
    # 子类可以重写此方法实现特定的近战攻击
    if owner_enemy.target and owner_enemy.global_position.distance_to(owner_enemy.target.global_position) <= range:
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

# 远程攻击
func perform_ranged_attack():
    # 子类可以重写此方法实现特定的远程攻击
    # 创建投射物
    var projectile = create_projectile()
    if projectile:
        # 设置投射物属性
        projectile.damage = damage
        projectile.source = owner_enemy
        
        # 计算方向
        var direction = (owner_enemy.target.global_position - owner_enemy.global_position).normalized()
        projectile.direction = direction
        
        # 添加到场景
        owner_enemy.get_tree().current_scene.add_child(projectile)
        projectile.global_position = owner_enemy.global_position
        
        # 播放攻击动画
        play_attack_animation()

# 范围攻击
func perform_area_attack():
    # 子类可以重写此方法实现特定的范围攻击
    # 获取范围内的所有玩家
    var players = owner_enemy.get_tree().get_nodes_in_group("player")
    for player in players:
        if owner_enemy.global_position.distance_to(player.global_position) <= range:
            # 造成伤害
            if player.has_method("take_damage"):
                player.take_damage(damage)
            
            # 应用状态效果
            apply_status_effects(player)
    
    # 播放攻击动画
    play_area_attack_animation()

# 特殊攻击
func perform_special_attack():
    # 子类可以重写此方法实现特定的特殊攻击
    # 这里可以实现复杂的攻击模式，如多段攻击、召唤小怪等
    pass

# 创建投射物
func create_projectile():
    # 子类可以重写此方法创建特定的投射物
    var projectile = Node2D.new()
    projectile.set_script(load("res://scripts/enemies/attacks/enemy_projectile.gd"))
    return projectile

# 应用状态效果
func apply_status_effects(target):
    if !target:
        return
    
    # 应用眩晕
    if stun_chance > 0 and randf() < stun_chance and target.has_method("apply_status_effect"):
        target.apply_status_effect("stun", stun_duration)
    
    # 应用减速
    if slow_chance > 0 and randf() < slow_chance and target.has_method("apply_status_effect"):
        target.apply_status_effect("slow", slow_duration, slow_factor)
    
    # 应用燃烧
    if burn_chance > 0 and randf() < burn_chance and target.has_method("apply_status_effect"):
        target.apply_status_effect("burn", burn_duration, burn_damage)

# 播放攻击动画
func play_attack_animation():
    # 子类可以重写此方法播放特定的攻击动画
    if owner_enemy:
        var attack_effect = ColorRect.new()
        attack_effect.color = Color(1, 1, 0, 0.5)  # 黄色半透明
        attack_effect.size = Vector2(30, 10)
        attack_effect.position = Vector2(-15, -5)
        owner_enemy.add_child(attack_effect)
        
        # 动画效果
        var tween = owner_enemy.create_tween()
        tween.tween_property(attack_effect, "modulate:a", 0, 0.2)
        tween.tween_callback(func(): attack_effect.queue_free())

# 播放范围攻击动画
func play_area_attack_animation():
    # 子类可以重写此方法播放特定的范围攻击动画
    if owner_enemy:
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
        circle.color = Color(1, 0.5, 0, 0.3)  # 橙色半透明
        attack_effect.add_child(circle)
        
        # 动画效果
        var tween = owner_enemy.create_tween()
        tween.tween_property(circle, "scale", Vector2(1.2, 1.2), 0.3)
        tween.parallel().tween_property(circle, "modulate:a", 0, 0.3)
        tween.tween_callback(func(): attack_effect.queue_free())

# 更新
func _process(delta):
    # 更新冷却计时器
    if !can_attack:
        cooldown_timer -= delta
        if cooldown_timer <= 0:
            can_attack = true
