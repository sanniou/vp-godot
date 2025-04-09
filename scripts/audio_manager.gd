extends Node

# Sound effect players
var sfx_players = []
var num_sfx_players = 8
var current_sfx_player = 0

# Music player
var music_player = null

# Sound volumes
var sfx_volume = 0.8
var music_volume = 0.5

# Sound effects
var sounds = {
	"player_hit": preload("res://assets/audio/player_hit.wav"),
	"enemy_hit": preload("res://assets/audio/enemy_hit.wav"),
	"enemy_death": preload("res://assets/audio/enemy_death.wav"),
	"level_up": preload("res://assets/audio/level_up.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"shoot": preload("res://assets/audio/shoot.wav"),
	"game_over": preload("res://assets/audio/game_over.wav")
}

# Music tracks
var music = {
	"gameplay": preload("res://assets/audio/gameplay_music.ogg")
}

func _ready():
	# Create sound effect players
	for i in range(num_sfx_players):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = linear_to_db(sfx_volume)
		add_child(player)
		sfx_players.append(player)
	
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = linear_to_db(music_volume)
	add_child(music_player)

# Play a sound effect
func play_sound(sound_name, volume_scale = 1.0):
	if sounds.has(sound_name):
		var player = sfx_players[current_sfx_player]
		player.stream = sounds[sound_name]
		player.volume_db = linear_to_db(sfx_volume * volume_scale)
		player.play()
		
		# Move to next player
		current_sfx_player = (current_sfx_player + 1) % num_sfx_players
	else:
		print("Sound not found: ", sound_name)

# Play music
func play_music(music_name, fade_time = 1.0):
	if music.has(music_name):
		# Stop current music with fade out
		if music_player.playing:
			var tween = create_tween()
			tween.tween_property(music_player, "volume_db", -80, fade_time)
			await tween.finished
		
		# Start new music with fade in
		music_player.stream = music[music_name]
		music_player.volume_db = -80
		music_player.play()
		
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_time)
	else:
		print("Music not found: ", music_name)

# Stop music
func stop_music(fade_time = 1.0):
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_time)
		await tween.finished
		music_player.stop()

# Set SFX volume
func set_sfx_volume(volume):
	sfx_volume = clamp(volume, 0, 1)
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume)

# Set music volume
func set_music_volume(volume):
	music_volume = clamp(volume, 0, 1)
	if music_player.playing:
		music_player.volume_db = linear_to_db(music_volume)
