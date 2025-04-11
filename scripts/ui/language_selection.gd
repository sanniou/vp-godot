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

    # 连接返回按钮信号
    $BackButton.pressed.connect(_on_back_button_pressed)

    # 生成语言选择按钮
    generate_language_buttons()

    # 更新UI文本
    update_ui_text()

# 生成语言选择按钮
func generate_language_buttons():
    var languages = language_manager.get_supported_languages()
    var button_container = $LanguageButtonContainer

    # 清空现有按钮
    for child in button_container.get_children():
        child.queue_free()

    # 为每种语言创建按钮
    for language_code in languages:
        var language_name = languages[language_code]

        var button = Button.new()
        button.text = language_name
        button.custom_minimum_size = Vector2(200, 50)
        button.set_meta("language_code", language_code)

        # 高亮显示当前选择的语言
        if language_code == language_manager.current_language:
            button.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
            button.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.3, 1))

        # 连接按钮信号
        button.pressed.connect(_on_language_button_pressed.bind(button))

        # 添加到容器
        button_container.add_child(button)

# 更新UI文本
func update_ui_text():
    $TitleLabel.text = language_manager.get_translation("language")
    $BackButton.text = language_manager.get_translation("back")

# 处理语言按钮点击
func _on_language_button_pressed(button):
    var language_code = button.get_meta("language_code")

    # 切换语言
    if language_manager.switch_language(language_code):
        # 重新生成按钮以更新高亮显示
        generate_language_buttons()

        # 更新UI文本
        update_ui_text()

# 处理返回按钮点击
func _on_back_button_pressed():
    # 返回到上一个场景
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
