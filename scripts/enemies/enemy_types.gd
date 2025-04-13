extends Node
class_name EnemyTypes

# 敌人类型枚举
enum Type {
    BASIC,      # 基本敌人（近战）
    RANGED,     # 远程敌人
    ELITE,      # 精英敌人
    BOSS        # Boss敌人
}

# 敌人类型名称
static func get_type_name(type: int) -> String:
    match type:
        Type.BASIC:
            return "basic"
        Type.RANGED:
            return "ranged"
        Type.ELITE:
            return "elite"
        Type.BOSS:
            return "boss"
        _:
            return "unknown"

# 敌人类型本地化名称
static func get_type_display_name(type: int) -> String:
    match type:
        Type.BASIC:
            return "基本敌人"
        Type.RANGED:
            return "远程敌人"
        Type.ELITE:
            return "精英敌人"
        Type.BOSS:
            return "Boss敌人"
        _:
            return "未知敌人"
