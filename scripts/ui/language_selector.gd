extends Control

# 语言选择器
# 允许用户选择游戏语言

signal language_changed(language_code)
signal closed

# 初始化
func _ready():
	# 设置当前语言的按钮为选中状态
	var Tr = load("res://scripts/language/tr.gd")
	var current_language = Tr.get_current_language()
	
	match current_language:
		"zh_CN":
			$Panel/VBoxContainer/LanguageGrid/ChineseButton.add_theme_color_override("font_color", Color.GREEN)
		"en_US":
			$Panel/VBoxContainer/LanguageGrid/EnglishButton.add_theme_color_override("font_color", Color.GREEN)
		"ja_JP":
			$Panel/VBoxContainer/LanguageGrid/JapaneseButton.add_theme_color_override("font_color", Color.GREEN)

# 中文按钮点击
func _on_chinese_button_pressed():
	_switch_language("zh_CN")

# 英文按钮点击
func _on_english_button_pressed():
	_switch_language("en_US")

# 日文按钮点击
func _on_japanese_button_pressed():
	_switch_language("ja_JP")

# 关闭按钮点击
func _on_close_button_pressed():
	visible = false
	closed.emit()

# 切换语言
func _switch_language(language_code):
	# 重置所有按钮颜色
	$Panel/VBoxContainer/LanguageGrid/ChineseButton.remove_theme_color_override("font_color")
	$Panel/VBoxContainer/LanguageGrid/EnglishButton.remove_theme_color_override("font_color")
	$Panel/VBoxContainer/LanguageGrid/JapaneseButton.remove_theme_color_override("font_color")
	
	# 设置选中按钮颜色
	match language_code:
		"zh_CN":
			$Panel/VBoxContainer/LanguageGrid/ChineseButton.add_theme_color_override("font_color", Color.GREEN)
		"en_US":
			$Panel/VBoxContainer/LanguageGrid/EnglishButton.add_theme_color_override("font_color", Color.GREEN)
		"ja_JP":
			$Panel/VBoxContainer/LanguageGrid/JapaneseButton.add_theme_color_override("font_color", Color.GREEN)
	
	# 使用通用翻译辅助工具切换语言
	var Tr = load("res://scripts/language/tr.gd")
	var success = Tr.switch_language(language_code)
	
	if success:
		language_changed.emit(language_code)
	else:
		print("Failed to switch language to: " + language_code)

# 显示语言选择器
func show_selector():
	visible = true
