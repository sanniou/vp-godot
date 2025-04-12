extends PanelContainer
class_name AchievementListItem

# 成就引用
var achievement_id: String
var achievement: Dictionary
var achievement_manager = null
var language_manager = null

# 节点引用
@onready var icon_label = $HBoxContainer/IconLabel
@onready var title_label = $HBoxContainer/VBoxContainer/TitleLabel
@onready var description_label = $HBoxContainer/VBoxContainer/DescriptionLabel
@onready var progress_bar = $HBoxContainer/VBoxContainer/ProgressBar
@onready var progress_label = $HBoxContainer/VBoxContainer/ProgressBar/ProgressLabel
@onready var unlock_time_label = $HBoxContainer/VBoxContainer/UnlockTimeLabel

# 初始化成就项
func initialize(p_achievement_id: String, p_achievement: Dictionary, p_achievement_manager, p_language_manager = null):
	achievement_id = p_achievement_id
	achievement = p_achievement
	achievement_manager = p_achievement_manager
	language_manager = p_language_manager

	update_display()

# 更新显示
func update_display():
	if not achievement:
		return

	# 显示成就信息
	icon_label.text = achievement.icon

	# 获取成就的翻译名称和描述
	var achievement_name = achievement.name
	var achievement_desc = achievement.description

	if language_manager and achievement_id and not achievement_id.is_empty():
		# 尝试获取翻译
		var translated_name = language_manager.get_translation("achievement_" + achievement_id + "_name", "")
		var translated_desc = language_manager.get_translation("achievement_" + achievement_id + "_desc", "")

		# 打印调试信息
		print("Achievement list item looking for translation: achievement_" + achievement_id + "_name")

		if not translated_name.is_empty():
			achievement_name = translated_name
		else:
			# 如果没有翻译，使用标题
			if "title" in achievement:
				achievement_name = achievement.title

		if not translated_desc.is_empty():
			achievement_desc = translated_desc
		else:
			# 如果没有翻译，使用原始描述
			if "description" in achievement:
				achievement_desc = achievement.description

	title_label.text = achievement_name
	description_label.text = achievement_desc

	if achievement.unlocked:
		# 已解锁：显示解锁时间，隐藏进度条
		progress_bar.visible = false
		unlock_time_label.visible = true

		# 格式化时间
		var unlock_time = achievement.unlock_time
		var datetime = Time.get_datetime_dict_from_unix_time(unlock_time)
		var formatted_time = "%04d-%02d-%02d %02d:%02d" % [datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute]

		# 获取翻译文本
		var unlocked_on_text = "Unlocked on"
		if language_manager:
			unlocked_on_text = language_manager.get_translation("unlocked_on", "Unlocked on")

		unlock_time_label.text = unlocked_on_text + ": " + formatted_time

		# 设置已解锁样式
		add_theme_stylebox_override("panel", get_theme_stylebox("panel_unlocked", "AchievementItem"))
	else:
		# 未解锁：显示进度条，隐藏解锁时间
		progress_bar.visible = true
		progress_bar.value = achievement.progress * 100
		progress_label.text = str(int(achievement.progress * 100)) + "%"
		unlock_time_label.visible = false

		# 设置未解锁样式
		add_theme_stylebox_override("panel", get_theme_stylebox("panel_locked", "AchievementItem"))
