extends "res://scripts/weapons/abstract_weapon.gd"
class_name OrbitalSatellite

# 卫星属性
var satellite_count = 1  # 初始卫星数量
var orbit_radius = 100  # 轨道半径
var orbit_speed = 2.0  # 轨道旋转速度（弧度/秒）
var damage = 20  # 伤害值
var damage_cooldown = 0.5  # 对同一敌人的伤害冷却

# 内部变量
var satellites = []  # 卫星节点数组
var current_angle = 0.0  # 当前角度
var damaged_enemies = {}  # 已伤害敌人的冷却计时器

func _init():
    super._init(
        "orbital_satellite",
        "轨道卫星",
        "围绕玩家旋转的卫星，自动攻击接触到的敌人",
        "🛰️",
        "special"
    )

func _ready():
    # 初始化卫星
    create_satellites()

func _process(delta):
    # 更新卫星位置
    update_satellites(delta)

    # 更新伤害冷却
    update_damage_cooldowns(delta)

    # 检测碰撞
    check_collisions()

# 创建卫星
func create_satellites():
    # 清除现有卫星
    for satellite in satellites:
        if is_instance_valid(satellite):
            satellite.queue_free()
    satellites.clear()

    # 创建新卫星
    for i in range(satellite_count):
        var satellite = create_satellite_node()
        satellites.append(satellite)
        add_child(satellite)

# 创建单个卫星节点
func create_satellite_node():
    var satellite = Node2D.new()

    # 创建卫星视觉效果
    var visual = Polygon2D.new()
    var points = []

    # 创建六边形
    var sides = 6
    var radius = 15
    for i in range(sides):
        var angle = 2 * PI * i / sides
        points.append(Vector2(cos(angle), sin(angle)) * radius)

    visual.polygon = points
    visual.color = Color(0.2, 0.6, 1.0, 0.8)  # 蓝色
    satellite.add_child(visual)

    # 添加发光效果
    var glow = visual.duplicate()
    glow.color = Color(0.4, 0.8, 1.0, 0.4)
    glow.scale = Vector2(1.5, 1.5)
    glow.z_index = -1
    satellite.add_child(glow)

    # 添加碰撞区域
    var area = Area2D.new()
    var collision = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = radius
    collision.shape = shape
    area.add_child(collision)

    # 设置碰撞层
    area.collision_layer = 0
    area.collision_mask = 4  # 敌人层

    satellite.add_child(area)

    return satellite

# 更新卫星位置
func update_satellites(delta):
    # 更新角度
    current_angle += orbit_speed * delta

    # 计算卫星位置
    for i in range(satellites.size()):
        var satellite = satellites[i]
        var angle_offset = 2 * PI * i / satellites.size()
        var angle = current_angle + angle_offset

        var pos = Vector2(cos(angle), sin(angle)) * orbit_radius
        satellite.position = pos

# 更新伤害冷却
func update_damage_cooldowns(delta):
    var to_remove = []

    for enemy_id in damaged_enemies:
        damaged_enemies[enemy_id] -= delta
        if damaged_enemies[enemy_id] <= 0:
            to_remove.append(enemy_id)

    for enemy_id in to_remove:
        damaged_enemies.erase(enemy_id)

# 检测碰撞
func check_collisions():
    for satellite in satellites:
        # 获取所有子节点
        for child in satellite.get_children():
            if child is Area2D:
                var overlapping_bodies = child.get_overlapping_bodies()
                for body in overlapping_bodies:
                    if body.is_in_group("enemies"):
                        deal_damage_to_enemy(body)

# 对敌人造成伤害
func deal_damage_to_enemy(enemy):
    # 检查冷却
    var enemy_id = enemy.get_instance_id()
    if enemy_id in damaged_enemies:
        return

    # 造成伤害
    var damage_data = {
        "enemy": enemy,
        "damage": damage,
        "weapon": self,
        "is_critical": false
    }

    # 触发伤害事件
    damage_data = trigger_event(EventType.HIT_ENEMY, damage_data)

    # 应用伤害
    enemy.take_damage(damage_data["damage"])

    # 设置冷却
    damaged_enemies[enemy_id] = damage_cooldown

    # 发出信号
    enemy_hit.emit(self.weapon_id, enemy, damage_data["damage"])

    # 检查是否击杀
    if enemy.current_health <= 0:
        enemy_killed.emit(self.weapon_id, enemy, enemy.global_position)

# 获取升级选项
func get_upgrade_options() -> Array:
    # 使用通用翻译辅助工具
    var Tr = load("res://scripts/language/tr.gd")

    return [
        {
            "type": UpgradeType.DAMAGE,
            "name": Tr.weapon_upgrade("damage", "伤害 +10"),
            "description": Tr.weapon_upgrade_desc("damage", "增加卫星伤害"),
            "icon": "💥"
        },
        {
            "type": UpgradeType.PROJECTILE_COUNT,
            "name": Tr.weapon_upgrade("projectile_count", "卫星 +1"),
            "description": Tr.weapon_upgrade_desc("projectile_count", "增加卫星数量"),
            "icon": "🛰️"
        },
        {
            "type": UpgradeType.AREA,
            "name": Tr.weapon_upgrade("range", "轨道半径 +20"),
            "description": Tr.weapon_upgrade_desc("range", "增加卫星轨道半径"),
            "icon": "⭕"
        },
        {
            "type": UpgradeType.ATTACK_SPEED,
            "name": Tr.weapon_upgrade("attack_speed", "旋转速度 +20%"),
            "description": Tr.weapon_upgrade_desc("attack_speed", "增加卫星旋转速度"),
            "icon": "🔄"
        }
    ]

# 应用升级
func apply_upgrade(upgrade_type: int) -> void:
    match upgrade_type:
        UpgradeType.DAMAGE:
            damage += 10
        UpgradeType.PROJECTILE_COUNT:
            satellite_count += 1
            create_satellites()
        UpgradeType.AREA:
            orbit_radius += 20
        UpgradeType.ATTACK_SPEED:
            orbit_speed *= 1.2

    # 调用父类方法
    super.apply_upgrade(upgrade_type)
