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
    # 使用自动扫描方式注册遗物
    auto_register_relics()

    # 如果自动扫描失败，使用手动注册方式
    if available_relics.size() == 0:
        manual_register_relics()

# 自动扫描并注册遗物
func auto_register_relics():
    # 遗物脚本目录
    var relics_dir = "res://scripts/relics/"

    # 获取目录中的所有文件
    var dir = DirAccess.open(relics_dir)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()

        while file_name != "":
            # 只处理 .gd 文件，并跳过抽象遗物类
            if file_name.ends_with("_relic.gd") and file_name != "abstract_relic.gd":
                # 加载遗物脚本
                var relic_script = load(relics_dir + file_name)

                # 从文件名提取遗物ID
                var relic_id = file_name.replace("_relic.gd", "")

                # 注册遗物
                register_relic(relic_id, relic_script)
                print("Auto registered relic: ", relic_id)

            # 获取下一个文件
            file_name = dir.get_next()

        dir.list_dir_end()
    else:
        print("Failed to open relics directory")

# 手动注册遗物（备用方法）
func manual_register_relics():
    # 加载已实现的遗物类
    var phoenix_feather = load("res://scripts/relics/phoenix_feather_relic.gd")
    var wisdom_crystal = load("res://scripts/relics/wisdom_crystal_relic.gd")
    var magnetic_amulet = load("res://scripts/relics/magnetic_amulet_relic.gd")
    var heart_amulet = load("res://scripts/relics/heart_amulet_relic.gd")
    var lucky_clover = load("res://scripts/relics/lucky_clover_relic.gd")
    var shadow_cloak = load("res://scripts/relics/shadow_cloak_relic.gd")
    var upgrade_enhancer = load("res://scripts/relics/upgrade_enhancer_relic.gd")
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
    register_relic("time_warper", time_warper)
    register_relic("elemental_resonance", elemental_resonance)
    register_relic("experience_catalyst", experience_catalyst)
    register_relic("critical_amulet", critical_amulet)
    register_relic("life_steal", life_steal)

    print("Manually registered relics")

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
            # 在触发效果前保存原始数据
            var original_data = modified_data.duplicate()

            # 触发遗物效果
            modified_data = relic.on_event(event_type, modified_data)

            # 检查数据是否发生变化，如果变化了则显示效果
            if _data_changed(original_data, modified_data):
                # 显示遗物效果
                _show_relic_effect(relic_id, event_type, modified_data)

            # 发出信号
            relic_effect_triggered.emit(relic_id, event_type)

    return modified_data

# 检查数据是否发生变化
func _data_changed(original_data: Dictionary, modified_data: Dictionary) -> bool:
    # 如果键的数量不同，则数据发生了变化
    if original_data.size() != modified_data.size():
        return true

    # 检查每个键的值是否发生变化
    for key in original_data.keys():
        # 如果修改后的数据中没有这个键，则数据发生了变化
        if not modified_data.has(key):
            return true

        # 如果值的类型不同，则数据发生了变化
        if typeof(original_data[key]) != typeof(modified_data[key]):
            return true

        # 如果值是字典或数组，递归检查
        if typeof(original_data[key]) == TYPE_DICTIONARY:
            if _data_changed(original_data[key], modified_data[key]):
                return true
        elif typeof(original_data[key]) == TYPE_ARRAY:
            # 简化处理，如果数组长度不同则认为发生了变化
            if original_data[key].size() != modified_data[key].size():
                return true
        # 如果是基本类型，直接比较值
        elif original_data[key] != modified_data[key]:
            return true

    # 检查修改后的数据中是否有新的键
    for key in modified_data.keys():
        if not original_data.has(key):
            return true

    # 如果所有检查都通过，则数据没有变化
    return false

# 显示遗物效果
func _show_relic_effect(relic_id: String, event_type: int, event_data: Dictionary) -> void:
    # 获取遗物实例
    var relic = equipped_relics[relic_id]
    if not relic:
        return

    # 获取主场景
    var main_scene = get_tree().current_scene
    if not main_scene:
        return

    # 检查是否有遗物效果显示节点
    var effect_display = main_scene.get_node_or_null("RelicEffectDisplay")

    # 如果没有，创建一个
    if not effect_display:
        var effect_display_scene = load("res://scenes/ui/relic_effect_display.tscn")
        if effect_display_scene:
            effect_display = effect_display_scene.instantiate()
            effect_display.name = "RelicEffectDisplay"
            main_scene.add_child(effect_display)

    # 如果有效果显示节点，显示效果
    if effect_display:
        # 获取遗物图标和名称
        var RelicUtils = load("res://scripts/utils/relic_utils.gd")
        var icon = RelicUtils.get_relic_icon(relic_id)
        var name = relic.relic_name

        # 根据事件类型生成效果文本
        var effect_text = icon + " " + name + " 激活"

        # 根据遗物稀有度设置颜色
        var color = RelicUtils.get_rarity_color(relic.rarity)

        # 计算显示位置（屏幕右上角）
        var viewport_size = get_viewport().get_visible_rect().size
        var position = Vector2(viewport_size.x - 150, 100)

        # 显示效果
        effect_display.show_effect(relic_id, effect_text, position, color)

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
