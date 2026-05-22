extends Node

const MAIN_THEME_PATH := "res://assets/audio/music/mossy_pixel_path.mp3"

signal playback_changed(is_playing: bool)
signal volume_changed(volume_linear: float)

var _player: AudioStreamPlayer
var _playing := true
var _volume_linear := 0.65


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = &"Master"
	add_child(_player)

	var stream: AudioStream = load(MAIN_THEME_PATH)
	if stream == null:
		push_warning("MusicManager: no se encontró %s" % MAIN_THEME_PATH)
		return

	_player.stream = stream
	_player.finished.connect(_on_track_finished)
	_apply_volume()
	play()


func _on_track_finished() -> void:
	if _playing:
		_player.play()


func play() -> void:
	if _player.stream == null:
		return
	_player.stream_paused = false
	if not _player.playing:
		_player.play()
	_playing = true
	playback_changed.emit(true)


func pause() -> void:
	_player.stream_paused = true
	_playing = false
	playback_changed.emit(false)


func toggle_playback() -> void:
	if _playing:
		pause()
	else:
		play()


func is_playing() -> bool:
	return _playing


func get_volume_linear() -> float:
	return _volume_linear


func get_volume_percent() -> float:
	return _volume_linear * 100.0


func set_volume_linear(volume: float) -> void:
	_volume_linear = clampf(volume, 0.0, 1.0)
	_apply_volume()
	volume_changed.emit(_volume_linear)


func set_volume_percent(percent: float) -> void:
	set_volume_linear(percent / 100.0)


func _apply_volume() -> void:
	if _volume_linear <= 0.001:
		_player.volume_db = -80.0
	else:
		_player.volume_db = linear_to_db(_volume_linear)
