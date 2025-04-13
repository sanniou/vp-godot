extends "res://scripts/weapons/abstract_weapon.gd"

# 武器特有属性
var damage: float = 30.0
var strike_rate: float = 0.8  # 每秒闪电次数
var chain_count: int = 2  # 闪电链数量
var chain_range: float = 150.0  # 闪电链范围

# 内部变量
var can_strike: bool = true
var strike_timer: float = 0.0

func _init():
    super._init(
        "lightning",
        "闪电法杖",
        "召唤闪电攻击敌人，可以链接多个目标",
        "⚡",
        "magic"
    )

func _ready():
    # 初始化
    pass

func _process(delta):
    # 处理攻击冷却
    if !can_strike:
        strike_timer += delta
        if strike_timer >= 1.0 / strike_rate:
            can_strike = true
            strike_timer = 0

    # 自动攻击
    if can_strike:
        perform_attack()

# 执行攻击
func perform_attack():
    var enemies = get_tree().get_nodes_in_group("enemies")
    if enemies.size() == 0:
        return

    # 调用父类方法触发攻击开始事件
    var attack_data = {
        "weapon_id": weapon_id,
        "weapon_type": weapon_type,
        "level": level,
        "damage": damage,
        "chain_count": chain_count,
        "chain_range": chain_range
    }

    # 触发攻击开始事件
    attack_data = trigger_event(EventType.ATTACK_START, attack_data)

    # 更新属性（可能被遗物修改）
    damage = attack_data.damage
    chain_count = attack_data.chain_count
    chain_range = attack_data.chain_range

    # 设置冷却
    can_strike = false

    # 选择一个随机敌人作为主要目标
    var primary_target = enemies[randi() % enemies.size()]

    # 造成伤害并创建闪电效果
    handle_enemy_hit(primary_target, damage)
    create_lightning_effect(global_position, primary_target.global_position)

    # 处理闪电链
    var hit_enemies = [primary_target]
    var current_target = primary_target

    for i in range(chain_count):
        var next_target = find_next_chain_target(current_target, hit_enemies, chain_range)
        if next_target:
            # 造成伤害并创建闪电效果
            handle_enemy_hit(next_target, damage * 0.7)  # 链式伤害降低
            create_lightning_effect(current_target.global_position, next_target.global_position)

            hit_enemies.append(next_target)
            current_target = next_target
        else:
            break  # 没有更多可链接的目标

    # 发出攻击信号
    attack_performed.emit(weapon_id, attack_data)

    # 触发攻击结束事件
    trigger_event(EventType.ATTACK_END, attack_data)

# 寻找下一个闪电链目标
func find_next_chain_target(current_target, hit_enemies, max_range):
    var enemies = get_tree().get_nodes_in_group("enemies")
    var valid_targets = []

    for enemy in enemies:
        # 检查是否已经被击中
        if enemy in hit_enemies:
            continue

        # 检查是否在链接范围内
        var distance = current_target.global_position.distance_to(enemy.global_position)
        if distance <= max_range:
            valid_targets.append({"enemy": enemy, "distance": distance})

    # 按距离排序
    valid_targets.sort_custom(func(a, b): return a.distance < b.distance)

    # 返回最近的有效目标
    if valid_targets.size() > 0:
        return valid_targets[0].enemy

    return null

# 创建闪电效果
func create_lightning_effect(start_pos, end_pos):
    var lightning = Line2D.new()
    lightning.width = 3
    lightning.default_color = Color(0.5, 0.8, 1.0, 0.8)  # 淡蓝色

    # 创建锯齿状闪电路径
    var points = []
    points.append(start_pos)

    var distance = start_pos.distance_to(end_pos)
    var direction = (end_pos - start_pos).normalized()
    var perpendicular = Vector2(-direction.y, direction.x)

    var segments = 5
    for i in range(1, segments):
        var t = float(i) / segments
        var pos = start_pos.lerp(end_pos, t)

        # 添加随机偏移
        var offset = perpendicular * (randf() * 20 - 10)
        pos += offset

        points.append(pos)

    points.append(end_pos)
    lightning.points = points

    get_tree().current_scene.add_child(lightning)

    # 添加闪电消失动画
    var tween = lightning.create_tween()
    tween.tween_property(lightning, "modulate:a", 0, 0.2)
    tween.tween_callback(func(): lightning.queue_free())

# 获取升级选项
func get_upgrade_options() -> Array:
    # 使用通用翻译辅助工具
    var Tr = load("res://scripts/language/tr.gd")
    var options = []

    # 伤害升级
    if level < max_level:
        options.append({
            "type": UpgradeType.DAMAGE,
            "name": Tr.weapon_upgrade("damage", "闪电伤害 +10"),
            "description": Tr.weapon_upgrade_desc("damage", "增加闪电伤害"),
            "icon": "💥"
        })

    # 攻击速度升级
    if level < max_level:
        options.append({
            "type": UpgradeType.ATTACK_SPEED,
            "name": Tr.weapon_upgrade("attack_speed", "闪电频率 +20%"),
            "description": Tr.weapon_upgrade_desc("attack_speed", "增加闪电攻击频率"),
            "icon": "⚡"
        })

    # 链数升级
    if level < max_level:
        options.append({
            "type": UpgradeType.PROJECTILE_COUNT,
            "name": Tr.weapon_upgrade("projectile_count", "闪电链 +1"),
            "description": Tr.weapon_upgrade_desc("projectile_count", "增加闪电链接数量"),
            "icon": "🔗"
        })

    # 链接范围升级
    if level < max_level:
        options.append({
            "type": UpgradeType.AREA,
            "name": Tr.weapon_upgrade("range", "链接范围 +30"),
            "description": Tr.weapon_upgrade_desc("range", "增加闪电链接范围"),
            "icon": "📏"
        })

    return options

# 应用升级
func apply_upgrade(upgrade_type: int) -> void:
    match upgrade_type:
        UpgradeType.DAMAGE:
            damage += 10
        UpgradeType.ATTACK_SPEED:
            strike_rate *= 1.2
        UpgradeType.PROJECTILE_COUNT:
            chain_count += 1
        UpgradeType.AREA:
            chain_range += 30

    # 调用父类方法更新等级并发出信号
    super.apply_upgrade(upgrade_type)

# 获取武器状态
func get_state() -> Dictionary:
    var state = super.get_state()
    state["damage"] = damage
    state["strike_rate"] = strike_rate
    state["chain_count"] = chain_count
    state["chain_range"] = chain_range
    return state

# 设置武器状态
func set_state(state: Dictionary) -> void:
    super.set_state(state)
    if state.has("damage"):
        damage = state.damage
    if state.has("strike_rate"):
        strike_rate = state.strike_rate
    if state.has("chain_count"):
        chain_count = state.chain_count
    if state.has("chain_range"):
        chain_range = state.chain_range
