extends Node

# UI管理器 - 管理UI页面的导航

# 页面类型枚举
enum PageType {
	NONE,
	START_SCREEN,
	PAUSE_MENU,
	AUDIO_SETTINGS,
	CONSOLE,
	ACHIEVEMENTS,
	GAME_OVER
}

# 页面栈
var page_stack = []

# 当前页面
var current_page = PageType.NONE

# 页面节点引用
var page_nodes = {}

# 主场景引用
var main_scene = null

# 初始化
func _ready():
	# 设置进程模式，确保在暂停时也能工作
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 等待主场景加载完成
	await get_tree().process_frame

	# 获取主场景引用
	main_scene = get_tree().get_root().get_node_or_null("Main")
	if not main_scene:
		push_error("UIManager: 无法找到主场景")
		return

	# 初始化页面节点引用
	_initialize_page_nodes()

	# 连接信号
	_connect_signals()

	# 检测当前显示的页面
	_detect_initial_page()

	print("UIManager 初始化完成")

# 初始化页面节点引用
func _initialize_page_nodes():
	if not main_scene:
		return

	# 获取页面节点引用
	page_nodes[PageType.START_SCREEN] = main_scene.get_node_or_null("UI/StartScreen")
	page_nodes[PageType.PAUSE_MENU] = main_scene.get_node_or_null("UI/PauseMenu")
	page_nodes[PageType.AUDIO_SETTINGS] = main_scene.get_node_or_null("UI/AudioSettingsPanel")
	page_nodes[PageType.CONSOLE] = main_scene.get_node_or_null("UI/ConsolePanel")
	page_nodes[PageType.GAME_OVER] = main_scene.get_node_or_null("UI/GameOverScreen")

	# 成就页面可能是动态加载的，暂时不检查
	page_nodes[PageType.ACHIEVEMENTS] = null

	# 检查节点是否存在
	for page_type in page_nodes:
		if not page_nodes[page_type] and page_type != PageType.ACHIEVEMENTS:
			push_warning("UIManager: 找不到页面节点: " + str(page_type))

# 连接信号
func _connect_signals():
	# 连接键盘输入信号
	get_viewport().connect("gui_focus_changed", _on_gui_focus_changed)

# 处理输入
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# 如果页面栈不为空，返回上一页
		if not page_stack.is_empty():
			go_back()

# 打开页面
func open_page(page_type):
	print("UIManager: 打开页面: ", page_type)

	# 如果是成就页面，尝试动态获取
	if page_type == PageType.ACHIEVEMENTS and (not page_nodes.has(page_type) or not page_nodes[page_type]):
		# 尝试获取成就页面
		page_nodes[PageType.ACHIEVEMENTS] = main_scene.get_node_or_null("UI/AchievementScreen")

		# 如果还是找不到，可能需要动态加载
		if not page_nodes[PageType.ACHIEVEMENTS]:
			# 这里可以添加动态加载成就页面的代码
			push_warning("UIManager: 成就页面不存在，需要先创建")
			return

	# 检查页面是否存在
	if not page_nodes.has(page_type) or not page_nodes[page_type]:
		push_error("UIManager: 尝试打开不存在的页面: " + str(page_type))
		return

	# 如果当前已经是这个页面，不做任何操作
	if current_page == page_type:
		return

	# 将当前页面压入栈
	if current_page != PageType.NONE:
		page_stack.push_back(current_page)

		# 隐藏当前页面
		_hide_page(current_page)
	elif page_type == PageType.ACHIEVEMENTS or page_type == PageType.AUDIO_SETTINGS or page_type == PageType.CONSOLE:
		# 特殊处理：如果当前页面是 NONE，但我们正在打开设置类页面
		# 尝试检测当前可见的页面并将其压入栈
		if page_nodes[PageType.START_SCREEN] and page_nodes[PageType.START_SCREEN].visible:
			page_stack.push_back(PageType.START_SCREEN)
			_hide_page(PageType.START_SCREEN)
			print("UIManager: 从开始页面打开页面，将开始页面压入栈")
		elif page_nodes[PageType.GAME_OVER] and page_nodes[PageType.GAME_OVER].visible:
			page_stack.push_back(PageType.GAME_OVER)
			_hide_page(PageType.GAME_OVER)
			print("UIManager: 从游戏结束页面打开页面，将游戏结束页面压入栈")
		elif page_nodes[PageType.PAUSE_MENU] and page_nodes[PageType.PAUSE_MENU].visible:
			page_stack.push_back(PageType.PAUSE_MENU)
			_hide_page(PageType.PAUSE_MENU)
			print("UIManager: 从暂停菜单打开页面，将暂停菜单压入栈")

	# 更新当前页面
	current_page = page_type

	# 显示新页面
	_show_page(current_page)

	print("UIManager: 页面栈: ", page_stack)

# 返回上一页
func go_back():
	print("UIManager: 返回上一页")

	# 检查页面栈是否为空
	if page_stack.is_empty():
		push_warning("UIManager: 页面栈为空，无法返回")

		# 特殊处理：如果页面栈为空，尝试返回到开始页面
		if current_page == PageType.AUDIO_SETTINGS or current_page == PageType.ACHIEVEMENTS or current_page == PageType.CONSOLE:
			# 隐藏当前页面
			_hide_page(current_page)

			# 尝试显示开始页面
			if page_nodes[PageType.START_SCREEN]:
				current_page = PageType.START_SCREEN
				_show_page(PageType.START_SCREEN)
				print("UIManager: 页面栈为空，返回到开始页面")
				return
		return

	# 隐藏当前页面
	_hide_page(current_page)

	# 弹出上一页
	var previous_page = page_stack.pop_back()

	# 更新当前页面
	current_page = previous_page

	# 显示上一页
	_show_page(current_page)

	print("UIManager: 页面栈: ", page_stack)

# 清空页面栈并打开指定页面
func clear_and_open_page(page_type):
	print("UIManager: 清空页面栈并打开页面: ", page_type)

	# 隐藏当前页面
	if current_page != PageType.NONE:
		_hide_page(current_page)

	# 清空页面栈
	page_stack.clear()

	# 更新当前页面
	current_page = page_type

	# 显示新页面
	_show_page(current_page)

# 显示页面
func _show_page(page_type):
	# 如果是 NONE 页面，不需要显示
	if page_type == PageType.NONE:
		return

	# 检查页面是否存在
	if not page_nodes.has(page_type) or not page_nodes[page_type]:
		# 如果是成就页面，再次尝试获取
		if page_type == PageType.ACHIEVEMENTS:
			page_nodes[PageType.ACHIEVEMENTS] = main_scene.get_node_or_null("UI/AchievementScreen")
			if not page_nodes[PageType.ACHIEVEMENTS]:
				push_warning("UIManager: 无法显示成就页面，页面不存在")
				return
		else:
			push_warning("UIManager: 无法显示页面，页面不存在: " + str(page_type))
			return

	var page = page_nodes[page_type]

	# 根据页面类型执行特定操作
	match page_type:
		PageType.START_SCREEN:
			page.visible = true
			# 确保游戏未暂停
			get_tree().paused = false
		PageType.PAUSE_MENU:
			page.visible = true
			# 如果是从暂停菜单打开的其他页面，返回时保持暂停状态
			get_tree().paused = true
			if page.has_method("show_menu"):
				page.show_menu()
		PageType.AUDIO_SETTINGS:
			page.visible = true
			# 确保在最上层
			page.z_index = 100
			# 移到最前面
			page.get_parent().move_child(page, page.get_parent().get_child_count() - 1)
			# 打印调试信息
			print("Opening audio settings panel")
		PageType.CONSOLE:
			page.visible = true
			# 确保在最上层
			page.z_index = 100
			# 移到最前面
			page.get_parent().move_child(page, page.get_parent().get_child_count() - 1)
			# 如果控制台有输入框，让它获取焦点
			if page.has_method("_ensure_input_focus"):
				page.call_deferred("_ensure_input_focus")
		PageType.ACHIEVEMENTS:
			page.visible = true
			# 确保在最上层
			page.z_index = 100
			# 移到最前面
			if page.get_parent():
				page.get_parent().move_child(page, page.get_parent().get_child_count() - 1)
		PageType.GAME_OVER:
			page.visible = true
			# 游戏结束时暂停游戏
			get_tree().paused = true

# 隐藏页面
func _hide_page(page_type):
	# 如果是 NONE 页面，不需要隐藏
	if page_type == PageType.NONE:
		return

	# 检查页面是否存在
	if not page_nodes.has(page_type) or not page_nodes[page_type]:
		# 如果是成就页面，再次尝试获取
		if page_type == PageType.ACHIEVEMENTS:
			page_nodes[PageType.ACHIEVEMENTS] = main_scene.get_node_or_null("UI/AchievementScreen")
			if not page_nodes[PageType.ACHIEVEMENTS]:
				# 成就页面不存在，忽略
				return
		else:
			# 其他页面不存在，返回警告
			push_warning("UIManager: 无法隐藏页面，页面不存在: " + str(page_type))
			return

	var page = page_nodes[page_type]

	# 根据页面类型执行特定操作
	match page_type:
		PageType.PAUSE_MENU:
			page.visible = false
			if page.has_method("hide_menu"):
				page.hide_menu()
		_:
			page.visible = false

# 获取当前页面类型
func get_current_page():
	return current_page

# 获取页面栈
func get_page_stack():
	return page_stack.duplicate()

# 检查页面是否在栈中
func is_page_in_stack(page_type):
	return page_type in page_stack

# 检测初始页面
func _detect_initial_page():
	# 检测当前显示的页面
	if main_scene:
		# 首先检查开始页面
		if page_nodes[PageType.START_SCREEN] and page_nodes[PageType.START_SCREEN].visible:
			current_page = PageType.START_SCREEN
			print("UIManager: 检测到初始页面为开始页面")
		# 然后检查游戏结束页面
		elif page_nodes[PageType.GAME_OVER] and page_nodes[PageType.GAME_OVER].visible:
			current_page = PageType.GAME_OVER
			print("UIManager: 检测到初始页面为游戏结束页面")
		# 最后检查暂停菜单
		elif page_nodes[PageType.PAUSE_MENU] and page_nodes[PageType.PAUSE_MENU].visible:
			current_page = PageType.PAUSE_MENU
			print("UIManager: 检测到初始页面为暂停菜单")

# 处理GUI焦点变化
func _on_gui_focus_changed(control):
	# 可以在这里处理焦点变化，例如确保焦点在当前页面内
	pass
