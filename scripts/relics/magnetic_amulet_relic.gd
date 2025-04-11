extends "res://scripts/relics/abstract_relic.gd"

var exp_boost_value = 0.2  # 经验值增加20%
var range_boost_value = 0.5  # 吸取范围增加50%

func _init():
    super._init(
        "magnetic_amulet",
        "磁力护符",
        "经验球吸取范围增加50%，经验值增加20%",
        "🧲",
        "common"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [EventType.EXPERIENCE_GAIN, EventType.ITEM_PICKUP]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    match event_type:
        EventType.EXPERIENCE_GAIN:
            # 增加获得的经验值
            if event_data.has("experience"):
                var original_exp = event_data["experience"]
                var bonus_exp = original_exp * exp_boost_value
                event_data["experience"] = original_exp + bonus_exp
                event_data["bonus_exp"] = bonus_exp
                # print("磁力护符触发: 经验值增加 ", bonus_exp, " (", exp_boost_value * 100, "%)")

        EventType.ITEM_PICKUP:
            # 增加经验球吸取范围
            if event_data.has("type") and event_data["type"] == "experience_orb":
                if event_data.has("attraction_range"):
                    var original_range = event_data["attraction_range"]
                    event_data["attraction_range"] = original_range * (1 + range_boost_value)
                    # print("磁力护符触发: 吸取范围增加 ", range_boost_value * 100, "%")

                if event_data.has("max_speed"):
                    var original_speed = event_data["max_speed"]
                    event_data["max_speed"] = original_speed * (1 + range_boost_value)

                if event_data.has("acceleration"):
                    var original_accel = event_data["acceleration"]
                    event_data["acceleration"] = original_accel * (1 + range_boost_value)

    return event_data

# 获取遗物的状态信息
func get_state() -> Dictionary:
    var state = super.get_state()
    state["exp_boost_value"] = exp_boost_value
    state["range_boost_value"] = range_boost_value
    return state

# 从状态信息恢复遗物状态
func set_state(state: Dictionary) -> void:
    super.set_state(state)
    if state.has("exp_boost_value"):
        exp_boost_value = state.exp_boost_value
    if state.has("range_boost_value"):
        range_boost_value = state.range_boost_value
