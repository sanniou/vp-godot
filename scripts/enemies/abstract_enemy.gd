extends CharacterBody2D
class_name AbstractEnemy

# 预加载生命条类
const HealthBarClass = preload("res://scripts/ui/health_bar.gd")

# 信号
signal died(position, experience)
signal damaged(amount)

# 敌人类型枚举
enum EnemyType {
    BASIC,      # 基本敌人（近战）
    RANGED,     # 远程敌人
    ELITE,      # 精英敌人
    BOSS        # Boss敌人
}

# 基本属性
var enemy_id: String = ""
var enemy_name: String = "抽象敌人"
var enemy_type: int = EnemyType.BASIC
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
var is_knocked_back: bool = false
var knockback_timer: float = 0.0

# 碰撞后的临时状态
var cannot_approach_player: bool = false  # 无法接近玩家
var approach_cooldown_timer: float = 0.0  # 接近冷却计时器
var last_collision_time: int = 0  # 上次碰撞时间

# 攻击系统
var attack_system = null

# 预加载敌人配置
const EnemyConfigClass = preload("res://scripts/enemies/enemy_config.gd")

# 预加载敌人状态机
const EnemyStateMachineClass = preload("res://scripts/enemies/enemy_state_machine.gd")

# 敌人状态机
var state_machine = null

# 探测范围
var detection_range = 500.0

# 眼晕持续时间
var stun_duration = 1.0

# 构造函数
func _init(id: String, name: String, type: int = EnemyType.BASIC):
    enemy_id = id
    enemy_name = name
    enemy_type = type

    # 从配置文件加载敌人属性
    var config = {}

    match type:
        EnemyType.BASIC:
            config = EnemyConfigClass.get_config("basic")
        EnemyType.RANGED:
            config = EnemyConfigClass.get_config("ranged")
        EnemyType.ELITE:
            config = EnemyConfigClass.get_config("elite")
        EnemyType.BOSS:
            config = EnemyConfigClass.get_config("boss")

    # 设置属性
    max_health = config.get("max_health", 100.0)
    move_speed = config.get("move_speed", 100.0)
    attack_damage = config.get("attack_damage", 10.0)
    attack_range = config.get("attack_range", 50.0)
    experience_value = config.get("experience_value", 10)
    physical_resistance = config.get("physical_resistance", 0.0)
    magic_resistance = config.get("magic_resistance", 0.0)
    shield = config.get("shield", 0.0)
    shield_regeneration = config.get("shield_regeneration", 0.0)
    knockback_resistance = config.get("knockback_resistance", 0.0)

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

    # 初始化状态机
    state_machine = EnemyStateMachineClass.new(self)

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
    # 从配置加载视觉效果参数
    var config = {}

    match enemy_type:
        EnemyType.BASIC:
            config = EnemyConfigClass.get_config("basic")
        EnemyType.RANGED:
            config = EnemyConfigClass.get_config("ranged")
        EnemyType.ELITE:
            config = EnemyConfigClass.get_config("elite")
        EnemyType.BOSS:
            config = EnemyConfigClass.get_config("boss")

    # 创建敌人外观
    var visual = ColorRect.new()
    visual.color = config.get("color", Color(1, 0, 0, 1))  # 默认红色
    var size = config.get("size", Vector2(40, 40))
    visual.size = size
    visual.position = Vector2(-size.x/2, -size.y/2)
    add_child(visual)

    # 设置血条
    setup_health_bar()

    # 设置护盾条（如果有护盾）
    setup_shield_bar()

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

    # 更新状态机
    if state_machine:
        # 检查与玩家的距离
        var player_distance = 9999.0
        var can_attack_player = false

        if target:
            player_distance = global_position.distance_to(target.global_position)
            can_attack_player = player_distance <= attack_range

        # 更新状态机条件
        state_machine.update_conditions(
            player_distance,
            can_attack_player,
            is_stunned,
            current_health <= 0
        )

        # 处理状态
        state_machine.process_state(delta)

# 物理更新
func _physics_process(delta):
    # 更新击退计时器
    if is_knocked_back:
        knockback_timer -= delta
        if knockback_timer <= 0:
            is_knocked_back = false
            # 打印击退结束信息
            print("Knockback ended for enemy: ", enemy_name)
            # 重置速度
            velocity = Vector2.ZERO

            # 设置无法接近玩家状态，防止击退后立即吸附
            cannot_approach_player = true
            approach_cooldown_timer = 1.0  # 1秒无法接近玩家

    # 更新接近冷却计时器
    if cannot_approach_player:
        approach_cooldown_timer -= delta
        if approach_cooldown_timer <= 0:
            cannot_approach_player = false
            print("Enemy can approach player again: ", enemy_name)

    # 如果正在被击退，保持当前速度并执行移动
    if is_knocked_back:
        # 打印当前速度
        print("Knocked back enemy velocity: ", velocity)
        # 仅执行移动，不改变速度
        move_and_slide()
        return

    # 如果正在使用状态机，则由状态机控制移动
    if state_machine:
        # 执行移动
        move_and_slide()
        return

    # 如果眼晕，不执行移动
    if is_stunned:
        return

    # 正常移动逻辑
    if target:
        # 计算方向
        var direction = (target.global_position - global_position).normalized()

        # 如果处于无法接近玩家状态，则移动到玩家侧面或后面
        if cannot_approach_player:
            # 计算一个与玩家相对的侧面位置
            var perpendicular = Vector2(direction.y, -direction.x)  # 垂直于原方向
            direction = perpendicular  # 改变移动方向为垂直方向

        # 应用速度
        velocity = direction * move_speed * slow_factor
    else:
        velocity = Vector2.ZERO

    # 移动敌人
    move_and_slide()

    # 检查攻击范围
    check_attack_range()

    # 主动检测与玩家的碰撞
    check_player_collision()

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

# 设置血条
func setup_health_bar():
    # 获取血条大小和位置
    var health_bar_width = 40
    var health_bar_height = 1
    var health_bar_position_y = -30

    # 根据敌人类型调整血条大小和位置
    match enemy_type:
        EnemyType.ELITE:
            health_bar_width = 50
            health_bar_position_y = -35
        EnemyType.BOSS:
            health_bar_width = 80
            health_bar_position_y = -50

    # 检查是否已经存在血条
    var existing_health_bar = find_child("HealthBar")
    if existing_health_bar:
        # 如果是新的HealthBar类，直接调用其方法
        if existing_health_bar is HealthBarClass:
            existing_health_bar.position = Vector2(-health_bar_width/2, health_bar_position_y)
            existing_health_bar.set_bar_size(health_bar_width, health_bar_height)
            existing_health_bar.set_max_value(max_health)
            existing_health_bar.set_value(current_health)
            return
        else:
            # 如果是旧的生命条，删除它
            existing_health_bar.queue_free()

    # 创建新的血条
    var health_bar = HealthBarClass.new()
    health_bar.name = "HealthBar"
    health_bar.position = Vector2(-health_bar_width/2, health_bar_position_y)
    health_bar.set_bar_size(health_bar_width, health_bar_height)
    health_bar.set_max_value(max_health)
    health_bar.set_value(current_health)

    # 调试输出
    print("Created health bar for ", enemy_name, ": max_health = ", max_health, ", current_health = ", current_health)
    print("Health bar settings: max_value = ", health_bar.max_value, ", current_value = ", health_bar.current_value)

    # 设置颜色和闪烁效果
    var fill_color = Color(0.8, 0, 0, 1)  # 默认红色
    var low_health_color = Color(1.0, 0.0, 0.0, 1.0)  # 默认低生命值颜色
    var flash_speed = 3.0  # 默认闪烁速度
    var damage_flash_duration = 0.3  # 默认受伤闪烁持续时间

    # 根据敌人类型调整颜色和闪烁效果
    match enemy_type:
        EnemyType.ELITE:
            fill_color = Color(0.8, 0.8, 0.2, 1.0)  # 黄色
            low_health_color = Color(1.0, 0.8, 0.0, 1.0)  # 橙色
            flash_speed = 4.0  # 精英敌人闪烁更快
            damage_flash_duration = 0.4  # 精英敌人受伤闪烁更长
        EnemyType.BOSS:
            fill_color = Color(0.8, 0.0, 0.0, 1.0)  # 深红色
            low_health_color = Color(1.0, 0.0, 0.0, 1.0)  # 亮红色
            flash_speed = 5.0  # Boss敌人闪烁更快
            damage_flash_duration = 0.5  # Boss敌人受伤闪烁更长

    # 设置颜色
    health_bar.set_colors(Color(0.2, 0.2, 0.2, 0.7), fill_color, low_health_color)

    # 设置闪烁效果
    health_bar.set_flash_speed(flash_speed)
    health_bar.set_damage_flash_duration(damage_flash_duration)

    # 设置低生命值阈值，精英和Boss敌人的阈值更低
    if enemy_type == EnemyType.ELITE:
        health_bar.set_low_health_threshold(0.25)  # 25%
    elif enemy_type == EnemyType.BOSS:
        health_bar.set_low_health_threshold(0.2)  # 20%
    else:
        health_bar.set_low_health_threshold(0.3)  # 30%

    # 添加到敌人
    add_child(health_bar)



# 设置护盾条
func setup_shield_bar():
    # 如果有护盾，添加护盾条
    if shield > 0:
        # 检查是否已经存在护盾条
        var existing_shield_bar = find_child("ShieldBar")
        if existing_shield_bar:
            return  # 已经存在，不需要再创建

        # 创建护盾条
        var shield_bar = Control.new()
        shield_bar.name = "ShieldBar"

        # 根据敌人类型调整护盾条大小和位置
        var shield_width = 40
        var shield_position_y = -35

        match enemy_type:
            EnemyType.ELITE:
                shield_width = 50
                shield_position_y = -40
            EnemyType.BOSS:
                shield_width = 80
                shield_position_y = -55

        shield_bar.position = Vector2(-shield_width/2, shield_position_y)
        shield_bar.custom_minimum_size = Vector2(shield_width, 1)

        # 创建护盾条背景
        var bg = ColorRect.new()
        bg.name = "Background"
        bg.size = Vector2(shield_width, 1)
        bg.color = Color(0.1, 0.1, 0.3, 0.7)  # 深蓝色背景
        shield_bar.add_child(bg)

        # 创建护盾条前景
        var fill = ColorRect.new()
        fill.name = "Fill"
        fill.size = Vector2(shield_width, 1)
        fill.color = Color(0.2, 0.6, 1.0, 1.0)  # 蓝色护盾条
        shield_bar.add_child(fill)

        # 添加到敌人
        add_child(shield_bar)

        # 更新护盾条宽度
        update_shield_bar()

# 更新护盾条
func update_shield_bar():
    var shield_bar = find_child("ShieldBar")
    if shield_bar and shield >= 0:
        var fill = shield_bar.find_child("Fill")
        if fill:
            var max_shield = max_health * 0.5  # 护盾最大值为最大生命值的50%
            var shield_percent = float(shield) / max_shield
            var shield_width = 40

            match enemy_type:
                EnemyType.ELITE:
                    shield_width = 50
                EnemyType.BOSS:
                    shield_width = 80

            fill.size.x = shield_width * shield_percent

# 更新护盾
func update_shield(delta):
    if shield < 0:
        shield = 0

    # 护盾再生
    if shield_regeneration > 0 and shield < max_health * 0.5:  # 护盾最多为最大生命值的50%
        shield += shield_regeneration * delta

    # 更新护盾条
    update_shield_bar()

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

    # 确保生命值不会小于0
    current_health = max(0, current_health)

    # 更新生命条
    var health_bar = find_child("HealthBar")
    if health_bar and health_bar is HealthBarClass:
        # 设置最大值，确保与当前生命值一致
        health_bar.set_max_value(max_health)
        # 显示受伤闪烁
        health_bar.set_value(current_health, true)
        # 强制更新血条
        health_bar._update_fill_width()
        # 强制重绘
        health_bar.queue_redraw()

        # 调试输出
        print("Enemy ", enemy_name, " health: ", current_health, "/", max_health, " = ", (current_health / max_health) * 100, "%")
        print("Health bar: max_value = ", health_bar.max_value, ", value = ", health_bar.current_value, ", ratio = ", health_bar.current_value / health_bar.max_value)

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
    # 使用效果管理器创建安全的粒子效果
    var EffectManager = load("res://scripts/utils/effect_manager.gd")
    var config = {
        "emitting": true,
        "one_shot": true,
        "explosiveness": 0.8,
        "amount": 20,
        "lifetime": 0.5,
        "direction": Vector2(0, -1),
        "spread": 180.0,
        "gravity": Vector2(0, 0),
        "velocity_min": 50.0,
        "velocity_max": 100.0,
        "scale": 3.0,
        "color": Color(1.0, 0.3, 0.3, 1.0)  # 红色
    }

    EffectManager.create_safe_particles(global_position, config)

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
    # 记录碰撞时间
    last_collision_time = Time.get_ticks_msec()

    # 应用击退抗性
    force *= (1 - knockback_resistance)

    # 进一步减小击退力度，使敌人被击退约一个身位
    force *= 0.1  # 进一步减小击退力度

    # 打印击退信息
    print("Applying knockback to enemy: ", enemy_name, ", force: ", force)

    # 设置击退状态
    is_knocked_back = true
    knockback_timer = 0.8  # 增加击退持续时间到 0.8 秒

    # 立即设置无法接近玩家状态
    cannot_approach_player = true
    approach_cooldown_timer = 1.5  # 1.5秒无法接近玩家

    # 应用击退速度 - 使用更大的值
    velocity = direction * force * 2

    # 直接修改敌人位置，实现立即击退效果
    # 使用 move_and_collide 而不是直接设置位置，以处理碰撞
    var collision = move_and_collide(direction * 5)  # 进一步减小初始位移

    # 添加少量强制移动的定时器，在几帧内微小推动敌人
    var timer1 = get_tree().create_timer(0.05)
    timer1.timeout.connect(func(): if is_instance_valid(self) and is_knocked_back: move_and_collide(direction * 3))

    var timer2 = get_tree().create_timer(0.1)
    timer2.timeout.connect(func(): if is_instance_valid(self) and is_knocked_back: move_and_collide(direction * 2))

    # 创建击退特效
    create_knockback_effect(global_position)

# 创建击退特效
func create_knockback_effect(position):
    # 创建粒子效果
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
    # 不设置 scale_amount，因为它可能不兼容
    effect.color = Color(0.8, 0.8, 1.0, 0.7)  # 浅蓝色

    # 添加到场景
    get_tree().current_scene.add_child(effect)
    effect.global_position = position

    # 自动清理
    var timer = Timer.new()
    timer.wait_time = 0.5
    timer.one_shot = true
    timer.autostart = true
    effect.add_child(timer)
    timer.timeout.connect(func(): effect.queue_free())

# 主动检测与玩家的碰撞
func check_player_collision():
    # 如果没有目标或正在被击退或无法接近玩家，不检测碰撞
    if target == null or is_knocked_back or cannot_approach_player:
        return

    # 获取玩家
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        return

    # 检查碰撞冷却时间
    var current_time = Time.get_ticks_msec()
    if current_time - last_collision_time < 1000:  # 1秒内不重复触发碰撞
        return

    # 计算与玩家的距离
    var distance = global_position.distance_to(player.global_position)

    # 使用更小的碰撞检测范围，提高精度
    var collision_radius = 25  # 减小范围以提高精度

    if distance < collision_radius:
        # 更新碰撞时间
        last_collision_time = current_time

        # 打印碰撞信息
        print("Enemy ", enemy_name, " actively detected collision with player, distance: ", distance)

        # 触发玩家的碰撞处理
        if player.has_method("_process_collision"):
            player._process_collision(self)

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
