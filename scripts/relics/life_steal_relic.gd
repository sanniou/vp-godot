extends "res://scripts/relics/abstract_relic.gd"

# 生命窃取遗物
# 造成伤害时恢复少量生命值

var life_steal_percent = 0.05  # 造成伤害的5%转化为生命值
var heal_cooldown = 0.5  # 治疗冷却时间（秒）
var last_heal_time = 0.0  # 上次治疗时间

func _init():
    super._init(
        "life_steal",
        "生命窃取",
        "造成伤害时恢复伤害值5%的生命值",
        "💉",
        "uncommon"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [
        EventType.DAMAGE_DEALT,
        EventType.TIMER_TICK
    ]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    var modified_data = event_data.duplicate()
    
    match event_type:
        EventType.DAMAGE_DEALT:
            # 造成伤害时，恢复少量生命值
            if modified_data.has("damage") and modified_data.has("player"):
                var player = modified_data["player"]
                var current_time = Time.get_ticks_msec() / 1000.0
                
                # 检查冷却时间
                if current_time - last_heal_time >= heal_cooldown:
                    # 计算恢复量
                    var damage = modified_data["damage"]
                    var heal_amount = damage * life_steal_percent
                    
                    # 设置恢复生命值的标志
                    modified_data["heal_player"] = true
                    modified_data["heal_amount"] = heal_amount
                    
                    # 更新上次治疗时间
                    last_heal_time = current_time
                    
                    print("生命窃取触发：造成", damage, "伤害，恢复", heal_amount, "生命值")
        
        EventType.TIMER_TICK:
            # 更新计时器
            if modified_data.has("delta"):
                # 这里不需要做任何事情，只是为了接收计时器事件
                pass
    
    return modified_data
