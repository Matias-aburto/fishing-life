extends Node2D
## Mundo compartido: el servidor instancia jugadores; cada cliente controla el suyo.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

const SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(560, 520),
	Vector2(640, 520),
	Vector2(480, 520),
	Vector2(560, 440),
]

@onready var _players_root: Node2D = $Players
@onready var _player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var _world_camera: Camera2D = $WorldCamera
@onready var fishing_minigame: Control = $UI/FishingMinigame
@onready var hint_label: Label = $UI/HUD/HintLabel
@onready var status_label: Label = $UI/HUD/StatusLabel
@onready var fishing_prompt: Label = $UI/HUD/FishingPrompt
@onready var network_label: Label = $UI/HUD/NetworkLabel
@onready var inventory_hud: Control = $UI/InventoryHud
@onready var coins_hud: Control = $UI/CoinsHud

var local_player: GamePlayer
var player_state: PlayerState
var _fishing: FishingController

var _return_spawn_pending := false


func _ready() -> void:
	_activate_world_camera_fallback()
	_update_network_label()
	if multiplayer.is_server():
		_spawn_server_players()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	call_deferred("_setup_local_player")


func _activate_world_camera_fallback() -> void:
	_world_camera.enabled = true
	_world_camera.make_current()


func _spawn_server_players() -> void:
	_spawn_player(multiplayer.get_unique_id())
	for peer_id in multiplayer.get_peers():
		_spawn_player(peer_id)


func _spawn_player(peer_id: int) -> void:
	var node_name := str(peer_id)
	if _players_root.get_node_or_null(node_name) != null:
		return

	if NetworkManager.is_online():
		if not _player_spawner.spawn_function.is_valid():
			push_error("PlayerSpawner: spawn_function no configurado.")
			return
		var spawned: Node = _player_spawner.spawn(peer_id)
		if spawned == null:
			push_error("MultiplayerSpawner no pudo crear jugador %d" % peer_id)
		return

	var player: GamePlayer = PLAYER_SCENE.instantiate()
	player.name = node_name
	player.position = SPAWN_POSITIONS[(peer_id - 1) % SPAWN_POSITIONS.size()]
	player.set_multiplayer_authority(peer_id)
	_players_root.add_child(player)


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_spawn_player(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	var node := _players_root.get_node_or_null(str(peer_id))
	if node != null:
		node.queue_free()
	if local_player == null or not is_instance_valid(local_player):
		call_deferred("_setup_local_player")


func _setup_local_player() -> void:
	var my_id := multiplayer.get_unique_id()
	if multiplayer.is_server() and _players_root.get_node_or_null(str(my_id)) == null:
		_spawn_player(my_id)

	local_player = _find_local_player()
	var attempts := 0
	while local_player == null and attempts < 60:
		await get_tree().process_frame
		local_player = _find_local_player()
		attempts += 1

	if local_player == null:
		push_error("Jugador local no encontrado (peer %d). Revisa la consola." % my_id)
		_activate_world_camera_fallback()
		return

	player_state = local_player.get_player_state()
	player_state.restore_starting_loadout_if_empty()

	if GameSession.consume_returning_from_shop():
		_return_spawn_pending = true
		local_player.global_position = GameSession.overworld_return_position

	_fishing = local_player.get_node("FishingController") as FishingController
	_fishing.setup(local_player, player_state, fishing_minigame)
	_connect_fishing_signals()

	inventory_hud.bind_player_state(player_state)
	coins_hud.bind_player_state(player_state)

	local_player.activate_camera()
	_setup_camera_limits()
	_world_camera.enabled = false

	if _return_spawn_pending:
		hint_label.text = "Volviste a la orilla del río."
		hint_label.visible = true
		status_label.visible = false
	elif NetworkManager.is_online():
		status_label.text = "Co-op en línea — pesca y explora con tus amigos."
		if multiplayer.is_server():
			status_label.text += " (eres el host)"


func _find_local_player() -> GamePlayer:
	for node in get_tree().get_nodes_in_group("local_player"):
		if node is GamePlayer:
			return node as GamePlayer
	for child in _players_root.get_children():
		if child is GamePlayer and (child as GamePlayer).is_local_player():
			return child as GamePlayer
	return null


func _setup_camera_limits() -> void:
	if local_player == null:
		return
	var camera: Camera2D = local_player.get_node("Camera2D")
	var world_size := Vector2(50 * 32, 38 * 32)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_size.x)
	camera.limit_bottom = int(world_size.y)
	camera.limit_smoothed = true


func _update_network_label() -> void:
	if NetworkManager.solo_mode or not NetworkManager.is_online():
		network_label.text = "Solo"
	elif multiplayer.is_server():
		network_label.text = "Host — puerto %d" % NetworkManager.DEFAULT_PORT
	else:
		network_label.text = "Cliente — ID %d" % multiplayer.get_unique_id()


func _connect_fishing_signals() -> void:
	if _fishing == null:
		return
	if _fishing.hint_changed.is_connected(_on_hint_changed):
		return
	_fishing.hint_changed.connect(_on_hint_changed)
	_fishing.status_changed.connect(_on_status_changed)
	_fishing.fishing_prompt_changed.connect(_on_fishing_prompt_changed)
	_fishing.session_message.connect(_on_session_message)


func _physics_process(_delta: float) -> void:
	if local_player == null or _fishing == null:
		return

	if _fishing.is_idle():
		_update_world_hint()
		if _is_player_free() and _fishing.wants_interact():
			if _try_enter_shop():
				return
			_fishing.process_interact()
		return

	_fishing.process_fishing_tick()
	if _fishing.wants_interact():
		_fishing.process_interact()


func _update_world_hint() -> void:
	if ZoneOverlap.find_shop_door(local_player) != null:
		if NetworkManager.is_online():
			hint_label.text = "Tienda desactivada en multijugador (por ahora)"
		else:
			hint_label.text = "E — Entrar a la tienda"
		hint_label.visible = true
		_reset_hint_style()
		return
	_fishing.update_idle_hint()


func _try_enter_shop() -> bool:
	if NetworkManager.is_online():
		return false
	if ZoneOverlap.find_shop_door(local_player) == null:
		return false
	hint_label.visible = false
	GameSession.enter_shop_interior(local_player)
	return true


func _on_hint_changed(text: String, visible: bool) -> void:
	hint_label.text = text
	hint_label.visible = visible
	if visible:
		_reset_hint_style()


func _on_status_changed(text: String, visible: bool) -> void:
	status_label.text = text
	status_label.visible = visible


func _on_fishing_prompt_changed(text: String, visible: bool, is_bite: bool) -> void:
	if not visible:
		fishing_prompt.visible = false
		return
	fishing_prompt.text = text
	fishing_prompt.visible = true
	if is_bite:
		fishing_prompt.add_theme_font_size_override("font_size", 52)
		fishing_prompt.add_theme_color_override("font_color", Color(1.0, 0.93, 0.25, 1.0))
		fishing_prompt.add_theme_color_override("font_outline_color", Color(0.5, 0.15, 0.05, 1.0))
		fishing_prompt.add_theme_constant_override("outline_size", 10)
	else:
		fishing_prompt.add_theme_font_size_override("font_size", 44)
		fishing_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		fishing_prompt.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14, 1.0))
		fishing_prompt.add_theme_constant_override("outline_size", 8)


func _on_session_message(message: String) -> void:
	status_label.text = message
	status_label.visible = true
	hint_label.visible = false
	_reset_hint_style()


func _is_player_free() -> bool:
	return local_player.is_free()


func _reset_hint_style() -> void:
	hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	hint_label.add_theme_color_override("font_outline_color", Color(0.1, 0.12, 0.16, 1.0))
	hint_label.add_theme_constant_override("outline_size", 4)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and NetworkManager.is_online():
		NetworkManager.go_to_lobby()
		get_viewport().set_input_as_handled()
