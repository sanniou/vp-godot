extends Node
class_name AudioSettings

# 音频设置
var master_volume = 1.0
var music_volume = 0.8
var sfx_volume = 0.8

var master_muted = false
var music_muted = false
var sfx_muted = false

# 音频管理器引用
var music_manager: MusicManager = null
var sfx_manager: SoundEffectManager = null

# 设置文件路径
const SETTINGS_FILE = "user://audio_settings.cfg"

# 初始化
func _ready():
	# 加载设置
	load_settings()
	
	# 应用设置
	apply_settings()

# 设置主音量
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	
	# 更新音频总线音量
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	
	# 保存设置
	save_settings()

# 设置音乐音量
func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	
	# 更新音乐管理器音量
	if music_manager:
		music_manager.set_music_volume(music_volume)
	
	# 更新音频总线音量
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	
	# 保存设置
	save_settings()

# 设置音效音量
func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	
	# 更新音效管理器音量
	if sfx_manager:
		sfx_manager.set_sfx_volume(sfx_volume)
	
	# 更新音频总线音量
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	
	# 保存设置
	save_settings()

# 静音/取消静音主音量
func toggle_master_mute():
	master_muted = !master_muted
	
	# 更新音频总线静音状态
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), master_muted)
	
	# 保存设置
	save_settings()

# 静音/取消静音音乐
func toggle_music_mute():
	music_muted = !music_muted
	
	# 更新音乐管理器静音状态
	if music_manager:
		if music_muted:
			music_manager.mute_music()
		else:
			music_manager.unmute_music()
	
	# 更新音频总线静音状态
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), music_muted)
	
	# 保存设置
	save_settings()

# 静音/取消静音音效
func toggle_sfx_mute():
	sfx_muted = !sfx_muted
	
	# 更新音效管理器静音状态
	if sfx_manager:
		if sfx_muted:
			sfx_manager.mute_sfx()
		else:
			sfx_manager.unmute_sfx()
	
	# 更新音频总线静音状态
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), sfx_muted)
	
	# 保存设置
	save_settings()

# 应用设置
func apply_settings():
	# 设置音频总线音量
	var master_bus_index = AudioServer.get_bus_index("Master")
	var music_bus_index = AudioServer.get_bus_index("Music")
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	if master_bus_index != -1:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(master_volume))
		AudioServer.set_bus_mute(master_bus_index, master_muted)
	
	if music_bus_index != -1:
		AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(music_volume))
		AudioServer.set_bus_mute(music_bus_index, music_muted)
	
	if sfx_bus_index != -1:
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume))
		AudioServer.set_bus_mute(sfx_bus_index, sfx_muted)
	
	# 更新音乐管理器设置
	if music_manager:
		music_manager.set_music_volume(music_volume)
		if music_muted:
			music_manager.mute_music()
		else:
			music_manager.unmute_music()
	
	# 更新音效管理器设置
	if sfx_manager:
		sfx_manager.set_sfx_volume(sfx_volume)
		if sfx_muted:
			sfx_manager.mute_sfx()
		else:
			sfx_manager.unmute_sfx()

# 保存设置
func save_settings():
	var config = ConfigFile.new()
	
	# 添加设置
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "master_muted", master_muted)
	config.set_value("audio", "music_muted", music_muted)
	config.set_value("audio", "sfx_muted", sfx_muted)
	
	# 保存设置
	var error = config.save(SETTINGS_FILE)
	if error != OK:
		print("保存音频设置失败: ", error)

# 加载设置
func load_settings():
	var config = ConfigFile.new()
	
	# 加载设置
	var error = config.load(SETTINGS_FILE)
	if error != OK:
		print("加载音频设置失败，使用默认设置")
		return
	
	# 获取设置
	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 0.8)
	sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
	master_muted = config.get_value("audio", "master_muted", false)
	music_muted = config.get_value("audio", "music_muted", false)
	sfx_muted = config.get_value("audio", "sfx_muted", false)
