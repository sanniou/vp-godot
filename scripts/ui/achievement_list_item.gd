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
	title_label.text = achievement.name
	description_label.text = achievement.description

	if achievement.unlocked:
		# 已解锁：显示解锁时间，隐藏进度条
		progress_bar.visible = false
		unlock_time_label.visible = true

		# 格式化时间
		var unlock_time = achievement.unlock_time
		var datetime = Time.get_datetime_dict_from_unix_time(unlock_time)
		var formatted_time = "%04d-%02d-%02d %02d:%02d" % [datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute]
		unlock_time_label.text = tr("unlocked_on") + ": " + formatted_time

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
