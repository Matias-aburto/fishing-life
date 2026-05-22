extends Node
## Inventario y monedas siempre aquí (no se reparenta al Player; evita perder items al cambiar escena).

const MAIN_SCENE := "res://scenes/main.tscn"
const SHOP_INTERIOR_SCENE := "res://scenes/world/shop_interior.tscn"

var overworld_return_position: Vector2 = Vector2(560, 520)
var _player_state: PlayerState
var _returning_from_shop := false


func ensure_player_state() -> PlayerState:
	if _player_state == null or not is_instance_valid(_player_state):
		_player_state = PlayerState.new()
		add_child(_player_state)
	return _player_state


func get_player_state() -> PlayerState:
	return ensure_player_state()


func has_player_state() -> bool:
	return _player_state != null and is_instance_valid(_player_state)


func enter_shop_interior(player: CharacterBody2D) -> void:
	if player != null:
		overworld_return_position = player.global_position
	_returning_from_shop = false
	get_tree().change_scene_to_file(SHOP_INTERIOR_SCENE)


func return_to_overworld() -> void:
	_returning_from_shop = true
	get_tree().change_scene_to_file(MAIN_SCENE)


func consume_returning_from_shop() -> bool:
	var value := _returning_from_shop
	_returning_from_shop = false
	return value
