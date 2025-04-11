extends Node

# 获取翻译
static func tr(key: String, default: String = "") -> String:
    var language_manager = Engine.get_main_loop().root.get_node_or_null("LanguageManager")

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
