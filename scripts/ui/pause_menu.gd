extends Control

# 暂停菜单

# 预加载按钮效果脚本
const ButtonEffects = preload("res://scripts/ui/button_effects.gd")

signal resume_game
signal quit_game
signal show_settings
signal show_console
signal show_achievements
signal return_to_home

# 初始化
func _ready():
	# 连接按钮信号
	$Panel/VBoxContainer/ButtonsContainer/ResumeButton.pressed.connect(_on_resume_button_pressed)
	$Panel/VBoxContainer/ButtonsContainer/ConsoleButton.pressed.connect(_on_console_button_pressed)
	$Panel/VBoxContainer/ButtonsContainer/AchievementsButton.pressed.connect(_on_achievements_button_pressed)
	$Panel/VBoxContainer/ButtonsContainer/SettingsButton.pressed.connect(_on_settings_button_pressed)
	$Panel/VBoxContainer/HomeButton.pressed.connect(_on_home_button_pressed)
	$Panel/VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

	# 为所有按钮添加悬停效果
	ButtonEffects.add_hover_effects_to_container($Panel/VBoxContainer)

	# 初始隐藏
	hide()

# 显示暂停菜单
func show_menu():
	show()
	$VBoxContainer/ResumeButton.grab_focus()

# 隐藏暂停菜单
func hide_menu():
	hide()

# 恢复按钮回调
func _on_resume_button_pressed():
	# 播放UI点击音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

	# 发出恢复游戏信号
	resume_game.emit()
	hide_menu()

# 设置按钮回调
func _on_settings_button_pressed():
	# 播放UI点击音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

	# 发出显示设置信号
	show_settings.emit()

	# 显示音频设置面板
	print("Opening audio settings panel")

# 控制台按钮回调
func _on_console_button_pressed():
	# 播放UI点击音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

	# 发出显示控制台信号
	show_console.emit()

# 成就按钮回调
func _on_achievements_button_pressed():
	# 播放UI点击音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

	# 发出显示成就信号
	show_achievements.emit()

# 返回主页按钮回调
func _on_home_button_pressed():
	# 播放UI点击音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

	# 发出返回主页信号
	return_to_home.emit()

# 退出按钮回调
func _on_quit_button_pressed():
	# 播放UI点击音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

	# 发出退出游戏信号
	quit_game.emit()
