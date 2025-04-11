extends Control

# 语言管理器引用
var language_manager = null

# 初始化
func _ready():
    # 获取语言管理器
    # 获取语言管理器
    language_manager = get_node("/root/LanguageManager")
    if not language_manager:
        # 如果找不到语言管理器，尝试从自动加载脚本获取
        var autoload = get_node("/root/LanguageAutoload")
        if autoload and autoload.language_manager:
            language_manager = autoload.language_manager
        else:
            # 如果还是找不到，创建一个新的语言管理器
            language_manager = load("res://scripts/language/language_manager.gd").new()
            language_manager.name = "LanguageManager"
            get_tree().root.call_deferred("add_child", language_manager)

    # 连接语言变更信号
    language_manager.language_changed.connect(_on_language_changed)

    # 连接按钮信号
    $StartButton.pressed.connect(_on_start_button_pressed)
    $OptionsButton.pressed.connect(_on_options_button_pressed)
    $QuitButton.pressed.connect(_on_quit_button_pressed)

    # 更新UI文本
    update_ui_text()

# 更新UI文本
func update_ui_text():
    $TitleLabel.text = language_manager.get_translation("game_title")
    $StartButton.text = language_manager.get_translation("start_game")
    $OptionsButton.text = language_manager.get_translation("options")
    $QuitButton.text = language_manager.get_translation("quit")

# 处理语言变更
func _on_language_changed(new_language):
    update_ui_text()

# 处理开始按钮点击
func _on_start_button_pressed():
    # 切换到遗物选择场景
    get_tree().change_scene_to_file("res://scenes/relic_selection.tscn")

# 处理选项按钮点击
func _on_options_button_pressed():
    # 切换到语言选择场景
    get_tree().change_scene_to_file("res://scenes/language_selection.tscn")

# 处理退出按钮点击
func _on_quit_button_pressed():
    # 退出游戏
    get_tree().quit()
