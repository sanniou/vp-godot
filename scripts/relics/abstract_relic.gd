extends Node
class_name AbstractRelic

# 基本属性
var id: String = ""
var relic_name: String = "抽象遗物"  # 改为 relic_name 避免与 Node.name 冲突
var description: String = "这是一个抽象遗物基类"
var icon: String = "❓"
var rarity: String = "common"  # common, uncommon, rare, legendary

# 事件类型枚举
enum EventType {
    GAME_START,      # 游戏开始时
    LEVEL_UP,        # 升级时
    EXPERIENCE_GAIN, # 获得经验时
    DAMAGE_TAKEN,    # 受到伤害时
    DAMAGE_DEALT,    # 造成伤害时
    ENEMY_KILLED,    # 击杀敌人时
    PLAYER_DEATH,    # 玩家死亡时
    ITEM_PICKUP,     # 拾取物品时
    TIMER_TICK,      # 定时触发
    UPGRADE_OPTIONS, # 升级选项生成时
    REROLL_COUNT,    # 获取重新随机次数时
    OPTION_REROLL,   # 重新随机选项时
    EXPERIENCE_ORB_COLLECTED # 收集经验球时
}

# 构造函数
func _init(relic_id: String, rel_name: String, relic_description: String, relic_icon: String, relic_rarity: String = "common"):
    id = relic_id
    relic_name = rel_name
    description = relic_description
    icon = relic_icon
    rarity = relic_rarity

# 虚函数：获取此遗物响应的事件类型列表
func get_event_types() -> Array:
    # 子类需要重写此方法，返回它关心的事件类型
    return []

# 虚函数：处理事件
# event_type: 事件类型
# event_data: 事件数据，包含与事件相关的所有信息
# 返回值: 修改后的事件数据（如果需要）
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    # 子类需要重写此方法，处理特定事件
    # print("AbstractRelic: 事件未处理 - ", EventType.keys()[event_type])
    return event_data

# 虚函数：获取遗物的状态信息（用于保存/加载）
func get_state() -> Dictionary:
    return {
        "id": id,
        "name": relic_name,
        "icon": icon,
        "rarity": rarity
    }

# 虚函数：从状态信息恢复遗物状态
func set_state(state: Dictionary) -> void:
    if state.has("id"):
        id = state.id
    if state.has("name"):
        relic_name = state.name
    if state.has("icon"):
        icon = state.icon
    if state.has("rarity"):
        rarity = state.rarity

# 辅助方法：获取遗物信息
func get_info() -> Dictionary:
    return {
        "id": id,
        "name": relic_name,
        "description": description,
        "icon": icon,
        "rarity": rarity
    }
