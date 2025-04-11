extends Node
class_name RelicManager

# 引入抽象遗物类
const AbstractRelic = preload("res://scripts/relics/abstract_relic.gd")

# 信号
signal relic_equipped(relic_id)
signal relic_unequipped(relic_id)
signal relic_effect_triggered(relic_id, event_type)

# 已装备的遗物
var equipped_relics = {}  # 字典: relic_id -> relic实例

# 所有可用遗物的注册表
var available_relics = {}  # 字典: relic_id -> relic类

# 初始化
func _ready():
    # 注册所有可用的遗物
    register_available_relics()

# 注册所有可用的遗物
func register_available_relics():
    # 加载已实现的遗物类
    var phoenix_feather = load("res://scripts/relics/phoenix_feather_relic.gd")
    var wisdom_crystal = load("res://scripts/relics/wisdom_crystal_relic.gd")
    var magnetic_amulet = load("res://scripts/relics/magnetic_amulet_relic.gd")
    var heart_amulet = load("res://scripts/relics/heart_amulet_relic.gd")
    var lucky_clover = load("res://scripts/relics/lucky_clover_relic.gd")
    var shadow_cloak = load("res://scripts/relics/shadow_cloak_relic.gd")
    var upgrade_enhancer = load("res://scripts/relics/upgrade_enhancer_relic.gd")

    # 加载新遗物类
    var time_warper = load("res://scripts/relics/time_warper_relic.gd")
    var elemental_resonance = load("res://scripts/relics/elemental_resonance_relic.gd")
    var experience_catalyst = load("res://scripts/relics/experience_catalyst_relic.gd")
    var critical_amulet = load("res://scripts/relics/critical_amulet_relic.gd")
    var life_steal = load("res://scripts/relics/life_steal_relic.gd")

    # 注册遗物
    register_relic("phoenix_feather", phoenix_feather)
    register_relic("wisdom_crystal", wisdom_crystal)
    register_relic("magnetic_amulet", magnetic_amulet)
    register_relic("heart_amulet", heart_amulet)
    register_relic("lucky_clover", lucky_clover)
    register_relic("shadow_cloak", shadow_cloak)
    register_relic("upgrade_enhancer", upgrade_enhancer)

    # 注册新遗物
    register_relic("time_warper", time_warper)
    register_relic("elemental_resonance", elemental_resonance)
    register_relic("experience_catalyst", experience_catalyst)
    register_relic("critical_amulet", critical_amulet)
    register_relic("life_steal", life_steal)

# 注册一个遗物类
func register_relic(relic_id: String, relic_class):
    available_relics[relic_id] = relic_class

# 装备遗物
func equip_relic(relic_id: String) -> bool:
    # 检查遗物是否已装备
    if equipped_relics.has(relic_id):
        # print("遗物已装备: ", relic_id)
        return false

    # 检查遗物是否可用
    if not available_relics.has(relic_id):
        # print("遗物不可用: ", relic_id)
        return false

    # 创建遗物实例
    var relic_instance = available_relics[relic_id].new()

    # 添加到已装备遗物列表
    equipped_relics[relic_id] = relic_instance
    add_child(relic_instance)

    # 发出信号
    relic_equipped.emit(relic_id)
    # print("已装备遗物: ", relic_id, " - ", relic_instance.relic_name)

    return true

# 卸下遗物
func unequip_relic(relic_id: String) -> bool:
    if not equipped_relics.has(relic_id):
        return false

    var relic = equipped_relics[relic_id]
    equipped_relics.erase(relic_id)

    if relic:
        relic.queue_free()

    # 发出信号
    relic_unequipped.emit(relic_id)

    return true

# 检查是否装备了特定遗物
func has_relic(relic_id: String) -> bool:
    return equipped_relics.has(relic_id)

# 获取遗物实例
func get_relic(relic_id: String):
    if equipped_relics.has(relic_id):
        return equipped_relics[relic_id]
    return null

# 获取遗物信息
func get_relic_info(relic_id: String) -> Dictionary:
    if equipped_relics.has(relic_id):
        return equipped_relics[relic_id].get_info()

    # 如果遗物未装备但在可用列表中，创建临时实例获取信息
    if available_relics.has(relic_id):
        var temp_relic = available_relics[relic_id].new()
        var info = temp_relic.get_info()
        temp_relic.free()
        return info

    return {}

# 获取所有已装备遗物的信息
func get_equipped_relics_info() -> Array:
    var result = []
    for relic_id in equipped_relics:
        result.append(equipped_relics[relic_id].get_info())
    return result

# 获取所有可用遗物的信息
func get_available_relics_info() -> Array:
    var result = []
    for relic_id in available_relics:
        # 创建临时实例获取信息
        var temp_relic = available_relics[relic_id].new()
        result.append(temp_relic.get_info())
        temp_relic.free()
    return result

# 触发事件
func trigger_event(event_type: int, event_data: Dictionary = {}) -> Dictionary:
    var modified_data = event_data.duplicate()

    # print("触发事件，类型:", event_type, "，已装备遗物:", equipped_relics.keys())

    # 遍历所有已装备的遗物
    for relic_id in equipped_relics:
        var relic = equipped_relics[relic_id]
        var event_types = relic.get_event_types()

        # print("检查遗物:", relic_id, "，关心的事件类型:", event_types, "，当前事件:", event_type)

        # 检查遗物是否关心此事件
        if event_type in event_types:
            # print("遗物", relic_id, "关心当前事件，触发效果")
            # 触发遗物效果
            modified_data = relic.on_event(event_type, modified_data)

            # 发出信号
            relic_effect_triggered.emit(relic_id, event_type)

    return modified_data

# 获取升级选项数量
func get_upgrade_options_count() -> int:
    var result = 3  # 默认值

    # 触发事件获取修改后的值
    var event_data = {"options_count": result}
    var modified_data = trigger_event(AbstractRelic.EventType.LEVEL_UP, event_data)

    if modified_data.has("options_count"):
        result = modified_data.options_count

    return result

# 获取重新随机次数
func get_reroll_count() -> int:
    var result = 3  # 默认值

    # 触发事件获取修改后的值
    var event_data = {"max_rerolls": result}
    var modified_data = trigger_event(AbstractRelic.EventType.REROLL_COUNT, event_data)

    if modified_data.has("max_rerolls"):
        result = modified_data.max_rerolls

    return result

# 修改升级选项
func modify_upgrade_options(options: Array) -> Array:
    var result = options.duplicate(true)

    # 触发事件获取修改后的值
    var event_data = {"base_options": result}
    var modified_data = trigger_event(AbstractRelic.EventType.UPGRADE_OPTIONS, event_data)

    if modified_data.has("base_options"):
        result = modified_data.base_options

    return result

# 修改重新随机选项
func modify_rerolled_options(option_index: int, reroll_count: int, available_options: Array) -> Array:
    var result = available_options.duplicate(true)

    # 触发事件获取修改后的值
    var event_data = {
        "option_index": option_index,
        "reroll_count": reroll_count,
        "available_options": result
    }
    var modified_data = trigger_event(AbstractRelic.EventType.OPTION_REROLL, event_data)

    if modified_data.has("available_options"):
        result = modified_data.available_options

    return result

# 在节点被移除时清理资源
func _exit_tree():
    # 清理所有遗物
    for relic_id in equipped_relics.keys():
        if equipped_relics[relic_id] != null and is_instance_valid(equipped_relics[relic_id]):
            equipped_relics[relic_id].queue_free()

    # 清空遗物字典
    equipped_relics.clear()
    available_relics.clear()
