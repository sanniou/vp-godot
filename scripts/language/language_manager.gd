extends Node
class_name LanguageManager

# 信号
signal language_changed(new_language)

# 当前语言
var current_language: String = "zh_CN"  # 默认语言为简体中文

# 支持的语言列表
var supported_languages: Dictionary = {
    "zh_CN": "简体中文",
    "en_US": "English",
    "ja_JP": "日本語",
    "ko_KR": "한국어",
    "ru_RU": "Русский",
    "es_ES": "Español",
    "fr_FR": "Français",
    "de_DE": "Deutsch"
}

# 翻译数据
var translations: Dictionary = {}

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
    if translations.has(key):
        return translations[key]

    # 如果找不到翻译，返回默认值或键名
    if default.is_empty():
        return key
    return default

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
