extends Control

# Toast组件 - 显示短暂的提示消息

# 属性
var message: String = ""
var duration: float = 2.0
var animation_speed: float = 0.3

# 初始化
func _ready():
	# 设置进程模式，确保在暂停时也能工作
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 设置鼠标过滤模式，确保不会阻挡鼠标事件
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 初始状态
	visible = false

# 设置消息
func set_message(new_message: String):
	message = new_message
	$Panel/Label.text = message

# 设置持续时间
func set_duration(new_duration: float):
	duration = new_duration

# 显示Toast
func show_component():
	# 确保可见
	visible = true

	# 重置透明度和缩放
	modulate.a = 0
	scale = Vector2(0.8, 0.8)

	# 创建显示动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, animation_speed).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), animation_speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# 等待持续时间
	await get_tree().create_timer(duration).timeout

	# 创建隐藏动画
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, animation_speed).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), animation_speed).set_ease(Tween.EASE_IN)

	# 等待动画完成
	await tween.finished

	# 隐藏
	visible = false

# 重置组件状态
func reset():
	message = ""
	duration = 2.0
	modulate.a = 0
	scale = Vector2(1.0, 1.0)
	visible = false
