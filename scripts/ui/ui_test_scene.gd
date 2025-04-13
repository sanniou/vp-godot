extends Control

# UI测试场景 - 用于测试UI组件池

# 初始化
func _ready():
	# 连接按钮信号
	$VBoxContainer/ToastButton.pressed.connect(_on_toast_button_pressed)
	$VBoxContainer/TooltipButton.pressed.connect(_on_tooltip_button_pressed)
	$VBoxContainer/PopupButton.pressed.connect(_on_popup_button_pressed)
	$VBoxContainer/LoadingButton.pressed.connect(_on_loading_button_pressed)
	$VBoxContainer/NotificationButton.pressed.connect(_on_notification_button_pressed)
	$VBoxContainer/BackButton.pressed.connect(_on_back_button_pressed)

# Toast按钮回调
func _on_toast_button_pressed():
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		ui_manager.show_toast("这是一条测试提示消息", 2.0)

# Tooltip按钮回调
func _on_tooltip_button_pressed():
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		var tooltip = ui_manager.show_tooltip("这是一个工具提示", get_global_mouse_position())

		# 3秒后自动隐藏
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(tooltip) and not tooltip.is_queued_for_deletion():
			ui_manager.hide_tooltip(tooltip)

# Popup按钮回调
func _on_popup_button_pressed():
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		var options = [
			{"text": "选项1", "id": 1},
			{"text": "选项2", "id": 2},
			{"text": "选项3", "id": 3}
		]

		var popup = ui_manager.show_popup("测试弹窗", "这是一个测试弹窗，请选择一个选项", options, func(option_id): print("选择了选项: ", option_id))

# Loading按钮回调
func _on_loading_button_pressed():
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		var loading = ui_manager.show_loading("正在加载...")

		# 模拟加载过程
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(loading) and not loading.is_queued_for_deletion():
			ui_manager.hide_loading(loading)

# Notification按钮回调
func _on_notification_button_pressed():
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		var types = ["info", "success", "warning", "error"]
		var type = types[randi() % types.size()]

		ui_manager.show_notification("测试通知", "这是一个" + type + "类型的测试通知", type, 5.0)

# 返回按钮回调
func _on_back_button_pressed():
	# 返回主场景
	get_tree().change_scene_to_file("res://scenes/main.tscn")
