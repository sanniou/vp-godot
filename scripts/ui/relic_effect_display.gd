extends Node2D

# 遗物效果显示
# 当遗物效果触发时，显示一个简短的动画和文本

# 显示持续时间
var display_duration = 1.5  # 秒

# 当前显示的效果
var current_effects = []

# 初始化
func _ready():
	# 设置为顶层节点，确保显示在其他元素之上
	z_index = 100

# 显示遗物效果
func show_effect(relic_id: String, effect_text: String, position: Vector2, color: Color = Color.WHITE):
	# 创建一个新的效果显示
	var effect = {
		"relic_id": relic_id,
		"text": effect_text,
		"position": position,
		"color": color,
		"time": 0,
		"node": null
	}
	
	# 创建文本节点
	var label = Label.new()
	label.text = effect_text
	label.position = position
	label.modulate = color
	label.modulate.a = 0  # 初始透明
	
	# 设置字体大小和描边
	var font = label.get_theme_font("font")
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	
	# 添加到场景
	add_child(label)
	effect["node"] = label
	
	# 添加到当前效果列表
	current_effects.append(effect)

# 更新效果显示
func _process(delta):
	var effects_to_remove = []
	
	# 更新所有当前效果
	for effect in current_effects:
		effect["time"] += delta
		var progress = effect["time"] / display_duration
		
		if progress < 1.0:
			# 更新效果显示
			var label = effect["node"]
			
			# 淡入淡出
			var alpha = 1.0
			if progress < 0.2:
				# 淡入
				alpha = progress / 0.2
			elif progress > 0.8:
				# 淡出
				alpha = (1.0 - progress) / 0.2
			
			# 设置透明度
			label.modulate.a = alpha
			
			# 上移效果
			label.position.y = effect["position"].y - progress * 30
		else:
			# 效果结束，标记为移除
			effects_to_remove.append(effect)
	
	# 移除已完成的效果
	for effect in effects_to_remove:
		if effect["node"] and is_instance_valid(effect["node"]):
			effect["node"].queue_free()
		current_effects.erase(effect)

# 清除所有效果
func clear_effects():
	for effect in current_effects:
		if effect["node"] and is_instance_valid(effect["node"]):
			effect["node"].queue_free()
	
	current_effects.clear()
