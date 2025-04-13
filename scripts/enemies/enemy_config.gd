extends Node
class_name EnemyConfig

# 敌人配置数据
const ENEMY_CONFIGS = {
    "basic": {
        "max_health": 30,
        "move_speed": 100,
        "attack_damage": 10,
        "attack_range": 50,
        "experience_value": 5,
        "color": Color(0.8, 0.2, 0.2, 1.0),  # 红色
        "size": Vector2(40, 40)
    },
    "ranged": {
        "max_health": 80,
        "move_speed": 80,
        "attack_damage": 15,
        "attack_range": 200,
        "experience_value": 15,
        "color": Color(0.8, 0.2, 0.8, 1.0),  # 紫色
        "size": Vector2(40, 40),
        "projectile_speed": 150,
        "attack_cooldown": 2.0
    },
    "elite": {
        "max_health": 200,
        "move_speed": 90,
        "attack_damage": 20,
        "attack_range": 70,
        "experience_value": 30,
        "physical_resistance": 0.2,
        "magic_resistance": 0.2,
        "color": Color(0.8, 0.8, 0.2, 1.0),  # 黄色
        "size": Vector2(50, 50)
    },
    "boss": {
        "max_health": 1000,
        "move_speed": 70,
        "attack_damage": 30,
        "attack_range": 100,
        "experience_value": 100,
        "physical_resistance": 0.3,
        "magic_resistance": 0.3,
        "shield": 200,
        "shield_regeneration": 5.0,
        "knockback_resistance": 0.5,
        "color": Color(0.8, 0.0, 0.0, 1.0),  # 深红色
        "size": Vector2(80, 80)
    }
}

# 获取敌人配置
static func get_config(enemy_id: String) -> Dictionary:
    if ENEMY_CONFIGS.has(enemy_id):
        return ENEMY_CONFIGS[enemy_id]
    return {}

# 使用全局敌人类型定义
const EnemyTypes = preload("res://scripts/enemies/enemy_types.gd")

# 根据敌人类型获取配置
static func get_config_by_type(enemy_type: int) -> Dictionary:
    match enemy_type:
        EnemyTypes.Type.BASIC:
            return get_config("basic")
        EnemyTypes.Type.RANGED:
            return get_config("ranged")
        EnemyTypes.Type.ELITE:
            return get_config("elite")
        EnemyTypes.Type.BOSS:
            return get_config("boss")
        _:
            return {}
