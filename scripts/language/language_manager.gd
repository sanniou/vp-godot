extends Node
class_name LanguageManager

# 信号
signal language_changed(new_language)

# 当前语言
var current_language: String = "zh_CN"  # 默认语言为简体中文

# 支持的语言列表
var supported_languages: Dictionary = {
    "zh_CN": "简体中文",
    "en_US": "English"
}

# 翻译数据
var translations: Dictionary = {}

# 翻译缓存
var translation_cache: Dictionary = {}

# 回退语言
var fallback_language: String = "en_US"  # 默认回退语言为英语

# 缓存设置
var cache_enabled: bool = true  # 是否启用缓存
var cache_size_limit: int = 1000  # 缓存项数量限制

# 初始化
func _ready():
    # 加载默认语言
    load_language(current_language)

    # 设置为单例，便于全局访问
    if Engine.get_main_loop().root.get_node_or_null("LanguageManager") == null:
        name = "LanguageManager"
        Engine.get_main_loop().root.add_child(self)

# 加载语言
func load_language(language_code: String) -> bool:
    # 检查语言是否支持
    if not supported_languages.has(language_code):
        # print("不支持的语言: ", language_code)
        return false

    # 尝试加载语言文件
    var file_path = "res://languages/" + language_code + ".json"
    var file = FileAccess.open(file_path, FileAccess.READ)

    if file == null:
        # print("无法打开语言文件: ", file_path)
        return false

    # 读取文件内容
    var json_text = file.get_as_text()
    file.close()

    # 解析JSON
    var json = JSON.new()
    var error = json.parse(json_text)

    if error != OK:
        # print("解析语言文件失败: ", json.get_error_message(), " at line ", json.get_error_line())
        return false

    # 获取翻译数据
    var data = json.get_data()

    if typeof(data) != TYPE_DICTIONARY:
        # print("语言文件格式错误: 不是有效的字典")
        return false

    # 清空缓存
    if cache_enabled:
        translation_cache.clear()

    # 更新翻译数据
    translations = data

    # 更新当前语言
    current_language = language_code

    # 发出语言变更信号
    language_changed.emit(current_language)

    # print("已加载语言: ", supported_languages[current_language])
    return true

# 切换语言
func switch_language(language_code: String) -> bool:
    return load_language(language_code)

# 获取翻译
func get_translation(key: String, default: String = "") -> String:
    # 检查缓存
    if cache_enabled and translation_cache.has(key):
        return translation_cache[key]

    # 从当前语言中查找
    if translations.has(key):
        var translation = translations[key]

        # 添加到缓存
        if cache_enabled:
            _add_to_cache(key, translation)

        return translation

    # 如果当前语言中没有找到，尝试从回退语言中查找
    if current_language != fallback_language:
        var fallback_translation = _get_fallback_translation(key)
        if not fallback_translation.is_empty():
            # 添加到缓存
            if cache_enabled:
                _add_to_cache(key, fallback_translation)

            return fallback_translation

    # 如果找不到翻译，返回默认值或键名
    var result = default if not default.is_empty() else key

    # 添加到缓存
    if cache_enabled:
        _add_to_cache(key, result)

    return result

# 从回退语言中获取翻译
func _get_fallback_translation(key: String) -> String:
    # 尝试加载回退语言文件
    var file_path = "res://languages/" + fallback_language + ".json"
    var file = FileAccess.open(file_path, FileAccess.READ)

    if file == null:
        return ""

    # 读取文件内容
    var json_text = file.get_as_text()
    file.close()

    # 解析JSON
    var json = JSON.new()
    var error = json.parse(json_text)

    if error != OK:
        return ""

    # 获取翻译数据
    var data = json.get_data()

    if typeof(data) != TYPE_DICTIONARY:
        return ""

    # 查找翻译
    if data.has(key):
        return data[key]

    return ""

# 添加到缓存
func _add_to_cache(key: String, value: String) -> void:
    # 检查缓存大小
    if translation_cache.size() >= cache_size_limit:
        # 简单的缓存清理策略：清空缓存
        translation_cache.clear()

    # 添加到缓存
    translation_cache[key] = value

# 获取当前语言名称
func get_current_language_name() -> String:
    return supported_languages[current_language]

# 获取支持的语言列表
func get_supported_languages() -> Dictionary:
    return supported_languages

# 在节点被移除时清理资源
func _exit_tree():
    # 清空翻译数据
    translations.clear()
