extends Node

# UI管理器 - 管理UI页面的导航

# 预加载类
const UIComponentPoolClass = preload("res://scripts/ui/ui_component_pool.gd")

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

# UI组件类型
enum ComponentType {
	TOAST,
	TOOLTIP,
	POPUP,
	LOADING_INDICATOR,
	NOTIFICATION
}

# 页面栈
var page_stack = []

# 当前页面
var current_page = PageType.NONE

# 页面节点引用
var page_nodes = {}

# 记录设置页面的入口点
var settings_entry_point = PageType.NONE

# 主场景引用
var main_scene = null

# UI组件池
var component_pool = null

# 初始化
func _ready():
	# 设置进程模式，确保在暂停时也能工作
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 初始化UI组件池
	_initialize_component_pool()

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

# 初始化UI组件池
func _initialize_component_pool():
	# 创建UI组件池
	component_pool = UIComponentPoolClass.new()
	component_pool.name = "UIComponentPool"
	add_child(component_pool)

	# 初始化各类组件池
	component_pool.initialize_pool("toast", "res://scenes/ui/components/toast.tscn", 5)
	component_pool.initialize_pool("tooltip", "res://scenes/ui/components/tooltip.tscn", 5)
	component_pool.initialize_pool("popup", "res://scenes/ui/components/popup.tscn", 3)
	component_pool.initialize_pool("loading", "res://scenes/ui/components/loading_indicator.tscn", 2)
	component_pool.initialize_pool("notification", "res://scenes/ui/components/notification.tscn", 5)

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
		# 只对必要的页面节点发出警告
		if not page_nodes[page_type] and page_type in [PageType.START_SCREEN, PageType.GAME_OVER]:
			push_warning("UIManager: 找不到关键页面节点: " + str(page_type))

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

		# 记录设置页面的入口点
		if page_type == PageType.AUDIO_SETTINGS or page_type == PageType.ACHIEVEMENTS or page_type == PageType.CONSOLE:
			settings_entry_point = current_page

		# 隐藏当前页面
		_hide_page(current_page)
	elif page_type == PageType.ACHIEVEMENTS or page_type == PageType.AUDIO_SETTINGS or page_type == PageType.CONSOLE:
		# 特殊处理：如果当前页面是 NONE，但我们正在打开设置类页面
		# 尝试检测当前可见的页面并将其压入栈
		if page_nodes[PageType.START_SCREEN] and page_nodes[PageType.START_SCREEN].visible:
			page_stack.push_back(PageType.START_SCREEN)
			settings_entry_point = PageType.START_SCREEN
			_hide_page(PageType.START_SCREEN)
			print("UIManager: 从开始页面打开页面，将开始页面压入栈")
		elif page_nodes[PageType.GAME_OVER] and page_nodes[PageType.GAME_OVER].visible:
			page_stack.push_back(PageType.GAME_OVER)
			settings_entry_point = PageType.GAME_OVER
			_hide_page(PageType.GAME_OVER)
			print("UIManager: 从游戏结束页面打开页面，将游戏结束页面压入栈")
		elif page_nodes[PageType.PAUSE_MENU] and page_nodes[PageType.PAUSE_MENU].visible:
			page_stack.push_back(PageType.PAUSE_MENU)
			settings_entry_point = PageType.PAUSE_MENU
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

		# 特殊处理：如果页面栈为空，尝试返回到设置页面的入口点
		if current_page == PageType.AUDIO_SETTINGS or current_page == PageType.ACHIEVEMENTS or current_page == PageType.CONSOLE:
			# 隐藏当前页面
			_hide_page(current_page)

			# 如果有记录的入口点，返回到入口点
			if settings_entry_point != PageType.NONE and page_nodes[settings_entry_point]:
				current_page = settings_entry_point
				_show_page(settings_entry_point)
				print("UIManager: 页面栈为空，返回到入口点: ", settings_entry_point)
				return
			# 如果没有入口点，尝试返回到开始页面
			elif page_nodes[PageType.START_SCREEN]:
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

	# 页面过渡动画参数
	var transition_time = 0.3
	var transition_type = Tween.TRANS_CUBIC
	var transition_ease = Tween.EASE_OUT

	# 根据页面类型执行特定操作
	match page_type:
		PageType.START_SCREEN:
			page.visible = true
			# 确保游戏未暂停
			get_tree().paused = false
			# 添加过渡动画
			_add_page_transition(page, transition_time, transition_type, transition_ease)
		PageType.PAUSE_MENU:
			page.visible = true
			# 如果是从暂停菜单打开的其他页面，返回时保持暂停状态
			get_tree().paused = true
			if page.has_method("show_menu"):
				page.show_menu()
			# 添加过渡动画
			_add_page_transition(page, transition_time, transition_type, transition_ease)
		PageType.AUDIO_SETTINGS:
			page.visible = true
			# 确保在最上层
			page.z_index = 100
			# 移到最前面
			page.get_parent().move_child(page, page.get_parent().get_child_count() - 1)
			# 添加过渡动画
			_add_page_transition(page, transition_time, transition_type, transition_ease)
			# 打印调试信息
			print("Opening audio settings panel")
		PageType.CONSOLE:
			page.visible = true
			# 确保在最上层
			page.z_index = 100
			# 移到最前面
			page.get_parent().move_child(page, page.get_parent().get_child_count() - 1)
			# 添加过渡动画
			_add_page_transition(page, transition_time, transition_type, transition_ease)
			# 如果控制台有输入框，让它获取焦点
			if page.has_method("_ensure_input_focus"):
				page.call_deferred("_ensure_input_focus")
		PageType.ACHIEVEMENTS:
			page.visible = true
			# 确保在最上层
			# 添加过渡动画
			_add_page_transition(page, transition_time, transition_type, transition_ease)
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

	# 页面过渡动画参数
	var transition_time = 0.2
	var transition_type = Tween.TRANS_CUBIC
	var transition_ease = Tween.EASE_IN

	# 根据页面类型执行特定操作
	match page_type:
		PageType.PAUSE_MENU:
			# 添加隐藏过渡动画
			_add_page_hide_transition(page, transition_time, transition_type, transition_ease)
			if page.has_method("hide_menu"):
				page.hide_menu()
		_:
			# 添加隐藏过渡动画
			_add_page_hide_transition(page, transition_time, transition_type, transition_ease)

# 添加页面显示过渡动画
func _add_page_transition(page: Control, duration: float, trans_type: int, ease_type: int):
	# 重置页面状态
	page.modulate.a = 0
	page.scale = Vector2(0.95, 0.95)

	# 创建过渡动画
	var tween = create_tween()
	tween.tween_property(page, "modulate:a", 1.0, duration).set_trans(trans_type).set_ease(ease_type)
	tween.parallel().tween_property(page, "scale", Vector2(1.0, 1.0), duration).set_trans(trans_type).set_ease(ease_type)

# 添加页面隐藏过渡动画
func _add_page_hide_transition(page: Control, duration: float, trans_type: int, ease_type: int):
	# 创建过渡动画
	var tween = create_tween()
	tween.tween_property(page, "modulate:a", 0.0, duration).set_trans(trans_type).set_ease(ease_type)
	tween.parallel().tween_property(page, "scale", Vector2(0.95, 0.95), duration).set_trans(trans_type).set_ease(ease_type)

	# 等待动画完成后隐藏页面
	await tween.finished
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

# UI组件相关方法

# 显示提示消息
func show_toast(message: String, duration: float = 2.0, position: Vector2 = Vector2(-1, -1)):
	# 从池中获取提示组件
	var toast = component_pool.get_component("toast")
	if not toast:
		return

	# 设置消息
	if toast.has_method("set_message"):
		toast.set_message(message)

	# 设置持续时间
	if toast.has_method("set_duration"):
		toast.set_duration(duration)

	# 设置位置
	if position.x >= 0 and position.y >= 0:
		toast.position = position
	else:
		# 默认位置：屏幕底部中心
		var viewport_size = get_viewport().get_visible_rect().size
		toast.position = Vector2(viewport_size.x / 2, viewport_size.y - 100)

	# 添加到场景
	# 先检查节点是否有父节点，如果有，先移除
	if toast.get_parent():
		toast.get_parent().remove_child(toast)

	if main_scene:
		main_scene.get_node("UI").add_child(toast)
	else:
		get_tree().root.add_child(toast)

	# 显示提示
	toast.visible = true
	if toast.has_method("show_component"):
		toast.show_component()

	# 定时返回到池中
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(toast) and not toast.is_queued_for_deletion():
		component_pool.return_component("toast", toast)

# 显示工具提示
func show_tooltip(text: String, position: Vector2, parent: Node = null):
	# 从池中获取工具提示组件
	var tooltip = component_pool.get_component("tooltip")
	if not tooltip:
		return

	# 设置文本
	if tooltip.has_method("set_text"):
		tooltip.set_text(text)

	# 设置位置
	tooltip.position = position

	# 添加到父节点
	# 先检查节点是否有父节点，如果有，先移除
	if tooltip.get_parent():
		tooltip.get_parent().remove_child(tooltip)

	if parent:
		parent.add_child(tooltip)
	elif main_scene:
		main_scene.get_node("UI").add_child(tooltip)
	else:
		get_tree().root.add_child(tooltip)

	# 显示工具提示
	tooltip.visible = true
	if tooltip.has_method("show_component"):
		tooltip.show_component()

	return tooltip

# 隐藏工具提示
func hide_tooltip(tooltip):
	if is_instance_valid(tooltip) and not tooltip.is_queued_for_deletion():
		component_pool.return_component("tooltip", tooltip)

# 显示弹出窗口
func show_popup(title: String, content: String, options: Array = [], callback = null):
	# 从池中获取弹出窗口组件
	var popup = component_pool.get_component("popup")
	if not popup:
		return

	# 设置标题和内容
	if popup.has_method("set_title"):
		popup.set_title(title)
	if popup.has_method("set_content"):
		popup.set_content(content)

	# 设置选项
	if popup.has_method("set_options"):
		popup.set_options(options)

	# 设置回调
	if callback and popup.has_method("set_callback"):
		popup.set_callback(callback)

	# 添加到场景
	# 先检查节点是否有父节点，如果有，先移除
	if popup.get_parent():
		popup.get_parent().remove_child(popup)

	if main_scene:
		main_scene.get_node("UI").add_child(popup)
	else:
		get_tree().root.add_child(popup)

	# 显示弹出窗口
	popup.visible = true
	if popup.has_method("show_component"):
		popup.show_component()

	return popup

# 隐藏弹出窗口
func hide_popup(popup):
	if is_instance_valid(popup) and not popup.is_queued_for_deletion():
		component_pool.return_component("popup", popup)

# 显示加载指示器
func show_loading(text: String = "加载中...", parent: Node = null):
	# 从池中获取加载指示器组件
	var loading = component_pool.get_component("loading")
	if not loading:
		return

	# 设置文本
	if loading.has_method("set_text"):
		loading.set_text(text)

	# 添加到父节点
	# 先检查节点是否有父节点，如果有，先移除
	if loading.get_parent():
		loading.get_parent().remove_child(loading)

	if parent:
		parent.add_child(loading)
	elif main_scene:
		main_scene.get_node("UI").add_child(loading)
	else:
		get_tree().root.add_child(loading)

	# 显示加载指示器
	loading.visible = true
	if loading.has_method("show_component"):
		loading.show_component()

	return loading

# 隐藏加载指示器
func hide_loading(loading):
	if is_instance_valid(loading) and not loading.is_queued_for_deletion():
		component_pool.return_component("loading", loading)

# 显示通知
func show_notification(title: String, message: String, type: String = "info", duration: float = 5.0):
	# 从池中获取通知组件
	var notification = component_pool.get_component("notification")
	if not notification:
		return

	# 设置标题和消息
	if notification.has_method("set_title"):
		notification.set_title(title)
	if notification.has_method("set_message"):
		notification.set_message(message)

	# 设置类型
	if notification.has_method("set_type"):
		notification.set_type(type)

	# 设置持续时间
	if notification.has_method("set_duration"):
		notification.set_duration(duration)

	# 添加到场景
	# 先检查节点是否有父节点，如果有，先移除
	if notification.get_parent():
		notification.get_parent().remove_child(notification)

	if main_scene:
		main_scene.get_node("UI").add_child(notification)
	else:
		get_tree().root.add_child(notification)

	# 显示通知
	notification.visible = true
	if notification.has_method("show_component"):
		notification.show_component()

	# 定时返回到池中
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(notification) and not notification.is_queued_for_deletion():
		component_pool.return_component("notification", notification)
