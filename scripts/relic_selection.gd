extends CanvasLayer

# 最大可选遗物数量
var max_relics = 1

# 已选择的遗物
var selected_relics = []

# 遗物管理器引用
var relic_manager = null

# 语言管理器引用
var language_manager = null

# 主场景引用
var main_scene = "res://scenes/main.tscn"

# 主场景实例引用
var main_scene_instance = null

func _ready():
	# 初始化遗物管理器
	relic_manager = Node.new()
	relic_manager.set_script(load("res://scripts/relics/relic_manager.gd"))
	add_child(relic_manager)

	# 获取语言管理器
	language_manager = get_node("/root/LanguageManager")
	if not language_manager:
		# 如果找不到语言管理器，尝试从自动加载脚本获取
		var autoload = get_node("/root/LanguageAutoload")
		if autoload and autoload.language_manager:
			language_manager = autoload.language_manager
		else:
			# 如果还是找不到，创建一个新的语言管理器
			language_manager = load("res://scripts/language/language_manager.gd").new()
			language_manager.name = "LanguageManager"
			get_tree().root.call_deferred("add_child", language_manager)

	# 连接语言变更信号
	language_manager.language_changed.connect(_on_language_changed)

	# 连接开始按钮信号
	$Control/StartButton.pressed.connect(_on_start_button_pressed)

	# 初始化开始按钮状态
	$Control/StartButton.disabled = true

	# 生成遗物选择网格
	generate_relic_grid()

	# 更新已选择遗物显示
	update_selected_relics_display()

	# 更新UI文本
	update_ui_text()

# 生成遗物选择网格
func generate_relic_grid():
	var grid = $Control/RelicGrid

	# 清空现有内容
	for child in grid.get_children():
		child.queue_free()

	# 获取所有可用遗物的信息
	# 暂时使用硬编码的遗物信息代替
	var all_relics_info = [
		{"id": "phoenix_feather", "name": "凤凰之羽", "description": "死亡时自动复活一次，恢复50%生命值", "icon": "🔥", "rarity": "rare"},
		{"id": "wisdom_crystal", "name": "智慧水晶", "description": "游戏开始时自动获得一级", "icon": "💎", "rarity": "uncommon"},
		{"id": "magnetic_amulet", "name": "磁力护符", "description": "经验球吸取范围增加50%，经验值增加20%", "icon": "🧲", "rarity": "common"},
		{"id": "heart_amulet", "name": "生命护符", "description": "最大生命值增加25", "icon": "❤️", "rarity": "common"},
		{"id": "lucky_clover", "name": "幸运四叶草", "description": "升级时获得4个选项而不是3个", "icon": "🍀", "rarity": "uncommon"},
		{"id": "shadow_cloak", "name": "暗影披风", "description": "10%几率闪避敌人攻击", "icon": "👻", "rarity": "uncommon"},
		{"id": "upgrade_enhancer", "name": "升级增强器", "description": "增加升级选项数量(+1)，增加重新随机次数(+1)，提高选项数值(+20%)", "icon": "🔮", "rarity": "rare"},

		# 新遗物
		{"id": "time_warper", "name": "时间扭曲器", "description": "减缓敌人移动速度(25%)，增加玩家攻击速度(15%)", "icon": "⏱️", "rarity": "rare"},
		{"id": "elemental_resonance", "name": "元素共鸣", "description": "每种不同类型的武器增加8%伤害(最大40%)", "icon": "🔄", "rarity": "epic"},
		{"id": "experience_catalyst", "name": "经验催化剂", "description": "击杀敌人有25%几率掉落额外经验球", "icon": "✨", "rarity": "uncommon"},
		{"id": "critical_amulet", "name": "暴击护符", "description": "增加15%暴击几率，暴击造成双倍伤害", "icon": "🔮", "rarity": "rare"},
		{"id": "life_steal", "name": "生命窃取", "description": "造成伤害时恢复伤害值5%的生命值", "icon": "💉", "rarity": "uncommon"}
	]

	# 为每个遗物创建一个按钮
	for relic_info in all_relics_info:
		# 创建遗物按钮
		var button = Button.new()
		button.custom_minimum_size = Vector2(200, 120)
		button.toggle_mode = true

		# 设置按钮文本
		var text = relic_info.icon + " " + relic_info.name + "\n" + relic_info.description
		button.text = text
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER

		# 设置按钮标识
		button.set_meta("relic_id", relic_info.id)

		# 连接按钮信号
		button.pressed.connect(_on_relic_button_pressed.bind(button))

		# 添加到网格
		grid.add_child(button)

# 更新已选择遗物显示
func update_selected_relics_display():
	var label = $Control/SelectedRelicInfo/VBoxContainer/RelicList

	if selected_relics.size() == 0:
		label.text = language_manager.get_translation("none", "无")
		$Control/StartButton.disabled = true
		return

	var text = ""
	var equipped_relics_info = []

	# 如果有遗物管理器，获取已装备遗物信息
	for relic_id in selected_relics:
		# 使用多语言系统获取遗物信息
		var relic_info = {
			"id": relic_id,
			"name": language_manager.get_translation("relic_" + relic_id + "_name", format_relic_name(relic_id)),
			"icon": "🔮"
		}

		# 根据ID设置图标
		match relic_id:
			"phoenix_feather":
				relic_info.icon = "🔥"
			"wisdom_crystal":
				relic_info.icon = "💎"
			"magnetic_amulet":
				relic_info.icon = "🧲"
			"heart_amulet":
				relic_info.icon = "❤️"
			"lucky_clover":
				relic_info.icon = "🍀"
			"shadow_cloak":
				relic_info.icon = "👻"
			"upgrade_enhancer":
				relic_info.icon = "🔮"
			"time_warper":
				relic_info.icon = "⏱️"
			"elemental_resonance":
				relic_info.icon = "🔄"
			"experience_catalyst":
				relic_info.icon = "✨"
			"critical_amulet":
				relic_info.icon = "🔮"
			"life_steal":
				relic_info.icon = "💉"

		equipped_relics_info.append(relic_info)

	for i in range(equipped_relics_info.size()):
		var relic_info = equipped_relics_info[i]
		text += relic_info.icon + " " + relic_info.name
		if i < equipped_relics_info.size() - 1:
			text += "\n"

	# 设置文本并强制更新
	label.text = text
	print("Selected relic: " + text)

	# 更新开始按钮状态
	$Control/StartButton.disabled = false

# 遗物按钮点击处理
func _on_relic_button_pressed(button):
	var relic_id = button.get_meta("relic_id")

	# 清除所有按钮的选中状态
	for child in $Control/RelicGrid.get_children():
		if child != button and child is Button:
			child.button_pressed = false

	if button.button_pressed:
		# 添加到已选择列表
		selected_relics = [relic_id]
	else:
		# 从已选择列表中移除
		selected_relics.clear()

	# 更新显示
	update_selected_relics_display()

# 开始按钮点击处理
func _on_start_button_pressed():
	# 检查是否选择了遗物
	if selected_relics.size() == 0:
		# print("No relic selected!")
		return

	# 打印调试信息
	# print("Start button pressed, selected relics: ", selected_relics)

	# 保存选择的遗物到全局配置
	save_selected_relics()

	# 如果有主场景实例，直接使用
	if main_scene_instance:
		# print("Using existing main scene instance")

		# 隐藏遗物选择界面
		queue_free()

		# 隐藏开始界面，显示游戏UI
		main_scene_instance.start_screen.visible = false
		main_scene_instance.game_ui.visible = true

		# 开始游戏
		main_scene_instance.start_game()

		# 恢复游戏
		get_tree().paused = false
		# print("Game started successfully!")
	else:
		# 如果没有主场景实例，切换到主场景
		# print("No main scene instance, changing scene")
		get_tree().change_scene_to_file(main_scene)

		# 等待一帧确保场景切换完成
		await get_tree().process_frame

		# 获取新的主场景
		var main_node = get_tree().current_scene
		if main_node:
			# 隐藏开始界面，显示游戏UI并开始游戏
			main_node.start_screen.visible = false
			main_node.game_ui.visible = true
			main_node.start_game()
			main_node.get_tree().paused = false
			# print("Game started successfully!")

# 保存选择的遗物
func save_selected_relics():
	# 创建一个全局单例来存储选择的遗物
	var global = Node.new()
	global.name = "RelicGlobal"
	global.set_script(load("res://scripts/relic_global.gd"))
	Engine.get_main_loop().root.add_child(global)

	# 设置选择的遗物
	global.selected_relics = selected_relics.duplicate()

# 更新UI文本
func update_ui_text():
	$Control/TitleLabel.text = language_manager.get_translation("relic_selection")
	$Control/SelectedRelicInfo/VBoxContainer/SelectedLabel.text = language_manager.get_translation("selected_relics")
	$Control/StartButton.text = language_manager.get_translation("confirm")
	$Control/DescriptionLabel.text = language_manager.get_translation("max_relics").replace("{0}", str(max_relics))

	# 更新遗物选择显示
	update_selected_relics_display()

# 格式化遗物名称（将下划线替换为空格并将首字母大写）
func format_relic_name(relic_id: String) -> String:
	# 将下划线替换为空格
	var formatted_name = relic_id.replace("_", " ")

	# 将首字母大写
	if formatted_name.length() > 0:
		formatted_name = formatted_name.substr(0, 1).to_upper() + formatted_name.substr(1)

	return formatted_name

# 处理语言变更
func _on_language_changed(new_language):
	update_ui_text()
