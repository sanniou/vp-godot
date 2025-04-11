extends Node
class_name EnemyFactory

# 预加载抽象敌人类
const AbstractEnemy = preload("res://scripts/enemies/abstract_enemy.gd")

# 敌人类型
enum EnemyType {
    MELEE,      # 近战敌人
    RANGED,     # 远程敌人
    ELITE,      # 精英敌人
    BOSS        # Boss敌人
}

# 敌人脚本
var enemy_scripts = {
    EnemyType.MELEE: preload("res://scripts/enemies/melee_enemy.gd"),
    EnemyType.RANGED: preload("res://scripts/enemies/ranged_enemy.gd"),
    EnemyType.ELITE: preload("res://scripts/enemies/elite_enemy.gd"),
    EnemyType.BOSS: preload("res://scripts/enemies/boss_enemy.gd")
}

# 创建敌人
func create_enemy(type: int, level: int = 1):
    # 检查类型是否有效
    if not enemy_scripts.has(type):
        print("无效的敌人类型: ", type)
        return null

    # 创建敌人实例
    var enemy_script = enemy_scripts[type]
    var enemy = enemy_script.new()

    # 手动初始化敌人
    enemy.add_to_group("enemies")
    enemy.setup_collision()
    enemy.setup_visuals()
    enemy.setup_attack_system()
    enemy.setup_skills()

    # 安全地设置等级
    if enemy.get("level") != null:
        enemy.level = level

    # 根据等级调整属性
    adjust_stats_by_level(enemy, level)

    return enemy

# 根据等级调整属性
func adjust_stats_by_level(enemy, level):
    # 每级增加10%的属性
    var level_multiplier = 1.0 + (level - 1) * 0.1

    # 安全地调整属性
    if "max_health" in enemy:
        enemy.max_health *= level_multiplier

    if "current_health" in enemy and "max_health" in enemy:
        enemy.current_health = enemy.max_health

    # 调整伤害
    if "attack_damage" in enemy:
        enemy.attack_damage *= level_multiplier

    # 调整经验值
    if "experience_value" in enemy:
        enemy.experience_value = int(enemy.experience_value * level_multiplier)

    # 更新生命条
    var health_bar = enemy.find_child("ProgressBar")
    if health_bar and "max_health" in enemy and "current_health" in enemy:
        health_bar.max_value = enemy.max_health
        health_bar.value = enemy.current_health

    # 精英和Boss敌人有护盾
    if enemy.enemy_type == AbstractEnemy.EnemyType.ELITE or enemy.enemy_type == AbstractEnemy.EnemyType.BOSS:
        enemy.shield *= level_multiplier

# 创建近战敌人
func create_melee_enemy(level: int = 1):
    return create_enemy(EnemyType.MELEE, level)

# 创建远程敌人
func create_ranged_enemy(level: int = 1):
    return create_enemy(EnemyType.RANGED, level)

# 创建精英敌人
func create_elite_enemy(level: int = 1):
    return create_enemy(EnemyType.ELITE, level)

# 创建Boss敌人
func create_boss_enemy(level: int = 1):
    return create_enemy(EnemyType.BOSS, level)
