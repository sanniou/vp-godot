extends Control

# 控制台面板 - 游戏内调试控制台

# 控制台管理器引用
var console_manager = null

# 节点引用
@onready var output_text = $VBoxContainer/OutputPanel/OutputText
@onready var input_field = $VBoxContainer/InputContainer/InputField
@onready var toggle_button = $ToggleButton

# 初始化
func _ready():
	# 创建控制台管理器
	console_manager = load("res://scripts/debug/console_manager.gd").new()
	add_child(console_manager)

	# 连接信号
	console_manager.command_executed.connect(_on_command_executed)
	input_field.text_submitted.connect(_on_input_submitted)
	toggle_button.pressed.connect(_on_toggle_button_pressed)

	# 确保控制台的所有子节点在暂停时也能工作
	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_ALWAYS

	# 确保输入相关组件在暂停时也能工作
	input_field.process_mode = Node.PROCESS_MODE_ALWAYS
	$VBoxContainer/InputContainer/ExecuteButton.process_mode = Node.PROCESS_MODE_ALWAYS
	toggle_button.process_mode = Node.PROCESS_MODE_ALWAYS

	# 初始状态
	visible = false

	# 添加欢迎消息
	add_message("欢迎使用游戏控制台! 输入 'help' 获取可用命令列表。", Color.LIGHT_BLUE)

# 处理输入
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_QUOTELEFT:  # 波浪键 (~)
			toggle_console()
			get_viewport().set_input_as_handled()

		if visible:
			# 处理 Tab 键，防止切换焦点
			if event.pressed and event.keycode == KEY_TAB:
				# 在输入框中插入制表符或实现命令自动补全
				# 这里我们只是阻止默认行为
				get_viewport().set_input_as_handled()

				# 实现命令自动补全
				auto_complete_command()

			# 处理上下方向键，浏览命令历史
			elif event.pressed and event.keycode == KEY_UP:
				input_field.text = console_manager.get_previous_command()
				input_field.caret_column = input_field.text.length()
				get_viewport().set_input_as_handled()
			elif event.pressed and event.keycode == KEY_DOWN:
				input_field.text = console_manager.get_next_command()
				input_field.caret_column = input_field.text.length()
				get_viewport().set_input_as_handled()
			# 处理 ESC 键，关闭控制台
			elif event.pressed and event.keycode == KEY_ESCAPE:
				# 关闭控制台
				visible = false

				# 检查是否需要恢复游戏
				var main = get_tree().get_root().get_node_or_null("Main")
				if main:
					if main.pause_screen.visible:
						# 如果暂停菜单可见，保持暂停状态
						get_tree().paused = true
					else:
						# 如果暂停菜单不可见，恢复游戏
						get_tree().paused = false

				get_viewport().set_input_as_handled()
			# 处理回车键，确保在提交后保持焦点
			elif event.pressed and event.keycode == KEY_ENTER:
				# 在下一帧确保输入框获取焦点
				call_deferred("_ensure_input_focus")

# 切换控制台显示
func toggle_console():
	visible = !visible

	if visible:
		# 打开控制台
		get_tree().paused = true

		# 使用 call_deferred 确保在当前帧结束后获取焦点
		# 这样可以避免焦点被其他控件抢占
		call_deferred("_ensure_input_focus")
	else:
		# 关闭控制台
		var main = get_tree().get_root().get_node_or_null("Main")
		if main:
			if main.pause_screen.visible:
				# 如果暂停菜单可见，保持暂停状态
				get_tree().paused = true
			else:
				# 如果暂停菜单不可见，恢复游戏
				get_tree().paused = false

# 添加消息到输出
func add_message(text, color = Color.WHITE):
	output_text.push_color(color)
	output_text.add_text(text)
	output_text.newline()
	output_text.pop()

# 清空输出
func clear_output():
	output_text.clear()

# 输入提交处理
func _on_input_submitted(text):
	if text.strip_edges().is_empty():
		# 即使没有文本也要保持焦点
		input_field.grab_focus()
		return

	# 显示输入的命令
	add_message("> " + text, Color.YELLOW)

	# 执行命令
	var result = console_manager.execute_command(text)

	# 显示结果
	if result and result != "":
		add_message(result)

	# 清空输入框
	input_field.clear()

	# 使用 call_deferred 确保在当前帧结束后重新获取焦点
	call_deferred("_ensure_input_focus")

# 命令执行回调
func _on_command_executed(command, result):
	if command == "clear":
		clear_output()
		add_message("控制台已清空", Color.LIGHT_BLUE)

# 切换按钮点击
func _on_toggle_button_pressed():
	toggle_console()

# 执行按钮点击
func _on_execute_button_pressed():
	_on_input_submitted(input_field.text)

# 确保输入框获取焦点
func _ensure_input_focus():
	# 如果控制台可见，则确保输入框获取焦点
	if visible:
		input_field.grab_focus()

		# 强制输入框成为当前焦点节点
		get_viewport().gui_get_focus_owner()
		if get_viewport().gui_get_focus_owner() != input_field:
			print("Forcing focus to input field")
			get_viewport().set_input_as_handled()
			input_field.grab_focus()

# 命令自动补全
func auto_complete_command():
	# 获取当前输入的文本
	var current_text = input_field.text

	# 如果没有输入，不进行补全
	if current_text.strip_edges().is_empty():
		return

	# 获取所有可用命令
	var available_commands = console_manager.registered_commands.keys()

	# 找到与当前输入匹配的命令
	var matching_commands = []
	for cmd in available_commands:
		if cmd.begins_with(current_text):
			matching_commands.append(cmd)

	# 如果有匹配的命令
	if matching_commands.size() > 0:
		if matching_commands.size() == 1:
			# 只有一个匹配，直接补全
			input_field.text = matching_commands[0] + " "
			input_field.caret_column = input_field.text.length()
		else:
			# 多个匹配，显示可能的补全选项
			var common_prefix = find_common_prefix(matching_commands)
			if common_prefix.length() > current_text.length():
				# 如果有共同前缀，先补全到共同前缀
				input_field.text = common_prefix
				input_field.caret_column = input_field.text.length()

			# 显示所有可能的补全选项
			add_message("可用的命令:")
			for cmd in matching_commands:
				add_message("  " + cmd)

# 找到字符串数组的共同前缀
func find_common_prefix(strings: Array) -> String:
	if strings.size() == 0:
		return ""

	var prefix = strings[0]
	for i in range(1, strings.size()):
		var j = 0
		while j < prefix.length() and j < strings[i].length() and prefix[j] == strings[i][j]:
			j += 1
		prefix = prefix.substr(0, j)

	return prefix
