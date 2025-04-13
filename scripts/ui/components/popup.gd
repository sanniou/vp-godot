extends Control

# Popup组件 - 显示弹出窗口

# 信号
signal option_selected(option_id)
signal closed

# 属性
var title: String = ""
var content: String = ""
var options: Array = []
var callback = null
var animation_speed: float = 0.3

# 初始化
func _ready():
	# 设置进程模式，确保在暂停时也能工作
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 设置鼠标过滤模式，确保可以接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 初始状态
	visible = false

	# 连接关闭按钮信号
	$Panel/CloseButton.pressed.connect(_on_close_button_pressed)

# 设置标题
func set_title(new_title: String):
	title = new_title
	$Panel/TitleLabel.text = title

# 设置内容
func set_content(new_content: String):
	content = new_content
	$Panel/ContentLabel.text = content

# 设置选项
func set_options(new_options: Array):
	options = new_options

	# 清除现有选项按钮
	for child in $Panel/OptionsContainer.get_children():
		child.queue_free()

	# 创建新的选项按钮
	for option in options:
		var button = Button.new()
		button.text = option.get("text", "")
		button.custom_minimum_size = Vector2(120, 40)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# 设置按钮ID
		var option_id = option.get("id", options.find(option))
		button.set_meta("option_id", option_id)

		# 连接按钮信号
		button.pressed.connect(_on_option_button_pressed.bind(option_id))

		# 添加到选项容器
		$Panel/OptionsContainer.add_child(button)

# 设置回调
func set_callback(new_callback):
	callback = new_callback

# 显示Popup
func show_component():
	# 确保可见
	visible = true

	# 重置透明度和缩放
	modulate.a = 0
	scale = Vector2(0.9, 0.9)

	# 创建显示动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, animation_speed).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), animation_speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# 聚焦第一个选项按钮
	if $Panel/OptionsContainer.get_child_count() > 0:
		$Panel/OptionsContainer.get_child(0).grab_focus()

# 隐藏Popup
func hide_component():
	# 创建隐藏动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, animation_speed).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2(0.9, 0.9), animation_speed).set_ease(Tween.EASE_IN)

	# 等待动画完成
	await tween.finished

	# 隐藏
	visible = false

	# 发出关闭信号
	closed.emit()

# 选项按钮点击回调
func _on_option_button_pressed(option_id):
	# 发出选项选择信号
	option_selected.emit(option_id)

	# 调用回调
	if callback:
		callback.call(option_id)

	# 隐藏弹出窗口
	hide()

# 关闭按钮点击回调
func _on_close_button_pressed():
	# 隐藏弹出窗口
	hide()

# 重置组件状态
func reset():
	title = ""
	content = ""
	options = []
	callback = null
	modulate.a = 0
	scale = Vector2(1.0, 1.0)
	visible = false

	# 清除选项按钮
	for child in $Panel/OptionsContainer.get_children():
		child.queue_free()
