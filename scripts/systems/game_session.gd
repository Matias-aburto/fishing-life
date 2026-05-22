extends Node
## Transiciones de escena y estado persistente entre tienda y mundo.

const MAIN_SCENE := "res://scenes/main.tscn"
const SHOP_INTERIOR_SCENE := "res://scenes/world/shop_interior.tscn"

var overworld_return_position: Vector2 = Vector2(560, 520)
var _returning_from_shop := false


func get_local_player_state() -> PlayerState:
	var local := _find_local_player()
	if local != null:
		return local.get_player_state()
	return null


func ensure_player_state() -> PlayerState:
	var state := get_local_player_state()
	if state != null:
		return state
	push_warning("GameSession.ensure_player_state: no hay jugador local.")
	return null


func get_player_state() -> PlayerState:
	return ensure_player_state()


func has_player_state() -> bool:
	return get_local_player_state() != null


func enter_shop_interior(player: CharacterBody2D) -> void:
	if NetworkManager.is_online():
		return
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


func _find_local_player() -> GamePlayer:
	for node in get_tree().get_nodes_in_group("local_player"):
		if node is GamePlayer:
			return node as GamePlayer
	return null
