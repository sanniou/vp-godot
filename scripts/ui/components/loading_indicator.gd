extends Control

# LoadingIndicator组件 - 显示加载指示器

# 属性
var text: String = "加载中..."
var animation_speed: float = 0.3
var rotation_speed: float = 2.0

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
	$Label.text = text

# 处理旋转动画
func _process(delta):
	if visible:
		$Spinner.rotation += rotation_speed * delta

# 显示加载指示器
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

# 隐藏加载指示器
func hide_component():
	# 创建隐藏动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, animation_speed).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), animation_speed).set_ease(Tween.EASE_IN)

	# 等待动画完成
	await tween.finished

	# 隐藏
	visible = false

# 重置组件状态
func reset():
	text = "加载中..."
	modulate.a = 0
	scale = Vector2(1.0, 1.0)
	visible = false
