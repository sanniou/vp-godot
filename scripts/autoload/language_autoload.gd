extends Node

var language_manager = null

func _ready():
    # 使用 call_deferred 延迟创建语言管理器
    call_deferred("_create_language_manager")

func _create_language_manager():
    # 创建语言管理器
    language_manager = load("res://scripts/language/language_manager.gd").new()
    language_manager.name = "LanguageManager"

    # 添加到场景树
    get_tree().root.add_child(language_manager)

    # 加载默认语言
    language_manager.load_language("zh_CN")

    # 去掉调试日志
    # print("Language manager initialized with language: ", language_manager.get_current_language_name())
