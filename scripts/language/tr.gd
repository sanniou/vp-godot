extends Node

# 通用翻译辅助工具
# 提供了简单的方法来获取和格式化翻译文本

# 获取语言管理器
static func get_language_manager():
    var language_manager = Engine.get_main_loop().root.get_node_or_null("LanguageManager")

    if not language_manager:
        # 如果找不到语言管理器，尝试从自动加载脚本获取
        var autoload = Engine.get_main_loop().root.get_node_or_null("LanguageAutoload")
        if autoload and autoload.language_manager:
            language_manager = autoload.language_manager

    return language_manager

# 获取翻译
static func tr(key: String, default: String = "") -> String:
    var language_manager = get_language_manager()

    if language_manager:
        return language_manager.get_translation(key, default)

    # 如果找不到语言管理器，返回默认值或键名
    if default.is_empty():
        return key
    return default

# 格式化翻译文本
static func trf(key: String, args: Array, default: String = "") -> String:
    var text = tr(key, default)

    # 替换占位符 {0}, {1}, {2}, ...
    for i in range(args.size()):
        var placeholder = "{" + str(i) + "}"
        text = text.replace(placeholder, str(args[i]))

    return text

# 获取武器名称翻译
static func weapon_name(weapon_id: String, default: String = "") -> String:
    return tr("weapon_" + weapon_id + "_name", default if not default.is_empty() else weapon_id.replace("_", " ").capitalize())

# 获取武器描述翻译
static func weapon_desc(weapon_id: String, default: String = "") -> String:
    return tr("weapon_" + weapon_id + "_desc", default if not default.is_empty() else "A weapon that damages enemies")

# 获取遗物名称翻译
static func relic_name(relic_id: String, default: String = "") -> String:
    return tr("relic_" + relic_id + "_name", default if not default.is_empty() else relic_id.replace("_", " ").capitalize())

# 获取遗物描述翻译
static func relic_desc(relic_id: String, default: String = "") -> String:
    return tr("relic_" + relic_id + "_desc", default if not default.is_empty() else "A mysterious relic with unknown powers")

# 获取敌人名称翻译
static func enemy_name(enemy_id: String, default: String = "") -> String:
    return tr("enemy_" + enemy_id + "_name", default if not default.is_empty() else enemy_id.replace("_", " ").capitalize())

# 获取武器升级选项翻译
static func weapon_upgrade(upgrade_type: String, default: String = "") -> String:
    return tr("weapon_upgrade_" + upgrade_type, default)

# 获取武器升级描述翻译
static func weapon_upgrade_desc(upgrade_type: String, default: String = "") -> String:
    return tr("weapon_upgrade_" + upgrade_type + "_desc", default)

# 获取当前语言
static func get_current_language() -> String:
    var language_manager = get_language_manager()
    if language_manager:
        return language_manager.current_language
    return "en_US"  # 默认返回英语

# 切换语言
static func switch_language(language_code: String) -> bool:
    var language_manager = get_language_manager()
    if language_manager:
        return language_manager.switch_language(language_code)
    return false
