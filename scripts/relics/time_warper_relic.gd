extends "res://scripts/relics/abstract_relic.gd"

# 时间扭曲器遗物
# 减缓敌人移动速度，增加玩家攻击速度

var enemy_speed_reduction = 0.25  # 减少敌人25%的移动速度
var player_attack_speed_bonus = 0.15  # 增加玩家15%的攻击速度

func _init():
    super._init(
        "time_warper",
        "时间扭曲器",
        "减缓敌人移动速度(25%)，增加玩家攻击速度(15%)",
        "⏱️",
        "rare"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [
        EventType.GAME_START,
        EventType.DAMAGE_DEALT
    ]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    var modified_data = event_data.duplicate()
    
    match event_type:
        EventType.GAME_START:
            # 游戏开始时，减缓所有敌人的移动速度
            print("时间扭曲器激活：减缓敌人移动速度，增加玩家攻击速度")
            
            # 添加全局修饰符
            modified_data["enemy_speed_modifier"] = -enemy_speed_reduction
            modified_data["player_attack_speed_modifier"] = player_attack_speed_bonus
            
        EventType.DAMAGE_DEALT:
            # 造成伤害时，增加伤害量
            if modified_data.has("damage"):
                # 如果是武器造成的伤害，增加攻击速度
                if modified_data.has("weapon"):
                    var weapon = modified_data["weapon"]
                    if "attack_speed" in weapon:
                        # 这里不直接修改武器属性，而是返回一个临时的攻击速度修饰符
                        modified_data["attack_speed_modifier"] = player_attack_speed_bonus
    
    return modified_data
