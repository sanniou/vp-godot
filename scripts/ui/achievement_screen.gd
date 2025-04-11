extends Control
class_name AchievementScreen

signal back_pressed

# 节点引用
@onready var title_label = $VBoxContainer/MarginContainer/TitleLabel
@onready var progress_label = $VBoxContainer/HBoxContainer/ProgressLabel
@onready var filter_button = $VBoxContainer/HBoxContainer/FilterButton
@onready var achievement_list = $VBoxContainer/ScrollContainer/AchievementList
@onready var back_button = $VBoxContainer/MarginContainer2/BackButton

# 成就管理器引用
var achievement_manager = null
var language_manager = null

# 成就列表项场景
var achievement_list_item_scene = preload("res://scenes/ui/achievement_list_item.tscn")

# 过滤器选项
enum FilterOption {
	ALL,
	UNLOCKED,
	LOCKED
}

var current_filter = FilterOption.ALL

# 初始化
func initialize(achievement_manager_ref, language_manager_ref = null):
	achievement_manager = achievement_manager_ref
	language_manager = language_manager_ref

	# 更新UI文本
	update_ui_text()

	# 更新成就列表
	update_achievement_list()

	# 连接信号
	if not achievement_manager.achievement_unlocked.is_connected(_on_achievement_unlocked):
		achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)

# 更新UI文本
func update_ui_text():
	if language_manager:
		title_label.text = tr("achievements")
		back_button.text = tr("back")

		filter_button.clear()
		filter_button.add_item(tr("all_achievements"), FilterOption.ALL)
		filter_button.add_item(tr("unlocked_achievements"), FilterOption.UNLOCKED)
		filter_button.add_item(tr("locked_achievements"), FilterOption.LOCKED)
		filter_button.selected = current_filter

	# 更新进度标签
	var unlocked_count = achievement_manager.get_unlocked_achievements_count()
	var total_count = achievement_manager.get_total_achievements_count()
	var percent = 0
	if total_count > 0:
		percent = int((float(unlocked_count) / float(total_count)) * 100)

	if language_manager:
		progress_label.text = tr("progress_format_full").replace("%d1", str(unlocked_count)).replace("%d2", str(total_count)).replace("%d3", str(percent))
	else:
		progress_label.text = "Progress: %d/%d (%d%%)" % [unlocked_count, total_count, percent]

# 更新成就列表
func update_achievement_list():
	# 清除现有列表
	for child in achievement_list.get_children():
		achievement_list.remove_child(child)
		child.queue_free()

	# 获取成就列表
	var achievements_to_display = []

	for achievement_id in achievement_manager.achievements:
		var achievement = achievement_manager.achievements[achievement_id]

		match current_filter:
			FilterOption.ALL:
				achievements_to_display.append({"id": achievement_id, "data": achievement})
			FilterOption.UNLOCKED:
				if achievement.unlocked:
					achievements_to_display.append({"id": achievement_id, "data": achievement})
			FilterOption.LOCKED:
				if not achievement.unlocked:
					achievements_to_display.append({"id": achievement_id, "data": achievement})

	# 排序成就：已解锁的在前，按解锁时间倒序；未解锁的在后，按进度倒序
	achievements_to_display.sort_custom(func(a, b):
		var a_data = a.data
		var b_data = b.data
		if a_data.unlocked and not b_data.unlocked:
			return true
		elif not a_data.unlocked and b_data.unlocked:
			return false
		elif a_data.unlocked and b_data.unlocked:
			return a_data.unlock_time > b_data.unlock_time
		else:
			return a_data.progress > b_data.progress
	)

	# 添加成就到列表
	for achievement_info in achievements_to_display:
		var list_item = achievement_list_item_scene.instantiate()
		achievement_list.add_child(list_item)

		# 获取成就数据
		var achievement_id = achievement_info.id
		var achievement_data = achievement_info.data

		# 确保 achievement_data 是字典类型
		if achievement_data is Dictionary:
			# 初始化列表项
			list_item.initialize(achievement_id, achievement_data, achievement_manager, language_manager)
		else:
			# 如果不是字典，尝试转换成字典
			var data_dict = {}

			# 尝试获取常见属性
			if achievement_data.get("name") != null:
				data_dict["name"] = achievement_data.get("name")
			if achievement_data.get("description") != null:
				data_dict["description"] = achievement_data.get("description")
			if achievement_data.get("icon") != null:
				data_dict["icon"] = achievement_data.get("icon")
			if achievement_data.get("unlocked") != null:
				data_dict["unlocked"] = achievement_data.get("unlocked")
			if achievement_data.get("progress") != null:
				data_dict["progress"] = achievement_data.get("progress")
			if achievement_data.get("target") != null:
				data_dict["target"] = achievement_data.get("target")
			if achievement_data.get("unlock_time") != null:
				data_dict["unlock_time"] = achievement_data.get("unlock_time")

			# 初始化列表项
			list_item.initialize(achievement_id, data_dict, achievement_manager, language_manager)

# 过滤按钮选择处理
func _on_filter_button_item_selected(index):
	current_filter = index
	update_achievement_list()

# 返回按钮处理
func _on_back_button_pressed():
	emit_signal("back_pressed")

# 成就解锁处理
func _on_achievement_unlocked(achievement_id):
	update_ui_text()
	update_achievement_list()
