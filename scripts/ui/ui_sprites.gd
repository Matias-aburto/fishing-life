class_name UiSprites
extends RefCounted

const COIN_PATH := "res://assets/sprites/ui/coin.png"

static var _coin: Texture2D


static func get_coin_icon() -> Texture2D:
	if _coin != null:
		return _coin
	if not ResourceLoader.exists(COIN_PATH):
		return null
	_coin = load(COIN_PATH) as Texture2D
	return _coin
