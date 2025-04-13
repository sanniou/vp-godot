extends Node
class_name MusicManager

# 音乐类型枚举
enum MusicType {
	NONE,
	MENU,
	GAMEPLAY,
	BOSS,
	GAME_OVER
}

# 音乐淡入淡出时间（秒）
const FADE_DURATION = 1.0

# 音乐播放器
var music_players = {}
var current_music_type = MusicType.NONE
var current_music_player = null

# 音乐路径
var music_paths = {
	MusicType.MENU: [
		"res://assets/music/menu/title_theme.ogg"
	],
	MusicType.GAMEPLAY: [
		"res://assets/music/gameplay/gameplay_1.ogg",
		"res://assets/music/gameplay/gameplay_2.ogg",
		"res://assets/music/gameplay/gameplay_3.ogg"
	],
	MusicType.BOSS: [
		"res://assets/music/boss/boss_battle.ogg"
	],
	MusicType.GAME_OVER: [
		"res://assets/music/gameplay/game_over.ogg"
	]
}

# 音量设置
var music_volume = 0.8
var music_muted = false

# 初始化
func _ready():
	# 创建音乐播放器
	for type in music_paths.keys():
		var player = AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = linear_to_db(0.0)  # 初始音量为0
		add_child(player)
		music_players[type] = player
	
	# 创建音频总线
	_setup_audio_buses()

# 设置音频总线
func _setup_audio_buses():
	# 检查是否已经存在音频总线
	var audio_bus_count = AudioServer.bus_count
	var music_bus_index = AudioServer.get_bus_index("Music")
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# 如果不存在，创建音频总线
	if music_bus_index == -1:
		AudioServer.add_bus()
		music_bus_index = audio_bus_count
		AudioServer.set_bus_name(music_bus_index, "Music")
		
		# 添加效果器
		var reverb = AudioEffectReverb.new()
		reverb.wet = 0.1
		AudioServer.add_bus_effect(music_bus_index, reverb)
	
	if sfx_bus_index == -1:
		AudioServer.add_bus()
		sfx_bus_index = audio_bus_count + 1
		AudioServer.set_bus_name(sfx_bus_index, "SFX")

# 播放指定类型的音乐
func play_music(type: int, fade_in: bool = true):
	if type == current_music_type and current_music_player and current_music_player.playing:
		return
	
	# 停止当前音乐
	if current_music_player:
		if fade_in:
			_fade_out(current_music_player)
		else:
			current_music_player.stop()
	
	# 获取新的音乐播放器
	var player = music_players.get(type)
	if not player:
		return
	
	# 获取音乐路径
	var paths = music_paths.get(type, [])
	if paths.is_empty():
		return
	
	# 随机选择一首音乐
	var music_path = paths[randi() % paths.size()]
	
	# 加载音乐
	var music = load(music_path)
	if not music:
		print("无法加载音乐: ", music_path)
		return
	
	# 设置音乐
	player.stream = music
	
	# 设置音量
	if music_muted:
		player.volume_db = linear_to_db(0.0)
	else:
		if fade_in:
			player.volume_db = linear_to_db(0.0)
			_fade_in(player)
		else:
			player.volume_db = linear_to_db(music_volume)
	
	# 播放音乐
	player.play()
	
	# 更新当前音乐
	current_music_type = type
	current_music_player = player
	
	print("播放音乐: ", music_path)

# 停止音乐
func stop_music(fade_out: bool = true):
	if current_music_player:
		if fade_out:
			_fade_out(current_music_player)
		else:
			current_music_player.stop()
		
		current_music_type = MusicType.NONE
		current_music_player = null

# 暂停音乐
func pause_music():
	if current_music_player:
		current_music_player.stream_paused = true

# 恢复音乐
func resume_music():
	if current_music_player:
		current_music_player.stream_paused = false

# 设置音乐音量
func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	
	if current_music_player and not music_muted:
		current_music_player.volume_db = linear_to_db(music_volume)

# 获取音乐音量
func get_music_volume() -> float:
	return music_volume

# 静音音乐
func mute_music():
	music_muted = true
	
	if current_music_player:
		_fade_out(current_music_player)

# 取消静音音乐
func unmute_music():
	music_muted = false
	
	if current_music_player:
		_fade_in(current_music_player)

# 淡入音乐
func _fade_in(player: AudioStreamPlayer):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", linear_to_db(music_volume), FADE_DURATION)

# 淡出音乐
func _fade_out(player: AudioStreamPlayer):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", linear_to_db(0.0), FADE_DURATION)
	tween.tween_callback(player.stop)
