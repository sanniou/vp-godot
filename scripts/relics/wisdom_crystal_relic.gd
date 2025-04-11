extends "res://scripts/relics/abstract_relic.gd"

var applied = false  # 是否已应用效果

func _init():
    super._init(
        "wisdom_crystal",
        "智慧水晶",
        "游戏开始时自动获得一级",
        "💎",
        "uncommon"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [EventType.GAME_START]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    var modified_data = event_data.duplicate()
    if event_type == EventType.GAME_START and not applied:
        print("智慧水晶触发: 自动获得一级，事件类型:", event_type, "，枚举值:", EventType.GAME_START)

        # 标记为已应用
        applied = true

        # 修改事件数据，添加自动升级标志
        modified_data["auto_level_up"] = true
        print("智慧水晶设置自动升级标志:", modified_data)

        # 显示效果
        if event_data.has("player"):
            var player = event_data["player"]
            var effect_label = Label.new()
            effect_label.text = "智慧水晶: 获得一级!"
            effect_label.position = Vector2(-60, -50)
            effect_label.modulate = Color(0.5, 0.8, 1.0, 1.0)
            player.add_child(effect_label)

            # 动画效果
            var tween = player.create_tween()
            tween.tween_property(effect_label, "position:y", -70, 0.5)
            tween.parallel().tween_property(effect_label, "modulate:a", 0, 0.5)
            tween.tween_callback(func(): effect_label.queue_free())

    return modified_data

# 获取遗物的状态信息
func get_state() -> Dictionary:
    var state = super.get_state()
    state["applied"] = applied
    return state

# 从状态信息恢复遗物状态
func set_state(state: Dictionary) -> void:
    super.set_state(state)
    if state.has("applied"):
        applied = state.applied
