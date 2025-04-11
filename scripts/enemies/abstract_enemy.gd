extends CharacterBody2D
class_name AbstractEnemy

# 信号
signal died(position, experience)
signal damaged(amount)

# 敌人类型枚举
enum EnemyType {
    MELEE,      # 近战敌人
    RANGED,     # 远程敌人
    ELITE,      # 精英敌人
    BOSS        # Boss敌人
}

# 基本属性
var enemy_id: String = ""
var enemy_name: String = "抽象敌人"
var enemy_type: int = EnemyType.MELEE
var level: int = 1
var experience_value: int = 10

# 生命属性
var max_health: float = 100.0
var current_health: float = 100.0
var shield: float = 0.0           # 护盾值
var shield_regeneration: float = 0.0  # 每秒护盾恢复量

# 抗性属性 (0.0 - 1.0，表示减免百分比)
var physical_resistance: float = 0.0  # 物理抗性
var magic_resistance: float = 0.0     # 魔法抗性
var fire_resistance: float = 0.0      # 火焰抗性
var lightning_resistance: float = 0.0 # 闪电抗性

# 移动属性
var move_speed: float = 100.0
var target = null
var target_position: Vector2 = Vector2.ZERO
var knockback_resistance: float = 0.0  # 击退抗性 (0.0 - 1.0)

# 攻击属性
var attack_range: float = 50.0
var attack_damage: float = 10.0
var attack_speed: float = 1.0  # 每秒攻击次数
var attack_timer: float = 0.0
var can_attack: bool = true

# 技能系统
var skills = []  # 技能列表
var active_skill = null  # 当前激活的技能

# 内部状态
var is_stunned: bool = false
var stun_timer: float = 0.0
var is_slowed: bool = false
var slow_factor: float = 1.0
var slow_timer: float = 0.0
var is_burning: bool = false
var burn_damage: float = 0.0
var burn_timer: float = 0.0

# 攻击系统
var attack_system = null

# 构造函数
func _init(id: String, name: String, type: int = EnemyType.MELEE):
    enemy_id = id
    enemy_name = name
    enemy_type = type

    # 根据敌人类型设置基本属性
    match type:
        EnemyType.MELEE:
            max_health = 100.0
            move_speed = 100.0
            attack_damage = 10.0
            attack_range = 50.0
            experience_value = 10
        EnemyType.RANGED:
            max_health = 80.0
            move_speed = 80.0
            attack_damage = 15.0
            attack_range = 200.0
            experience_value = 15
        EnemyType.ELITE:
            max_health = 200.0
            move_speed = 90.0
            attack_damage = 20.0
            attack_range = 70.0
            physical_resistance = 0.2
            magic_resistance = 0.2
            experience_value = 30
        EnemyType.BOSS:
            max_health = 1000.0
            move_speed = 70.0
            attack_damage = 30.0
            attack_range = 100.0
            physical_resistance = 0.3
            magic_resistance = 0.3
            shield = 200.0
            shield_regeneration = 5.0
            knockback_resistance = 0.5
            experience_value = 100

    current_health = max_health

# 初始化
func _ready():
    # 添加到敌人组
    add_to_group("enemies")

    # 初始化碰撞
    setup_collision()

    # 初始化视觉效果
    setup_visuals()

    # 初始化攻击系统
    setup_attack_system()

    # 初始化技能
    setup_skills()

    # 调试输出
    # print("Enemy created: ", enemy_name, ", health: ", current_health, "/", max_health)

    # 检查生命条
    var health_bar = find_child("HealthBar")
    # if health_bar:
    #     print("Health bar found: max_value = ", health_bar.max_value, ", value = ", health_bar.value)
    # else:
    #     print("Health bar not found!")

# 设置碰撞
func setup_collision():
    # 子类可以重写此方法设置特定的碰撞
    var collision_shape = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = 20
    collision_shape.shape = shape
    add_child(collision_shape)

    # 设置碰撞层
    collision_layer = 4  # 敌人层
    collision_mask = 3   # 玩家层和墙壁层

# 设置视觉效果
func setup_visuals():
    # 子类可以重写此方法设置特定的视觉效果
    var visual = ColorRect.new()
    visual.color = Color(1, 0, 0, 1)  # 红色
    visual.size = Vector2(40, 40)
    visual.position = Vector2(-20, -20)
    add_child(visual)

    # 添加生命条
    var health_bar = ProgressBar.new()
    health_bar.name = "HealthBar"  # 给生命条命名，便于查找
    health_bar.max_value = max_health
    health_bar.value = current_health
    health_bar.size = Vector2(40, 5)
    health_bar.position = Vector2(-20, -30)

    # 设置生命条样式
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.8, 0, 0, 1)  # 红色生命条
    style_box.corner_radius_top_left = 2
    style_box.corner_radius_top_right = 2
    style_box.corner_radius_bottom_left = 2
    style_box.corner_radius_bottom_right = 2
    health_bar.add_theme_stylebox_override("fill", style_box)

    # 设置背景样式
    var bg_style = StyleBoxFlat.new()
    bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # 灰色背景
    bg_style.corner_radius_top_left = 2
    bg_style.corner_radius_top_right = 2
    bg_style.corner_radius_bottom_left = 2
    bg_style.corner_radius_bottom_right = 2
    health_bar.add_theme_stylebox_override("background", bg_style)

    # 添加到敌人
    add_child(health_bar)

    # 调试输出
    # print("Health bar created: max_value = ", health_bar.max_value, ", value = ", health_bar.value)

# 设置攻击系统
func setup_attack_system():
    # 子类可以重写此方法设置特定的攻击系统
    attack_system = load("res://scripts/enemies/attacks/melee_attack.gd").new()
    attack_system.setup(self, attack_damage, attack_range)
    add_child(attack_system)

# 设置技能
func setup_skills():
    # 子类可以重写此方法设置特定的技能
    pass

# 每帧更新
func _process(delta):
    # 更新状态计时器
    update_status_timers(delta)

    # 更新护盾
    update_shield(delta)

    # 更新攻击计时器
    update_attack_timer(delta)

    # 更新技能
    update_skills(delta)

# 物理更新
func _physics_process(delta):
    if is_stunned:
        return

    # 移动逻辑
    if target:
        # 计算方向
        var direction = (target.global_position - global_position).normalized()

        # 应用速度
        velocity = direction * move_speed * slow_factor
    else:
        velocity = Vector2.ZERO

    # 移动敌人
    move_and_slide()

    # 检查攻击范围
    check_attack_range()

# 更新状态计时器
func update_status_timers(delta):
    # 更新眩晕计时器
    if is_stunned:
        stun_timer -= delta
        if stun_timer <= 0:
            is_stunned = false

    # 更新减速计时器
    if is_slowed:
        slow_timer -= delta
        if slow_timer <= 0:
            is_slowed = false
            slow_factor = 1.0

    # 更新燃烧计时器
    if is_burning:
        burn_timer -= delta

        # 造成燃烧伤害
        take_damage(burn_damage * delta, "fire")

        if burn_timer <= 0:
            is_burning = false

# 更新护盾
func update_shield(delta):
    if shield < 0:
        shield = 0

    # 护盾再生
    if shield_regeneration > 0 and shield < max_health * 0.5:  # 护盾最多为最大生命值的50%
        shield += shield_regeneration * delta

# 更新攻击计时器
func update_attack_timer(delta):
    if !can_attack:
        attack_timer += delta
        if attack_timer >= 1.0 / attack_speed:
            can_attack = true
            attack_timer = 0

# 更新技能
func update_skills(delta):
    # 子类可以重写此方法更新特定的技能
    pass

# 检查攻击范围
func check_attack_range():
    if !target or !can_attack:
        return

    var distance = global_position.distance_to(target.global_position)
    if distance <= attack_range:
        perform_attack()

# 执行攻击
func perform_attack():
    if attack_system:
        attack_system.perform_attack()

    can_attack = false

# 受到伤害
func take_damage(amount, damage_type = "physical"):
    # 应用抗性
    var final_damage = amount
    match damage_type:
        "physical":
            final_damage *= (1 - physical_resistance)
        "magic":
            final_damage *= (1 - magic_resistance)
        "fire":
            final_damage *= (1 - fire_resistance)
        "lightning":
            final_damage *= (1 - lightning_resistance)

    # 应用护盾
    if shield > 0:
        if shield >= final_damage:
            shield -= final_damage
            final_damage = 0
        else:
            final_damage -= shield
            shield = 0

    # 应用伤害
    current_health -= final_damage

    # 更新生命条
    var health_bar = find_child("HealthBar")

    # 如果生命条不存在，创建一个
    if not health_bar:
        # print("Creating health bar in take_damage")
        health_bar = ProgressBar.new()
        health_bar.name = "HealthBar"
        health_bar.size = Vector2(40, 5)
        health_bar.position = Vector2(-20, -30)

        # 设置生命条样式
        var style_box = StyleBoxFlat.new()
        style_box.bg_color = Color(0.8, 0, 0, 1)  # 红色生命条
        style_box.corner_radius_top_left = 2
        style_box.corner_radius_top_right = 2
        style_box.corner_radius_bottom_left = 2
        style_box.corner_radius_bottom_right = 2
        health_bar.add_theme_stylebox_override("fill", style_box)

        # 设置背景样式
        var bg_style = StyleBoxFlat.new()
        bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # 灰色背景
        bg_style.corner_radius_top_left = 2
        bg_style.corner_radius_top_right = 2
        bg_style.corner_radius_bottom_left = 2
        bg_style.corner_radius_bottom_right = 2
        health_bar.add_theme_stylebox_override("background", bg_style)

        add_child(health_bar)

    # 确保生命条的最大值和当前值正确设置
    health_bar.max_value = max_health
    health_bar.value = current_health

    # 调试输出
    # print("Enemy health: ", current_health, "/", max_health, " = ", (current_health / max_health) * 100, "%")
    # print("Health bar: max_value = ", health_bar.max_value, ", value = ", health_bar.value, ", ratio = ", health_bar.value / health_bar.max_value)

    # 发出受伤信号
    damaged.emit(final_damage)

    # 显示伤害数字
    show_damage_number(final_damage)

    # 检查死亡
    if current_health <= 0:
        die()

# 显示伤害数字
func show_damage_number(amount):
    var damage_label = Label.new()
    damage_label.text = str(int(amount))
    damage_label.position = Vector2(0, -40)
    damage_label.modulate = Color(1, 0.3, 0.3)
    add_child(damage_label)

    # 动画效果
    var tween = create_tween()
    tween.tween_property(damage_label, "position:y", -60, 0.5)
    tween.parallel().tween_property(damage_label, "modulate:a", 0, 0.5)
    tween.tween_callback(func(): damage_label.queue_free())

# 死亡
func die():
    # 发出死亡信号
    died.emit(global_position, experience_value)

    # 播放死亡动画
    play_death_animation()

    # 使用 call_deferred 延迟销毁敌人，避免在物理查询刷新时销毁
    call_deferred("queue_free")

# 播放死亡动画
func play_death_animation():
    # 子类可以重写此方法播放特定的死亡动画
    var death_effect = CPUParticles2D.new()
    death_effect.emitting = true
    death_effect.one_shot = true
    death_effect.explosiveness = 0.8
    death_effect.amount = 20
    death_effect.lifetime = 0.5
    death_effect.direction = Vector2(0, -1)
    death_effect.spread = 180
    death_effect.gravity = Vector2(0, 0)
    death_effect.initial_velocity_min = 50
    death_effect.initial_velocity_max = 100
    # 不设置 scale_amount，因为它可能不兼容
    death_effect.color = Color(1.0, 0.3, 0.3, 1.0)  # 红色

    get_tree().current_scene.add_child(death_effect)
    death_effect.global_position = global_position

# 获取攻击伤害值
func get_attack_damage() -> float:
    return attack_damage

# 应用状态效果
func apply_status_effect(effect_type, duration, value = 0):
    match effect_type:
        "stun":
            is_stunned = true
            stun_timer = duration
        "slow":
            is_slowed = true
            slow_timer = duration
            slow_factor = value  # 减速因子 (0.0 - 1.0)
        "burn":
            is_burning = true
            burn_timer = duration
            burn_damage = value  # 每秒燃烧伤害

# 应用击退
func apply_knockback(direction, force):
    # 应用击退抗性
    force *= (1 - knockback_resistance)

    # 应用击退
    velocity = direction * force

    # 创建一个短暂的计时器，在击退后恢复正常移动
    var timer = get_tree().create_timer(0.2)
    timer.timeout.connect(func(): velocity = Vector2.ZERO)

# 获取敌人信息
func get_info():
    return {
        "id": enemy_id,
        "name": enemy_name,
        "type": enemy_type,
        "level": level,
        "health": current_health,
        "max_health": max_health,
        "shield": shield,
        "experience_value": experience_value
    }
