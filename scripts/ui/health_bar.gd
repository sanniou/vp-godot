extends Control
class_name HealthBar

# 生命条属性
var max_value: float = 100.0
var current_value: float = 100.0
var bar_width: float = 40.0
var bar_height: float = 1.0
var background_color: Color = Color(0.2, 0.2, 0.2, 0.7)  # 灰色背景
var fill_color: Color = Color(0.8, 0.0, 0.0, 1.0)  # 红色填充
var low_health_color: Color = Color(1.0, 0.0, 0.0, 1.0)  # 低生命值颜色

# 动画设置
var show_animation: bool = true
var animation_speed: float = 5.0  # 动画速度
var low_health_threshold: float = 0.3  # 低生命值阈值，当生命值低于30%时闪烁
var flash_speed: float = 3.0  # 闪烁速度
var damage_flash_duration: float = 0.3  # 受伤闪烁持续时间

# 受伤闪烁相关
var is_flashing: bool = false
var flash_timer: float = 0.0
var original_color: Color

# 内部变量
var _target_fill_width: float = bar_width
var _current_fill_width: float = bar_width
var _background: ColorRect
var _fill: ColorRect

# 初始化
func _ready():
	# 设置控件大小
	custom_minimum_size = Vector2(bar_width, bar_height)
	size = Vector2(bar_width, bar_height)

	# 创建背景
	_background = ColorRect.new()
	_background.name = "Background"
	_background.size = Vector2(bar_width, bar_height)
	_background.color = background_color
	add_child(_background)

	# 创建填充
	_fill = ColorRect.new()
	_fill.name = "Fill"
	_fill.size = Vector2(bar_width, bar_height)
	_fill.color = fill_color
	add_child(_fill)

	# 保存原始颜色
	original_color = fill_color

	# 更新填充宽度
	_update_fill_width()

# 处理过程
func _process(delta):
	# 优化：如果生命条不可见，不进行处理
	if not visible:
		return

	# 优化：使用变量跟踪是否需要更新
	var needs_update = false

	# 处理受伤闪烁
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			# 闪烁结束，恢复原始颜色
			_fill.color = original_color
			is_flashing = false
			# 标记需要更新
			needs_update = true

	# 处理低生命值闪烁
	if current_value / max_value <= low_health_threshold and not is_flashing:
		# 低生命值闪烁
		var flash_value = (sin(Time.get_ticks_msec() * 0.01 * flash_speed) + 1) / 2.0
		_fill.color = original_color.lerp(low_health_color, flash_value)
		# 标记需要更新
		needs_update = true

	# 始终更新填充大小，确保血条正确显示
	if _fill:
		_fill.size = Vector2(_current_fill_width, bar_height)

# 设置最大值
func set_max_value(value: float):
	max_value = max(0.1, value)  # 防止除以零
	_update_fill_width()

# 设置当前值
func set_value(value: float, show_damage_flash: bool = false):
	# 检查是否受伤
	var old_value = current_value
	current_value = clamp(value, 0.0, max_value)

	# 如果生命值减少且需要显示受伤闪烁
	if show_damage_flash and current_value < old_value:
		# 触发受伤闪烁
		start_damage_flash()

	# 立即更新填充宽度
	_update_fill_width()

	# 确保立即更新视觉效果
	if _fill:
		_fill.size = Vector2(_current_fill_width, bar_height)

# 设置生命条大小
func set_bar_size(width: float, height: float):
	bar_width = width
	bar_height = height

	# 更新控件大小
	custom_minimum_size = Vector2(bar_width, bar_height)
	size = Vector2(bar_width, bar_height)

	# 更新背景大小
	if _background:
		_background.size = Vector2(bar_width, bar_height)

	# 更新填充大小和宽度
	_update_fill_width()

# 设置颜色
func set_colors(bg_color: Color, fill_color: Color, low_health_color: Color = Color(1.0, 0.0, 0.0, 1.0)):
	background_color = bg_color
	self.fill_color = fill_color
	self.low_health_color = low_health_color
	self.original_color = fill_color

	# 更新颜色
	if _background:
		_background.color = background_color

	if _fill:
		_fill.color = self.fill_color

# 更新填充宽度
func _update_fill_width():
	if max_value <= 0:
		return

	# 计算填充宽度
	var percent = clamp(current_value / max_value, 0.0, 1.0)
	_target_fill_width = bar_width * percent

	# 直接设置当前宽度，禁用动画效果确保立即更新
	_current_fill_width = _target_fill_width

	# 调试输出
	print("HealthBar._update_fill_width: current_value = ", current_value, ", max_value = ", max_value, ", percent = ", percent, ", width = ", _current_fill_width)

	# 更新填充矩形大小
	if _fill:
		_fill.size = Vector2(_current_fill_width, bar_height)

	# 强制重绘
	queue_redraw()

# 开始受伤闪烁
func start_damage_flash():
	# 设置闪烁颜色（白色）
	if _fill:
		_fill.color = Color(1.0, 1.0, 1.0, 1.0)

	# 设置闪烁持续时间
	flash_timer = damage_flash_duration
	is_flashing = true

# 设置低生命值阈值
func set_low_health_threshold(threshold: float):
	low_health_threshold = clamp(threshold, 0.0, 1.0)

# 设置闪烁速度
func set_flash_speed(speed: float):
	flash_speed = max(0.1, speed)

# 设置受伤闪烁持续时间
func set_damage_flash_duration(duration: float):
	damage_flash_duration = max(0.1, duration)
