extends "res://scripts/relics/abstract_relic.gd"

var health_boost = 25  # 最大生命值增加25

func _init():
    super._init(
        "heart_amulet",
        "生命护符",
        "最大生命值增加25",
        "❤️",
        "common"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [EventType.GAME_START]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    if event_type == EventType.GAME_START:
        # print("生命护符触发: 最大生命值增加 ", health_boost)

        # 修改事件数据，增加最大生命值
        if not event_data.has("stat_boosts"):
            event_data["stat_boosts"] = {}

        if not event_data["stat_boosts"].has("max_health"):
            event_data["stat_boosts"]["max_health"] = 0

        event_data["stat_boosts"]["max_health"] += health_boost

        # 显示效果
        if event_data.has("player"):
            var player = event_data["player"]
            var effect_label = Label.new()
            effect_label.text = "生命护符: +%d 生命值!" % health_boost
            effect_label.position = Vector2(-60, -50)
            effect_label.modulate = Color(1.0, 0.5, 0.5, 1.0)
            player.add_child(effect_label)

            # 动画效果
            var tween = player.create_tween()
            tween.tween_property(effect_label, "position:y", -70, 0.5)
            tween.parallel().tween_property(effect_label, "modulate:a", 0, 0.5)
            tween.tween_callback(func(): effect_label.queue_free())

    return event_data

# 获取遗物的状态信息
func get_state() -> Dictionary:
    var state = super.get_state()
    state["health_boost"] = health_boost
    return state

# 从状态信息恢复遗物状态
func set_state(state: Dictionary) -> void:
    super.set_state(state)
    if state.has("health_boost"):
        health_boost = state.health_boost
