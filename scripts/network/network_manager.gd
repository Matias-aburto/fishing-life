extends Node
## Conexión ENet (host / join). Usa IP de Tailscale o port forwarding para jugar online.

const MAIN_SCENE := "res://scenes/main.tscn"
const DEFAULT_PORT := 4242
const MAX_CLIENTS := 3

signal connected_to_server
signal connection_failed
signal server_disconnected
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

var solo_mode := false

const OFFLINE_PEER_ID := 1


func has_peer() -> bool:
	return multiplayer.multiplayer_peer != null


func get_local_peer_id() -> int:
	if solo_mode or not has_peer():
		return OFFLINE_PEER_ID
	return multiplayer.get_unique_id()


func is_server_role() -> bool:
	if not is_online():
		return true
	return multiplayer.is_server()


func is_online() -> bool:
	return has_peer() and not solo_mode


func host_game(port: int = DEFAULT_PORT) -> Error:
	_close_peer()
	solo_mode = false
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_wire_signals()
	return OK


func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	_close_peer()
	solo_mode = false
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address.strip_edges(), port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_wire_signals()
	return OK


func start_solo() -> void:
	_close_peer()
	solo_mode = true
	get_tree().change_scene_to_file(MAIN_SCENE)


func start_hosted_game(port: int = DEFAULT_PORT) -> Error:
	var err := host_game(port)
	if err != OK:
		return err
	get_tree().change_scene_to_file(MAIN_SCENE)
	return OK


func disconnect_game() -> void:
	_close_peer()
	solo_mode = false


func go_to_lobby() -> void:
	disconnect_game()
	get_tree().change_scene_to_file("res://scenes/ui/multiplayer_lobby.tscn")


func _close_peer() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


func _wire_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_peer_connected(peer_id: int) -> void:
	peer_joined.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	peer_left.emit(peer_id)


func _on_connected_to_server() -> void:
	connected_to_server.emit()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_connection_failed() -> void:
	connection_failed.emit()
	disconnect_game()


func _on_server_disconnected() -> void:
	server_disconnected.emit()
	disconnect_game()
	go_to_lobby()
