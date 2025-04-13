extends Node

# 按钮效果工具类
# 用于为按钮添加视觉反馈效果

# 为按钮添加悬停效果
static func add_hover_effect(button: Button):
	# 连接信号
	if not button.mouse_entered.is_connected(_on_button_mouse_entered.bind(button)):
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	
	if not button.mouse_exited.is_connected(_on_button_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	
	if not button.pressed.is_connected(_on_button_pressed.bind(button)):
		button.pressed.connect(_on_button_pressed.bind(button))

# 为多个按钮添加悬停效果
static func add_hover_effects_to_buttons(buttons: Array):
	for button in buttons:
		if button is Button:
			add_hover_effect(button)

# 为容器中的所有按钮添加悬停效果
static func add_hover_effects_to_container(container: Container):
	for child in container.get_children():
		if child is Button:
			add_hover_effect(child)
		elif child is Container:
			add_hover_effects_to_container(child)

# 按钮鼠标进入回调
static func _on_button_mouse_entered(button: Button):
	# 创建缩放动画
	var tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)
	
	# 播放音效
	var audio_manager = button.get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_HOVER)

# 按钮鼠标离开回调
static func _on_button_mouse_exited(button: Button):
	# 创建缩放动画
	var tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN)

# 按钮点击回调
static func _on_button_pressed(button: Button):
	# 创建点击动画
	var tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05).set_ease(Tween.EASE_IN)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.05).set_ease(Tween.EASE_OUT)
	
	# 播放音效
	var audio_manager = button.get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)
