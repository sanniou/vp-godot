extends "res://scripts/relics/abstract_relic.gd"

var used = false  # 是否已使用

func _init():
    super._init(
        "phoenix_feather",
        "凤凰之羽",
        "死亡时自动复活一次，恢复50%生命值",
        "🔥",
        "rare"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [EventType.PLAYER_DEATH]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    if event_type == EventType.PLAYER_DEATH and not used:
        # print("凤凰之羽触发: 玩家复活")

        # 标记为已使用
        used = true

        # 修改事件数据，阻止死亡并恢复生命值
        event_data["prevent_death"] = true
        event_data["heal_percent"] = 0.5

        # 显示复活效果
        if event_data.has("player"):
            var player = event_data["player"]
            var res_label = Label.new()
            res_label.text = "凤凰之羽: 复活!"
            res_label.position = Vector2(-60, -50)
            res_label.modulate = Color(1.0, 0.8, 0.0, 1.0)
            player.add_child(res_label)

            # 动画效果
            var tween = player.create_tween()
            tween.tween_property(res_label, "position:y", -70, 0.5)
            tween.parallel().tween_property(res_label, "modulate:a", 0, 0.5)
            tween.tween_callback(func(): res_label.queue_free())

    return event_data

# 获取遗物的状态信息
func get_state() -> Dictionary:
    var state = super.get_state()
    state["used"] = used
    return state

# 从状态信息恢复遗物状态
func set_state(state: Dictionary) -> void:
    super.set_state(state)
    if state.has("used"):
        used = state.used
