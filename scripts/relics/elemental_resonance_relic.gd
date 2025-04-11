extends "res://scripts/relics/abstract_relic.gd"

# 元素共鸣遗物
# 使用多种武器类型时提供额外伤害加成

var damage_bonus_per_weapon_type = 0.08  # 每种武器类型增加8%伤害
var max_bonus = 0.40  # 最大增加40%伤害
var weapon_types = {}  # 记录已拥有的武器类型

func _init():
    super._init(
        "elemental_resonance",
        "元素共鸣",
        "每种不同类型的武器增加8%伤害(最大40%)",
        "🔄",
        "epic"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [
        EventType.DAMAGE_DEALT,
        EventType.LEVEL_UP
    ]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    var modified_data = event_data.duplicate()
    
    match event_type:
        EventType.DAMAGE_DEALT:
            # 造成伤害时，根据拥有的武器类型数量增加伤害
            if modified_data.has("damage") and modified_data.has("weapon"):
                var weapon = modified_data["weapon"]
                if "weapon_id" in weapon:
                    # 计算当前拥有的武器类型数量
                    var weapon_type_count = weapon_types.size()
                    
                    # 计算伤害加成
                    var bonus = min(weapon_type_count * damage_bonus_per_weapon_type, max_bonus)
                    
                    # 应用伤害加成
                    if bonus > 0:
                        modified_data["damage"] = modified_data["damage"] * (1 + bonus)
                        print("元素共鸣触发：拥有", weapon_type_count, "种武器类型，伤害增加", bonus * 100, "%")
        
        EventType.LEVEL_UP:
            # 升级时，检查是否获得了新武器
            if modified_data.has("weapon_id"):
                var weapon_id = modified_data["weapon_id"]
                
                # 获取武器类型（简单地使用武器ID的前缀作为类型）
                var weapon_type = ""
                if weapon_id.begins_with("magic"):
                    weapon_type = "magic"
                elif weapon_id.begins_with("knife"):
                    weapon_type = "knife"
                elif weapon_id.begins_with("flame"):
                    weapon_type = "flame"
                elif weapon_id.begins_with("shield"):
                    weapon_type = "shield"
                elif weapon_id.begins_with("lightning"):
                    weapon_type = "lightning"
                
                # 记录新的武器类型
                if weapon_type != "" and not weapon_types.has(weapon_type):
                    weapon_types[weapon_type] = true
                    print("元素共鸣：发现新武器类型", weapon_type, "，当前共", weapon_types.size(), "种类型")
    
    return modified_data
