extends Node

@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(sfx_player)
	add_child(music_player)
	music_player.volume_db = -10.0

func play_sfx(stream: AudioStream) -> void:
	if not SaveManager.sfx_enabled or stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()

func play_music(stream: AudioStream) -> void:
	if not SaveManager.music_enabled or stream == null:
		return
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func set_sfx_enabled(val: bool) -> void:
	SaveManager.sfx_enabled = val
	SaveManager.save_data()

func set_music_enabled(val: bool) -> void:
	SaveManager.music_enabled = val
	if not val:
		stop_music()
	SaveManager.save_data()
