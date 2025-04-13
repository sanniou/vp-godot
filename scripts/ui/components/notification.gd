extends Control

# Notification组件 - 显示通知消息

# 属性
var title: String = ""
var message: String = ""
var type: String = "info"  # info, success, warning, error
var duration: float = 5.0
var animation_speed: float = 0.3

# 初始化
func _ready():
	# 设置进程模式，确保在暂停时也能工作
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 设置鼠标过滤模式，确保不会阻挡鼠标事件
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 初始状态
	visible = false

	# 连接关闭按钮信号
	$Panel/CloseButton.pressed.connect(_on_close_button_pressed)

# 设置标题
func set_title(new_title: String):
	title = new_title
	$Panel/TitleLabel.text = title

# 设置消息
func set_message(new_message: String):
	message = new_message
	$Panel/MessageLabel.text = message

# 设置类型
func set_type(new_type: String):
	type = new_type

	# 根据类型设置颜色
	var color = Color.WHITE
	match type:
		"info":
			color = Color(0.2, 0.6, 1.0)  # 蓝色
		"success":
			color = Color(0.2, 0.8, 0.4)  # 绿色
		"warning":
			color = Color(1.0, 0.8, 0.2)  # 黄色
		"error":
			color = Color(1.0, 0.3, 0.3)  # 红色

	# 应用颜色
	$Panel/TypeIcon.modulate = color

# 设置持续时间
func set_duration(new_duration: float):
	duration = new_duration

# 显示通知
func show_component():
	# 确保可见
	visible = true

	# 重置位置和透明度
	position.x = -size.x
	modulate.a = 1.0

	# 创建显示动画
	var tween = create_tween()
	tween.tween_property(self, "position:x", 20, animation_speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# 等待持续时间
	await get_tree().create_timer(duration).timeout

	# 如果仍然可见，自动隐藏
	if visible:
		hide_component()

# 隐藏通知
func hide_component():
	# 创建隐藏动画
	var tween = create_tween()
	tween.tween_property(self, "position:x", -size.x, animation_speed).set_ease(Tween.EASE_IN)

	# 等待动画完成
	await tween.finished

	# 隐藏
	visible = false

# 关闭按钮点击回调
func _on_close_button_pressed():
	# 隐藏通知
	hide()

# 重置组件状态
func reset():
	title = ""
	message = ""
	type = "info"
	duration = 5.0
	modulate.a = 1.0
	position.x = -size.x
	visible = false
