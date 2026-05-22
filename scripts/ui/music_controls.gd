extends Control

@onready var _play_button: Button = $Panel/Margin/HBox/PlayButton
@onready var _volume_slider: HSlider = $Panel/Margin/HBox/VolumeSlider
@onready var _volume_label: Label = $Panel/Margin/HBox/VolumeLabel


func _ready() -> void:
	_disable_keyboard_focus(self)
	_play_button.shortcut = null
	_volume_slider.value = MusicManager.get_volume_percent()
	_update_play_button()
	_update_volume_label(_volume_slider.value)

	MusicManager.playback_changed.connect(func(_p): _update_play_button())
	MusicManager.volume_changed.connect(func(v): _volume_slider.set_value_no_signal(v * 100.0))

	_play_button.gui_input.connect(_on_play_button_gui_input)
	_volume_slider.value_changed.connect(_on_volume_changed)


func _disable_keyboard_focus(node: Node) -> void:
	if node is Control:
		(node as Control).focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_keyboard_focus(child)


func _on_play_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			MusicManager.toggle_playback()
			_update_play_button()
			get_viewport().set_input_as_handled()


func _on_volume_changed(value: float) -> void:
	MusicManager.set_volume_percent(value)
	_update_volume_label(value)


func _update_play_button() -> void:
	_play_button.text = "⏸" if MusicManager.is_playing() else "▶"


func _update_volume_label(percent: float) -> void:
	_volume_label.text = "%d%%" % int(percent)
