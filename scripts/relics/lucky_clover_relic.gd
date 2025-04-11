extends "res://scripts/relics/abstract_relic.gd"

var options_count = 4  # 升级时获得4个选项而不是3个

func _init():
    super._init(
        "lucky_clover",
        "幸运四叶草",
        "升级时获得4个选项而不是3个",
        "🍀",
        "uncommon"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [EventType.LEVEL_UP]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    if event_type == EventType.LEVEL_UP:
        # print("幸运四叶草触发: 升级选项增加到 ", options_count)

        # 修改事件数据，增加升级选项数量
        event_data["options_count"] = options_count

    return event_data

# 获取遗物的状态信息
func get_state() -> Dictionary:
    var state = super.get_state()
    state["options_count"] = options_count
    return state

# 从状态信息恢复遗物状态
func set_state(state: Dictionary) -> void:
    super.set_state(state)
    if state.has("options_count"):
        options_count = state.options_count
