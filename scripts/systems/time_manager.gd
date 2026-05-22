extends Node

signal time_updated(day: int, hour: int, minute: int)
signal day_advanced(day: int)

## Un día de juego dura 14 minutos en tiempo real.
const REAL_SECONDS_PER_GAME_DAY := 14.0 * 60.0
const GAME_MINUTES_PER_REAL_SECOND := 1440.0 / REAL_SECONDS_PER_GAME_DAY

const START_HOUR := 6
const START_MINUTE := 0

var day: int = 1
var _game_minutes: float = START_HOUR * 60.0 + START_MINUTE


func _ready() -> void:
	_emit_time()


func _process(delta: float) -> void:
	_game_minutes += delta * GAME_MINUTES_PER_REAL_SECOND
	while _game_minutes >= 1440.0:
		_game_minutes -= 1440.0
		day += 1
		day_advanced.emit(day)
	_emit_time()


func get_hour() -> int:
	return int(_game_minutes) / 60 % 24


func get_minute() -> int:
	return int(_game_minutes) % 60


func get_time_string() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]


func get_day_string() -> String:
	return "Día %d" % day


func get_period_name() -> String:
	var hour := get_hour()
	if hour >= 5 and hour < 8:
		return "Amanecer"
	if hour >= 8 and hour < 12:
		return "Mañana"
	if hour >= 12 and hour < 14:
		return "Mediodía"
	if hour >= 14 and hour < 19:
		return "Tarde"
	if hour >= 19 and hour < 21:
		return "Atardecer"
	if hour >= 21 or hour < 5:
		return "Noche"
	return ""


func _emit_time() -> void:
	time_updated.emit(day, get_hour(), get_minute())
