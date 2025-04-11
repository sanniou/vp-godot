extends Node2D
class_name AbstractWeapon

# 基本属性
var weapon_id: String = ""
var weapon_name: String = "抽象武器"
var description: String = "这是一个抽象武器基类"
var icon: String = "🔫"
var weapon_type: String = "ranged"  # ranged, melee, magic, special

# 武器等级
var level: int = 1
var max_level: int = 5

# 事件类型枚举
enum EventType {
    ATTACK_START,    # 攻击开始时
    ATTACK_END,      # 攻击结束时
    HIT_ENEMY,       # 击中敌人时
    KILL_ENEMY,      # 击杀敌人时
    LEVEL_UP,        # 武器升级时
    PLAYER_MOVE,     # 玩家移动时
    PLAYER_IDLE,     # 玩家静止时
    TIMER_TICK       # 定时触发
}

# 升级选项类型
enum UpgradeType {
    DAMAGE,          # 伤害
    ATTACK_SPEED,    # 攻击速度
    AREA,            # 攻击范围
    PROJECTILE_COUNT,# 弹射数量
    PROJECTILE_SPEED,# 弹射速度
    EFFECT_DURATION, # 效果持续时间
    COOLDOWN,        # 冷却时间
    SPECIAL          # 特殊效果
}

# 信号
signal attack_performed(weapon_id, attack_data)
signal enemy_hit(weapon_id, enemy, damage)
signal enemy_killed(weapon_id, enemy, position)
signal weapon_upgraded(weapon_id, upgrade_type, new_level)

# 构造函数
func _init(id: String, name: String, desc: String, weapon_icon: String, type: String = "ranged"):
    weapon_id = id
    weapon_name = name
    description = desc
    icon = weapon_icon
    weapon_type = type

# 虚函数：初始化
func _ready():
    # 子类可以重写此方法进行初始化
    pass

# 虚函数：处理每帧更新
func _process(delta):
    # 子类可以重写此方法处理每帧逻辑
    pass

# 虚函数：获取此武器可用的升级选项
func get_upgrade_options() -> Array:
    # 子类需要重写此方法，返回可用的升级选项
    # 每个选项是一个字典，包含升级类型、名称、描述等
    return []

# 虚函数：应用升级
func apply_upgrade(upgrade_type: int) -> void:
    # 子类需要重写此方法，应用特定类型的升级
    level += 1
    weapon_upgraded.emit(weapon_id, upgrade_type, level)

# 虚函数：执行攻击
func perform_attack() -> void:
    # 子类需要重写此方法，实现具体的攻击逻辑
    var attack_data = {
        "weapon_id": weapon_id,
        "weapon_type": weapon_type,
        "level": level
    }
    
    # 触发攻击开始事件
    trigger_event(EventType.ATTACK_START, attack_data)
    
    # 发出攻击信号
    attack_performed.emit(weapon_id, attack_data)
    
    # 触发攻击结束事件
    trigger_event(EventType.ATTACK_END, attack_data)

# 虚函数：处理击中敌人
func handle_enemy_hit(enemy, damage: float) -> void:
    # 触发击中敌人事件
    var hit_data = {
        "enemy": enemy,
        "damage": damage,
        "weapon_id": weapon_id,
        "critical": false
    }
    
    hit_data = trigger_event(EventType.HIT_ENEMY, hit_data)
    
    # 应用最终伤害
    if enemy.has_method("take_damage"):
        enemy.take_damage(hit_data.damage)
    
    # 发出击中敌人信号
    enemy_hit.emit(weapon_id, enemy, hit_data.damage)

# 虚函数：处理击杀敌人
func handle_enemy_killed(enemy, position: Vector2) -> void:
    # 触发击杀敌人事件
    var kill_data = {
        "enemy": enemy,
        "position": position,
        "weapon_id": weapon_id
    }
    
    kill_data = trigger_event(EventType.KILL_ENEMY, kill_data)
    
    # 发出击杀敌人信号
    enemy_killed.emit(weapon_id, enemy, position)

# 触发事件
func trigger_event(event_type: int, event_data: Dictionary) -> Dictionary:
    # 这里可以添加武器特有的事件处理逻辑
    # 例如，某些武器可能在击中敌人时有特殊效果
    
    # 获取主场景中的遗物管理器，让遗物也能响应武器事件
    var main = get_tree().current_scene
    if main and main.has_node("RelicManager"):
        var relic_manager = main.get_node("RelicManager")
        
        # 添加武器信息到事件数据
        event_data["weapon"] = self
        
        # 让遗物管理器处理事件
        event_data = relic_manager.trigger_event(event_type, event_data)
    
    return event_data

# 获取武器信息
func get_info() -> Dictionary:
    return {
        "id": weapon_id,
        "name": weapon_name,
        "description": description,
        "icon": icon,
        "type": weapon_type,
        "level": level,
        "max_level": max_level
    }

# 获取武器的状态信息（用于保存/加载）
func get_state() -> Dictionary:
    return {
        "id": weapon_id,
        "level": level
    }

# 从状态信息恢复武器状态
func set_state(state: Dictionary) -> void:
    if state.has("level"):
        level = state.level
