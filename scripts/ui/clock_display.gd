extends Control

@onready var _day_label: Label = $Panel/Margin/VBox/DayLabel
@onready var _time_label: Label = $Panel/Margin/VBox/TimeLabel
@onready var _period_label: Label = $Panel/Margin/VBox/PeriodLabel
@onready var _weather_label: Label = $Panel/Margin/VBox/WeatherLabel


func _ready() -> void:
	TimeManager.time_updated.connect(_on_time_updated)
	TimeManager.day_advanced.connect(_on_day_advanced)
	WeatherManager.weather_changed.connect(_on_weather_changed)
	_refresh_weather()
	_on_time_updated(TimeManager.day, TimeManager.get_hour(), TimeManager.get_minute())


func _on_time_updated(day: int, hour: int, minute: int) -> void:
	_day_label.text = "Día %d" % day
	_time_label.text = "%02d:%02d" % [hour, minute]
	_period_label.text = TimeManager.get_period_name()


func _on_day_advanced(_day: int) -> void:
	_day_label.text = TimeManager.get_day_string()


func _on_weather_changed(_weather_id: String) -> void:
	_refresh_weather()


func _refresh_weather() -> void:
	_weather_label.text = WeatherManager.get_summary()
