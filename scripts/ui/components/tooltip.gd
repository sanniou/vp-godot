extends Control

# Tooltip组件 - 显示悬停提示

# 属性
var text: String = ""
var animation_speed: float = 0.2

# 初始化
func _ready():
	# 设置进程模式，确保在暂停时也能工作
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 设置鼠标过滤模式，确保不会阻挡鼠标事件
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 初始状态
	visible = false

# 设置文本
func set_text(new_text: String):
	text = new_text
	$Panel/Label.text = text

	# 调整大小以适应文本
	await get_tree().process_frame
	$Panel.custom_minimum_size.x = $Panel/Label.get_minimum_size().x + 20
	$Panel.size.x = 0  # 强制重新计算大小

# 显示Tooltip
func show_component():
	# 确保可见
	visible = true

	# 重置透明度和缩放
	modulate.a = 0
	scale = Vector2(0.9, 0.9)

	# 创建显示动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, animation_speed).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), animation_speed).set_ease(Tween.EASE_OUT)

# 隐藏Tooltip
func hide_component():
	# 创建隐藏动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, animation_speed).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2(0.9, 0.9), animation_speed).set_ease(Tween.EASE_IN)

	# 等待动画完成
	await tween.finished

	# 隐藏
	visible = false

# 重置组件状态
func reset():
	text = ""
	modulate.a = 0
	scale = Vector2(1.0, 1.0)
	visible = false
