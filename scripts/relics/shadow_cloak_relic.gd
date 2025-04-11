extends "res://scripts/relics/abstract_relic.gd"

var dodge_chance = 0.1  # 10%几率闪避敌人攻击

func _init():
    super._init(
        "shadow_cloak",
        "暗影披风",
        "10%几率闪避敌人攻击",
        "👻",
        "uncommon"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [EventType.DAMAGE_TAKEN]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    if event_type == EventType.DAMAGE_TAKEN:
        # 随机判定是否闪避
        if randf() < dodge_chance:
            # print("暗影披风触发: 闪避攻击!")

            # 修改事件数据，将伤害设为0
            event_data["damage"] = 0
            event_data["dodged"] = true

            # 显示闪避效果
            if event_data.has("player"):
                var player = event_data["player"]
                var dodge_label = Label.new()
                dodge_label.text = "闪避!"
                dodge_label.position = Vector2(-30, -50)
                dodge_label.modulate = Color(0.5, 0.5, 1.0, 1.0)
                player.add_child(dodge_label)

                # 动画效果
                var tween = player.create_tween()
                tween.tween_property(dodge_label, "position:y", -70, 0.5)
                tween.parallel().tween_property(dodge_label, "modulate:a", 0, 0.5)
                tween.tween_callback(func(): dodge_label.queue_free())

    return event_data

# 获取遗物的状态信息
func get_state() -> Dictionary:
    var state = super.get_state()
    state["dodge_chance"] = dodge_chance
    return state

# 从状态信息恢复遗物状态
func set_state(state: Dictionary) -> void:
    super.set_state(state)
    if state.has("dodge_chance"):
        dodge_chance = state.dodge_chance
