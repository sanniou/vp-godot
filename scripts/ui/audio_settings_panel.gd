extends Control

# 音频设置面板

# 定义信号
signal settings_closed

# 页面类型
const PAGE_TYPE = UIManager.PageType.AUDIO_SETTINGS

# UI元素
@onready var master_volume_slider = $VBoxContainer/MasterVolumeContainer/MasterVolumeSlider
@onready var music_volume_slider = $VBoxContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var sfx_volume_slider = $VBoxContainer/SfxVolumeContainer/SfxVolumeSlider

@onready var master_mute_button = $VBoxContainer/MasterVolumeContainer/MasterMuteButton
@onready var music_mute_button = $VBoxContainer/MusicVolumeContainer/MusicMuteButton
@onready var sfx_mute_button = $VBoxContainer/SfxVolumeContainer/SfxMuteButton

@onready var test_sound_button = $VBoxContainer/TestSoundButton
@onready var close_button = $VBoxContainer/CloseButton

# 音频管理器引用
var audio_manager = null

# 默认设置
var master_volume = 0.8
var music_volume = 0.8
var sfx_volume = 0.8
var master_muted = false
var music_muted = false
var sfx_muted = false

# 初始化
func _ready():
	# 设置进程模式，确保在暂停时仍然可以交互
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 设置为最高层级
	z_index = 100

	# 设置鼠标过滤模式，确保可以接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 确保所有子控件都可以接收鼠标事件
	for child in get_children_recursive(self):
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_STOP

	# 添加ESC键处理
	set_process_input(true)

	# 获取音频管理器
	audio_manager = get_node_or_null("/root/AudioManager")

	# 连接信号
	if master_volume_slider:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)

	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)

	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)

	if master_mute_button:
		master_mute_button.pressed.connect(_on_master_mute_pressed)

	if music_mute_button:
		music_mute_button.pressed.connect(_on_music_mute_pressed)

	if sfx_mute_button:
		sfx_mute_button.pressed.connect(_on_sfx_mute_pressed)

	if test_sound_button:
		test_sound_button.pressed.connect(_on_test_sound_button_pressed)

	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

	# 更新UI
	update_ui()

# 更新UI
func update_ui():
	# 更新音量滑块
	if master_volume_slider:
		master_volume_slider.value = master_volume

	if music_volume_slider:
		music_volume_slider.value = music_volume

	if sfx_volume_slider:
		sfx_volume_slider.value = sfx_volume

	# 更新静音按钮
	if master_mute_button:
		master_mute_button.button_pressed = master_muted
		update_mute_button_icon(master_mute_button, master_muted)

	if music_mute_button:
		music_mute_button.button_pressed = music_muted
		update_mute_button_icon(music_mute_button, music_muted)

	if sfx_mute_button:
		sfx_mute_button.button_pressed = sfx_muted
		update_mute_button_icon(sfx_mute_button, sfx_muted)

# 更新静音按钮图标
func update_mute_button_icon(button, muted):
	if muted:
		button.text = "🔇"
	else:
		button.text = "🔊"

# 主音量改变回调
func _on_master_volume_changed(value):
	master_volume = value
	if audio_manager:
		audio_manager.set_master_volume(value)

		# 播放测试音效
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

# 音乐音量改变回调
func _on_music_volume_changed(value):
	music_volume = value
	if audio_manager:
		audio_manager.set_music_volume(value)

# 音效音量改变回调
func _on_sfx_volume_changed(value):
	sfx_volume = value
	if audio_manager:
		audio_manager.set_sfx_volume(value)

		# 播放测试音效
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

# 主音量静音按钮回调
func _on_master_mute_pressed():
	master_muted = !master_muted
	if audio_manager:
		audio_manager.toggle_master_mute()
	update_mute_button_icon(master_mute_button, master_muted)

# 音乐静音按钮回调
func _on_music_mute_pressed():
	music_muted = !music_muted
	if audio_manager:
		audio_manager.toggle_music_mute()
	update_mute_button_icon(music_mute_button, music_muted)

# 音效静音按钮回调
func _on_sfx_mute_pressed():
	sfx_muted = !sfx_muted
	if audio_manager:
		audio_manager.toggle_sfx_mute()
	update_mute_button_icon(sfx_mute_button, sfx_muted)

	# 如果取消静音，播放测试音效
	if !sfx_muted and audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

# 测试音效按钮回调
func _on_test_sound_button_pressed():
	if audio_manager:
		audio_manager.play_sfx(AudioManager.SfxType.UI_CLICK)

# 递归获取所有子节点
func get_children_recursive(node):
	var children = []
	for child in node.get_children():
		children.append(child)
		children.append_array(get_children_recursive(child))
	return children

# 处理输入
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# 关闭设置面板
		_on_close_button_pressed()
		# 标记事件已处理
		get_viewport().set_input_as_handled()

# 关闭按钮回调
func _on_close_button_pressed():
	# 隐藏面板
	hide()

	# 发出关闭信号
	settings_closed.emit()

	# 使用UIManager返回上一页
	UIManager.go_back()
