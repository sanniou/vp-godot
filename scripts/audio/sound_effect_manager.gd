extends Node
class_name SoundEffectManager

# 音效类型枚举
enum SfxType {
	PLAYER_ATTACK,
	PLAYER_HURT,
	PLAYER_DEATH,
	ENEMY_HURT,
	ENEMY_DEATH,
	BOSS_ATTACK,
	BOSS_HURT,
	BOSS_DEATH,
	WEAPON_SHOOT,
	WEAPON_HIT,
	UI_CLICK,
	UI_HOVER,
	LEVEL_UP,
	PICKUP
}

# 音效播放器池
var sfx_players = []
var sfx_player_index = 0
const MAX_SFX_PLAYERS = 16

# 音效路径
var sfx_paths = {
	SfxType.PLAYER_ATTACK: [
		"res://assets/sfx/player/attack.wav"
	],
	SfxType.PLAYER_HURT: [
		"res://assets/sfx/player/hurt.wav"
	],
	SfxType.PLAYER_DEATH: [
		"res://assets/sfx/player/death.wav"
	],
	SfxType.ENEMY_HURT: [
		"res://assets/sfx/enemies/hurt.wav"
	],
	SfxType.ENEMY_DEATH: [
		"res://assets/sfx/enemies/death.wav"
	],
	SfxType.BOSS_ATTACK: [
		"res://assets/sfx/enemies/boss_attack.wav"
	],
	SfxType.BOSS_HURT: [
		"res://assets/sfx/enemies/boss_hurt.wav"
	],
	SfxType.BOSS_DEATH: [
		"res://assets/sfx/enemies/boss_death.wav"
	],
	SfxType.WEAPON_SHOOT: [
		"res://assets/sfx/weapons/shoot.wav"
	],
	SfxType.WEAPON_HIT: [
		"res://assets/sfx/weapons/hit.wav"
	],
	SfxType.UI_CLICK: [
		"res://assets/sfx/ui/click.wav"
	],
	SfxType.UI_HOVER: [
		"res://assets/sfx/ui/hover.wav"
	],
	SfxType.LEVEL_UP: [
		"res://assets/sfx/player/level_up.wav"
	],
	SfxType.PICKUP: [
		"res://assets/sfx/player/pickup.wav"
	]
}

# 音量设置
var sfx_volume = 0.8
var sfx_muted = false

# 初始化
func _ready():
	# 创建音效播放器池
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = linear_to_db(sfx_volume)
		add_child(player)
		sfx_players.append(player)
		
		# 连接播放完成信号
		player.finished.connect(_on_sfx_finished.bind(player))

# 播放音效
func play_sfx(type: int, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	# 如果静音，不播放音效
	if sfx_muted:
		return null
	
	# 获取音效路径
	var paths = sfx_paths.get(type, [])
	if paths.is_empty():
		return null
	
	# 随机选择一个音效
	var sfx_path = paths[randi() % paths.size()]
	
	# 加载音效
	var sfx = load(sfx_path)
	if not sfx:
		print("无法加载音效: ", sfx_path)
		return null
	
	# 获取下一个可用的音效播放器
	var player = _get_next_player()
	if not player:
		return null
	
	# 设置音效
	player.stream = sfx
	
	# 设置音量和音调
	player.volume_db = linear_to_db(sfx_volume * volume_scale)
	player.pitch_scale = pitch_scale
	
	# 播放音效
	player.play()
	
	return player

# 获取下一个可用的音效播放器
func _get_next_player() -> AudioStreamPlayer:
	# 查找未播放的播放器
	for i in range(MAX_SFX_PLAYERS):
		var index = (sfx_player_index + i) % MAX_SFX_PLAYERS
		var player = sfx_players[index]
		
		if not player.playing:
			sfx_player_index = (index + 1) % MAX_SFX_PLAYERS
			return player
	
	# 如果所有播放器都在播放，使用最旧的播放器
	var player = sfx_players[sfx_player_index]
	sfx_player_index = (sfx_player_index + 1) % MAX_SFX_PLAYERS
	player.stop()
	return player

# 设置音效音量
func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	
	# 更新所有播放器的音量
	for player in sfx_players:
		if player.playing and not sfx_muted:
			player.volume_db = linear_to_db(sfx_volume)

# 获取音效音量
func get_sfx_volume() -> float:
	return sfx_volume

# 静音音效
func mute_sfx():
	sfx_muted = true
	
	# 停止所有正在播放的音效
	for player in sfx_players:
		if player.playing:
			player.stop()

# 取消静音音效
func unmute_sfx():
	sfx_muted = false

# 音效播放完成回调
func _on_sfx_finished(player: AudioStreamPlayer):
	# 可以在这里添加音效播放完成后的逻辑
	pass
