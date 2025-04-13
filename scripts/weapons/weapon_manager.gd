extends Node
class_name WeaponManager

# 信号
signal weapon_added(weapon_id)
signal weapon_removed(weapon_id)
signal weapon_upgraded(weapon_id, upgrade_type, new_level)

# 已装备的武器
var equipped_weapons = {}  # 字典: weapon_id -> weapon实例

# 所有可用武器的注册表
var available_weapons = {}  # 字典: weapon_id -> weapon场景

# 武器容器节点
var weapon_container: Node

# 初始化
func _init():
    pass

# 设置武器容器
func set_weapon_container(container: Node):
    weapon_container = container

    # 注册所有可用的武器
    register_available_weapons()

# 注册所有可用的武器
func register_available_weapons():
    # 加载所有武器场景
    var magic_wand_scene = load("res://scenes/weapons/magic_wand.tscn")
    var flamethrower_scene = load("res://scenes/weapons/flamethrower.tscn")
    var gun_scene = load("res://scenes/weapons/gun.tscn")
    var knife_scene = load("res://scenes/weapons/knife.tscn")
    var shield_scene = load("res://scenes/weapons/shield.tscn")
    var lightning_scene = load("res://scenes/weapons/lightning.tscn")

    # 加载新武器场景
    var orbital_satellite_scene = load("res://scenes/weapons/orbital_satellite.tscn")
    var black_hole_bomb_scene = load("res://scenes/weapons/black_hole_bomb.tscn")
    var toxic_spray_scene = load("res://scenes/weapons/toxic_spray.tscn")
    var frost_staff_scene = load("res://scenes/weapons/frost_staff.tscn")
    var boomerang_scene = load("res://scenes/weapons/boomerang.tscn")

    # 注册武器
    register_weapon("magic_wand", magic_wand_scene)
    register_weapon("flamethrower", flamethrower_scene)
    register_weapon("gun", gun_scene)
    register_weapon("knife", knife_scene)
    register_weapon("shield", shield_scene)
    register_weapon("lightning", lightning_scene)

    # 注册新武器
    register_weapon("orbital_satellite", orbital_satellite_scene)
    register_weapon("black_hole_bomb", black_hole_bomb_scene)
    register_weapon("toxic_spray", toxic_spray_scene)
    register_weapon("frost_staff", frost_staff_scene)
    register_weapon("boomerang", boomerang_scene)

# 注册一个武器
func register_weapon(weapon_id: String, weapon_scene):
    available_weapons[weapon_id] = weapon_scene

# 添加武器
func add_weapon(weapon_id: String):
    # 检查武器是否已装备
    if equipped_weapons.has(weapon_id):
        print("武器已装备: ", weapon_id)
        return equipped_weapons[weapon_id]

    # 检查武器是否可用
    if not available_weapons.has(weapon_id):
        print("武器不可用: ", weapon_id)
        return null

    # 创建武器实例
    var weapon_instance = available_weapons[weapon_id].instantiate()

    # 添加到武器容器
    weapon_container.add_child(weapon_instance)

    # 添加到已装备武器列表
    equipped_weapons[weapon_id] = weapon_instance

    # 连接武器信号
    connect_weapon_signals(weapon_instance)

    # 发出信号
    weapon_added.emit(weapon_id)

    # 获取武器名称
    var weapon_name = weapon_id
    if "weapon_name" in weapon_instance:
        weapon_name = weapon_instance.weapon_name

    # 使用UI管理器显示武器获取消息
    var ui_manager = get_node_or_null("/root/UIManager")
    if ui_manager:
        # 获取语言管理器
        var language_manager = get_node_or_null("/root/LanguageManager")
        if not language_manager:
            # 如果找不到语言管理器，尝试从自动加载脚本获取
            var autoload = get_node_or_null("/root/LanguageAutoload")
            if autoload and autoload.language_manager:
                language_manager = autoload.language_manager

        # 获取武器翻译名称
        var translated_name = weapon_name
        if language_manager:
            var trans_key = "weapon_" + weapon_id + "_name"
            var trans_result = language_manager.get_translation(trans_key, "")
            if not trans_result.is_empty():
                translated_name = trans_result

        # 显示武器获取通知
        var title = language_manager.get_translation("weapon_acquired", "Weapon Acquired")
        var message = language_manager.get_translation("weapon_acquired_message", "You acquired %s!")
        message = message % translated_name

        ui_manager.show_notification(title, message, "success", 3.0)

    return weapon_instance

# 移除武器
func remove_weapon(weapon_id: String) -> bool:
    if not equipped_weapons.has(weapon_id):
        return false

    var weapon = equipped_weapons[weapon_id]
    equipped_weapons.erase(weapon_id)

    if weapon:
        # 断开武器信号
        disconnect_weapon_signals(weapon)

        # 从场景中移除
        weapon.queue_free()

    # 发出信号
    weapon_removed.emit(weapon_id)

    return true

# 连接武器信号
func connect_weapon_signals(weapon):
    # 安全地连接信号
    if weapon.has_signal("weapon_upgraded"):
        if not weapon.weapon_upgraded.is_connected(_on_weapon_upgraded):
            weapon.weapon_upgraded.connect(_on_weapon_upgraded)

    if weapon.has_signal("enemy_hit"):
        if not weapon.enemy_hit.is_connected(_on_enemy_hit):
            weapon.enemy_hit.connect(_on_enemy_hit)

    if weapon.has_signal("enemy_killed"):
        if not weapon.enemy_killed.is_connected(_on_enemy_killed):
            weapon.enemy_killed.connect(_on_enemy_killed)

# 断开武器信号
func disconnect_weapon_signals(weapon):
    # 安全地断开信号
    if weapon.has_signal("weapon_upgraded"):
        if weapon.weapon_upgraded.is_connected(_on_weapon_upgraded):
            weapon.weapon_upgraded.disconnect(_on_weapon_upgraded)

    if weapon.has_signal("enemy_hit"):
        if weapon.enemy_hit.is_connected(_on_enemy_hit):
            weapon.enemy_hit.disconnect(_on_enemy_hit)

    if weapon.has_signal("enemy_killed"):
        if weapon.enemy_killed.is_connected(_on_enemy_killed):
            weapon.enemy_killed.disconnect(_on_enemy_killed)

# 武器升级信号处理
func _on_weapon_upgraded(weapon_id: String, upgrade_type: int, new_level: int):
    weapon_upgraded.emit(weapon_id, upgrade_type, new_level)



# 击中敌人信号处理
func _on_enemy_hit(weapon_id: String, enemy, damage: float):
    # 可以在这里添加全局的击中处理逻辑
    pass

# 击杀敌人信号处理
func _on_enemy_killed(weapon_id: String, enemy, position: Vector2):
    # 可以在这里添加全局的击杀处理逻辑
    pass

# 升级武器
func upgrade_weapon(weapon_id: String, upgrade_type) -> bool:
    if not equipped_weapons.has(weapon_id):
        print("Weapon not found: ", weapon_id)
        return false

    var weapon = equipped_weapons[weapon_id]

    # 调试输出
    print("Upgrading weapon: ", weapon_id, " with upgrade type: ", upgrade_type)
    print("Weapon methods: ", weapon.get_method_list())

    # 检查武器是否有 apply_upgrade 方法
    if weapon.has_method("apply_upgrade"):
        weapon.apply_upgrade(upgrade_type)
    # 如果没有 apply_upgrade 方法，尝试使用 upgrade 方法
    elif weapon.has_method("upgrade"):
        weapon.upgrade(upgrade_type)
    else:
        print("Weapon does not have upgrade methods: ", weapon_id)
        return false

    # 使用UI管理器显示武器升级消息
    var ui_manager = get_node_or_null("/root/UIManager")
    if ui_manager:
        # 获取语言管理器
        var language_manager = get_node_or_null("/root/LanguageManager")
        if not language_manager:
            # 如果找不到语言管理器，尝试从自动加载脚本获取
            var autoload = get_node_or_null("/root/LanguageAutoload")
            if autoload and autoload.language_manager:
                language_manager = autoload.language_manager

        # 获取武器翻译名称
        var weapon_name = weapon_id
        if "weapon_name" in weapon:
            weapon_name = weapon.weapon_name

        var translated_name = weapon_name
        if language_manager:
            var trans_key = "weapon_" + weapon_id + "_name"
            var trans_result = language_manager.get_translation(trans_key, "")
            if not trans_result.is_empty():
                translated_name = trans_result

        # 获取升级类型名称
        var upgrade_name = ""
        match upgrade_type:
            0: # 伤害
                upgrade_name = language_manager.get_translation("weapon_upgrade_damage", "Damage")
            1: # 攻击速度
                upgrade_name = language_manager.get_translation("weapon_upgrade_attack_speed", "Attack Speed")
            2: # 范围
                upgrade_name = language_manager.get_translation("weapon_upgrade_range", "Range")
            3: # 子弹数量
                upgrade_name = language_manager.get_translation("weapon_upgrade_projectile_count", "Projectile Count")
            _:
                upgrade_name = language_manager.get_translation("weapon_upgrade_generic", "Upgrade")

        # 显示武器升级通知
        var title = language_manager.get_translation("weapon_upgraded", "Weapon Upgraded")
        var message = language_manager.get_translation("weapon_upgraded_message", "%s %s improved!")
        message = message % [translated_name, upgrade_name]

        ui_manager.show_toast(message, 3.0)

    return true

# 检查是否装备了特定武器
func has_weapon(weapon_id: String) -> bool:
    return equipped_weapons.has(weapon_id)

# 获取武器实例
func get_weapon(weapon_id: String):
    if equipped_weapons.has(weapon_id):
        return equipped_weapons[weapon_id]
    return null

# 获取武器信息
func get_weapon_info(weapon_id: String) -> Dictionary:
    if equipped_weapons.has(weapon_id):
        return equipped_weapons[weapon_id].get_info()

    return {}

# 获取所有已装备武器的信息
func get_equipped_weapons_info() -> Array:
    var result = []
    for weapon_id in equipped_weapons:
        result.append(equipped_weapons[weapon_id].get_info())
    return result

# 获取所有可用武器的ID
func get_available_weapon_ids() -> Array:
    return available_weapons.keys()

# 获取武器升级选项
func get_weapon_upgrade_options(weapon_id: String) -> Array:
    if not equipped_weapons.has(weapon_id):
        return []

    var weapon = equipped_weapons[weapon_id]
    return weapon.get_upgrade_options()

# 处理全局事件
func trigger_global_event(event_type: int, event_data: Dictionary = {}) -> Dictionary:
    var modified_data = event_data.duplicate()

    # 遍历所有已装备的武器，让它们处理事件
    for weapon_id in equipped_weapons:
        var weapon = equipped_weapons[weapon_id]
        modified_data = weapon.trigger_event(event_type, modified_data)

    return modified_data

# 在节点被移除时清理资源
func _exit_tree():
    # 清理所有武器
    for weapon_id in equipped_weapons.keys():
        if equipped_weapons[weapon_id] != null and is_instance_valid(equipped_weapons[weapon_id]):
            equipped_weapons[weapon_id].queue_free()

    # 清空武器字典
    equipped_weapons.clear()
    available_weapons.clear()
