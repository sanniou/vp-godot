extends Node
class_name EnemyFactory

# 预加载生命条类
const HealthBarClass = preload("res://scripts/ui/health_bar.gd")

# 预加载敌人类
const Enemy = preload("res://scripts/enemies/enemy.gd")

# 敌人类型
enum EnemyType {
    BASIC,      # 基本敌人（近战）
    RANGED,     # 远程敌人
    ELITE,      # 精英敌人
    BOSS        # Boss敌人
}

# 敌人场景路径
var enemy_scene_paths = {
    EnemyType.BASIC: "res://scenes/enemies/basic_enemy.tscn",
    EnemyType.RANGED: "res://scenes/enemies/ranged_enemy.tscn",
    EnemyType.ELITE: "res://scenes/enemies/strong_enemy.tscn",
    EnemyType.BOSS: "res://scenes/enemies/strong_enemy.tscn"  # 暂时使用strong_enemy作为Boss
}

# 敌人脚本路径 (保留以便兼容旧代码)
var enemy_script_paths = {
    EnemyType.BASIC: "res://scripts/enemies/basic_enemy.gd",
    EnemyType.RANGED: "res://scripts/enemies/ranged_enemy.gd",
    EnemyType.ELITE: "res://scripts/enemies/elite_enemy.gd",
    EnemyType.BOSS: "res://scripts/enemies/boss_enemy.gd"
}

# 创建敌人
func create_enemy(type: int, level: int = 1):
    # 检查类型是否有效
    if not enemy_scene_paths.has(type):
        push_error("无效的敌人类型: " + str(type))
        return null

    # 加载敌人场景
    var enemy_scene_path = enemy_scene_paths[type]
    var enemy_scene = load(enemy_scene_path)
    if enemy_scene == null:
        push_error("无法加载敌人场景: " + enemy_scene_path)
        return null

    # 实例化敌人场景
    var enemy = enemy_scene.instantiate()
    if enemy == null:
        push_error("无法实例化敌人场景")
        return null

    # 手动初始化敌人
    enemy.add_to_group("enemies")

    # 如果这些方法存在，才调用它们
    if enemy.has_method("setup_collision"):
        enemy.setup_collision()
    if enemy.has_method("setup_visuals"):
        enemy.setup_visuals()
    if enemy.has_method("setup_attack_system"):
        enemy.setup_attack_system()
    if enemy.has_method("setup_skills"):
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
    var health_bar = enemy.find_child("HealthBar")
    if health_bar and health_bar is HealthBarClass and "max_health" in enemy and "current_health" in enemy:
        health_bar.set_max_value(enemy.max_health)
        health_bar.set_value(enemy.current_health)

    # 精英和Boss敌人有护盾
    if "enemy_type" in enemy and "shield" in enemy:
        if enemy.enemy_type == Enemy.EnemyType.ELITE or enemy.enemy_type == Enemy.EnemyType.BOSS:
            enemy.shield *= level_multiplier

# 创建基本敌人
func create_basic_enemy(level: int = 1):
    return create_enemy(EnemyType.BASIC, level)

# 创建近战敌人 (兼容旧代码)
func create_melee_enemy(level: int = 1):
    return create_basic_enemy(level)

# 创建远程敌人
func create_ranged_enemy(level: int = 1):
    return create_enemy(EnemyType.RANGED, level)

# 创建精英敌人
func create_elite_enemy(level: int = 1):
    return create_enemy(EnemyType.ELITE, level)

# 创建Boss敌人
func create_boss_enemy(level: int = 1):
    return create_enemy(EnemyType.BOSS, level)
