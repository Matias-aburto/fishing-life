extends Control

@onready var _coin_icon: TextureRect = $Panel/Margin/HBox/CoinIcon
@onready var _coin_emoji: Label = $Panel/Margin/HBox/CoinEmoji
@onready var _coins_label: Label = $Panel/Margin/HBox/CoinsLabel

var _player_state: PlayerState


func _ready() -> void:
	var texture := UiSprites.get_coin_icon()
	if texture != null:
		_coin_icon.texture = texture
		_coin_icon.visible = true
		_coin_emoji.visible = false
	else:
		_coin_icon.visible = false
		_coin_emoji.visible = true


func bind_player_state(state: PlayerState) -> void:
	if _player_state != null and _player_state.money_changed.is_connected(_refresh):
		_player_state.money_changed.disconnect(_refresh)
	_player_state = state
	if _player_state == null:
		return
	_player_state.money_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if _player_state == null:
		return
	_coins_label.text = str(_player_state.coins)
