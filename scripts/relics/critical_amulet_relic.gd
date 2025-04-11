extends "res://scripts/relics/abstract_relic.gd"

# 暴击护符遗物
# 增加武器暴击几率和暴击伤害

var crit_chance_bonus = 0.15  # 增加15%暴击几率
var crit_damage_multiplier = 2.0  # 暴击伤害倍率

func _init():
    super._init(
        "critical_amulet",
        "暴击护符",
        "增加15%暴击几率，暴击造成双倍伤害",
        "🔮",
        "rare"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [
        EventType.DAMAGE_DEALT
    ]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    var modified_data = event_data.duplicate()
    
    match event_type:
        EventType.DAMAGE_DEALT:
            # 造成伤害时，有几率触发暴击
            if modified_data.has("damage"):
                # 检查是否暴击
                if randf() <= crit_chance_bonus:
                    # 计算暴击伤害
                    var original_damage = modified_data["damage"]
                    var crit_damage = original_damage * crit_damage_multiplier
                    
                    # 更新伤害值
                    modified_data["damage"] = crit_damage
                    modified_data["is_critical"] = true
                    
                    print("暴击护符触发：原始伤害", original_damage, "，暴击伤害", crit_damage)
    
    return modified_data
