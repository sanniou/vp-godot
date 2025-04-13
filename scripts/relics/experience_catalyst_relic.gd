extends "res://scripts/relics/abstract_relic.gd"

# 经验催化剂遗物
# 击杀敌人有几率掉落额外经验球

var extra_orb_chance = 0.25  # 25%几率掉落额外经验球
var extra_orb_value_multiplier = 0.5  # 额外经验球价值为原始经验的50%

func _init():
    super._init(
        "experience_catalyst",
        "经验催化剂",
        "击杀敌人有25%几率掉落额外经验球",
        "✨",
        "uncommon"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [
        EventType.ENEMY_KILLED
    ]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    var modified_data = event_data.duplicate()

    match event_type:
        EventType.ENEMY_KILLED:
            # 击杀敌人时，有几率生成额外经验球
            if randf() <= extra_orb_chance:
                # 设置生成额外经验球的标志
                modified_data["spawn_extra_orb"] = true

                # 如果有经验值信息，设置额外经验球的价值
                if modified_data.has("experience_value"):
                    var extra_value = int(modified_data["experience_value"] * extra_orb_value_multiplier)
                    modified_data["extra_orb_value"] = max(1, extra_value)  # 确保至少为1
                else:
                    # 默认额外经验值
                    modified_data["extra_orb_value"] = 5

    return modified_data
