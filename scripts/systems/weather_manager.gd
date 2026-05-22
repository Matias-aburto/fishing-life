extends Node

signal weather_changed(weather_id: String)

enum Weather { SUNNY }

var current: Weather = Weather.SUNNY


func _ready() -> void:
	weather_changed.emit(get_weather_id())


func get_weather_id() -> String:
	match current:
		Weather.SUNNY:
			return "sunny"
		_:
			return "sunny"


func get_display_name() -> String:
	match current:
		Weather.SUNNY:
			return "Soleado"
		_:
			return "Despejado"


func get_icon() -> String:
	match current:
		Weather.SUNNY:
			return "☀"
		_:
			return "☀"


func get_summary() -> String:
	return "%s %s" % [get_icon(), get_display_name()]
