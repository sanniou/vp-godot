extends Area2D
class_name EnemyProjectile

# 基本属性
var damage: float = 10.0
var speed: float = 200.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0
var max_lifetime: float = 3.0

# 特殊属性
var piercing: bool = false  # 是否穿透
var piercing_count: int = 0  # 穿透次数
var homing: bool = false    # 是否追踪
var homing_strength: float = 0.0  # 追踪强度
var explosion_radius: float = 0.0  # 爆炸半径
var explosion_damage: float = 0.0  # 爆炸伤害

# 状态效果
var stun_chance: float = 0.0
var stun_duration: float = 0.0
var slow_chance: float = 0.0
var slow_factor: float = 1.0
var slow_duration: float = 0.0
var burn_chance: float = 0.0
var burn_damage: float = 0.0
var burn_duration: float = 0.0

# 引用
var source = null  # 发射此投射物的敌人
var target = null  # 目标

func _ready():
    # 连接信号
    body_entered.connect(_on_body_entered)
    
    # 设置碰撞
    var collision = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = 5
    collision.shape = shape
    add_child(collision)
    
    # 设置碰撞层
    collision_layer = 0
    collision_mask = 2  # 玩家层
    
    # 设置视觉效果
    setup_visuals()

# 设置视觉效果
func setup_visuals():
    var visual = ColorRect.new()
    visual.color = Color(1, 0, 0, 1)  # 红色
    visual.size = Vector2(10, 10)
    visual.position = Vector2(-5, -5)
    add_child(visual)
    
    # 添加拖尾效果
    var trail = Line2D.new()
    trail.width = 5
    trail.default_color = Color(1, 0, 0, 0.5)  # 半透明红色
    trail.name = "Trail"
    add_child(trail)

# 更新
func _process(delta):
    # 更新生命周期
    lifetime += delta
    if lifetime >= max_lifetime:
        queue_free()
        return
    
    # 更新位置
    var velocity = direction * speed
    
    # 如果启用追踪，调整方向朝向目标
    if homing and target and is_instance_valid(target):
        var target_direction = (target.global_position - global_position).normalized()
        direction = direction.lerp(target_direction, homing_strength * delta)
        velocity = direction * speed
    
    position += velocity * delta
    
    # 更新拖尾效果
    update_trail()

# 更新拖尾效果
func update_trail():
    var trail = get_node_or_null("Trail")
    if trail:
        # 添加当前位置到拖尾
        trail.add_point(Vector2.ZERO)
        
        # 限制拖尾长度
        if trail.get_point_count() > 10:
            trail.remove_point(0)
        
        # 更新拖尾点的透明度
        for i in range(trail.get_point_count()):
            var alpha = float(i) / trail.get_point_count()
            trail.set_point_color(i, Color(1, 0, 0, alpha * 0.5))

# 碰撞处理
func _on_body_entered(body):
    if body.is_in_group("player"):
        # 造成伤害
        if body.has_method("take_damage"):
            body.take_damage(damage)
        
        # 应用状态效果
        apply_status_effects(body)
        
        # 处理爆炸
        if explosion_radius > 0:
            explode()
        
        # 处理穿透
        if piercing and piercing_count > 0:
            piercing_count -= 1
        else:
            # 销毁投射物
            queue_free()

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

# 爆炸
func explode():
    # 获取爆炸范围内的所有玩家
    var players = get_tree().get_nodes_in_group("player")
    for player in players:
        var distance = global_position.distance_to(player.global_position)
        if distance <= explosion_radius:
            # 计算伤害衰减
            var damage_factor = 1.0 - (distance / explosion_radius)
            var final_damage = explosion_damage * damage_factor
            
            # 造成伤害
            if player.has_method("take_damage"):
                player.take_damage(final_damage)
            
            # 应用状态效果
            apply_status_effects(player)
    
    # 播放爆炸效果
    play_explosion_effect()

# 播放爆炸效果
func play_explosion_effect():
    var explosion = CPUParticles2D.new()
    explosion.emitting = true
    explosion.one_shot = true
    explosion.explosiveness = 0.8
    explosion.amount = 30
    explosion.lifetime = 0.5
    explosion.direction = Vector2(0, -1)
    explosion.spread = 180
    explosion.gravity = Vector2(0, 0)
    explosion.initial_velocity_min = 50
    explosion.initial_velocity_max = 100
    explosion.scale_amount = 3
    explosion.color = Color(1.0, 0.5, 0.0, 1.0)  # 橙色
    
    get_tree().current_scene.add_child(explosion)
    explosion.global_position = global_position
    
    # 自动删除
    var timer = Timer.new()
    timer.wait_time = 1.0
    timer.one_shot = true
    timer.autostart = true
    explosion.add_child(timer)
    
    timer.timeout.connect(func(): explosion.queue_free())
