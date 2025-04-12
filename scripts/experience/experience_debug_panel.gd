extends Control

# 经验系统调试面板

# 节点引用
@onready var level_label = $VBoxContainer/StatsContainer/LevelLabel
@onready var exp_label = $VBoxContainer/StatsContainer/ExpLabel
@onready var exp_bar = $VBoxContainer/StatsContainer/ExpBar
@onready var multiplier_label = $VBoxContainer/StatsContainer/MultiplierLabel
@onready var orbs_label = $VBoxContainer/StatsContainer/OrbsLabel
@onready var sources_container = $VBoxContainer/SourcesContainer/SourcesList

# 经验管理器引用
var experience_manager = null
var experience_orb_manager = null

# 初始化
func _ready():
	# 连接按钮信号
	$VBoxContainer/ButtonsContainer/AddExpButton.pressed.connect(_on_add_exp_button_pressed)
	$VBoxContainer/ButtonsContainer/LevelUpButton.pressed.connect(_on_level_up_button_pressed)
	$VBoxContainer/ButtonsContainer/AddMultiplierButton.pressed.connect(_on_add_multiplier_button_pressed)
	$VBoxContainer/ButtonsContainer/SpawnOrbButton.pressed.connect(_on_spawn_orb_button_pressed)
	$VBoxContainer/ButtonsContainer/CollectAllButton.pressed.connect(_on_collect_all_button_pressed)
	$VBoxContainer/ButtonsContainer/ResetButton.pressed.connect(_on_reset_button_pressed)
	
	# 设置初始可见性
	visible = false

# 设置经验管理器
func set_experience_manager(manager):
	experience_manager = manager
	
	if experience_manager:
		# 连接信号
		experience_manager.experience_gained.connect(_on_experience_gained)
		experience_manager.level_up.connect(_on_level_up)
		experience_manager.experience_multiplier_changed.connect(_on_multiplier_changed)
		
		# 更新UI
		update_ui()

# 设置经验球管理器
func set_experience_orb_manager(manager):
	experience_orb_manager = manager
	
	if experience_orb_manager:
		# 连接信号
		experience_orb_manager.orb_spawned.connect(_on_orb_spawned)
		experience_orb_manager.orb_collected.connect(_on_orb_collected)
		experience_orb_manager.orb_merged.connect(_on_orb_merged)
		
		# 更新UI
		update_ui()

# 更新UI
func update_ui():
	if not experience_manager:
		return
	
	# 更新等级和经验
	level_label.text = "等级: %d" % experience_manager.current_level
	exp_label.text = "经验: %d / %d" % [experience_manager.current_experience, experience_manager.experience_to_level]
	
	# 更新经验条
	exp_bar.max_value = experience_manager.experience_to_level
	exp_bar.value = experience_manager.current_experience
	
	# 更新乘数
	multiplier_label.text = "经验乘数: x%.2f" % experience_manager.experience_multiplier
	
	# 更新经验球数量
	if experience_orb_manager:
		orbs_label.text = "活跃经验球: %d" % experience_orb_manager.active_orbs.size()
	
	# 更新经验来源
	update_sources_list()

# 更新经验来源列表
func update_sources_list():
	# 清空列表
	for child in sources_container.get_children():
		child.queue_free()
	
	# 获取经验来源
	var sources = experience_manager.get_experience_sources()
	
	# 添加每个来源
	for source in sources:
		var label = Label.new()
		label.text = "%s: %d" % [source, sources[source]]
		sources_container.add_child(label)

# 切换可见性
func toggle_visibility():
	visible = !visible
	
	# 如果变为可见，更新UI
	if visible:
		update_ui()

# 按钮回调
func _on_add_exp_button_pressed():
	if experience_manager:
		var amount = int($VBoxContainer/ButtonsContainer/ExpAmountEdit.text)
		if amount > 0:
			experience_manager.add_experience(amount, "debug")
			update_ui()

func _on_level_up_button_pressed():
	if experience_manager:
		# 添加足够的经验以升级
		var needed = experience_manager.experience_to_level - experience_manager.current_experience
		if needed > 0:
			experience_manager.add_experience(needed, "debug")
		update_ui()

func _on_add_multiplier_button_pressed():
	if experience_manager:
		var value = float($VBoxContainer/ButtonsContainer/MultiplierEdit.text)
		var duration = float($VBoxContainer/ButtonsContainer/DurationEdit.text)
		if value > 0 and duration > 0:
			experience_manager.add_temporary_multiplier("debug_boost", value, duration)
			update_ui()

func _on_spawn_orb_button_pressed():
	if experience_orb_manager:
		var value = int($VBoxContainer/ButtonsContainer/OrbValueEdit.text)
		if value > 0:
			# 获取玩家位置
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				var player_pos = players[0].global_position
				var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
				experience_orb_manager.spawn_experience_orb(player_pos + offset, value, "debug")
			update_ui()

func _on_collect_all_button_pressed():
	if experience_orb_manager:
		experience_orb_manager.collect_all_orbs()
		update_ui()

func _on_reset_button_pressed():
	if experience_manager:
		experience_manager.reset()
	if experience_orb_manager:
		experience_orb_manager.clear_all_orbs()
	update_ui()

# 信号回调
func _on_experience_gained(amount, total, source):
	update_ui()

func _on_level_up(new_level, overflow_exp):
	update_ui()

func _on_multiplier_changed(new_multiplier):
	update_ui()

func _on_orb_spawned(orb, position, value):
	update_ui()

func _on_orb_collected(orb, value):
	update_ui()

func _on_orb_merged(orb1, orb2, new_orb):
	update_ui()
