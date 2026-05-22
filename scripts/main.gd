extends Node2D
## Mundo + UI local. La lógica de jugador vive en GamePlayer / FishingController / PlayerState.

@onready var local_player: CharacterBody2D = $Player
@onready var _fishing: FishingController = $Player/FishingController

var player_state: PlayerState
@onready var camera: Camera2D = $Player/Camera2D
@onready var fishing_minigame: Control = $UI/FishingMinigame
@onready var hint_label: Label = $UI/HUD/HintLabel
@onready var status_label: Label = $UI/HUD/StatusLabel
@onready var fishing_prompt: Label = $UI/HUD/FishingPrompt
@onready var inventory_hud: Control = $UI/InventoryHud
@onready var coins_hud: Control = $UI/CoinsHud

var _return_spawn_pending := false


func _ready() -> void:
	local_player.add_to_group("local_player")

	player_state = GameSession.ensure_player_state()
	player_state.restore_starting_loadout_if_empty()

	if GameSession.consume_returning_from_shop():
		_return_spawn_pending = true
		local_player.global_position = GameSession.overworld_return_position

	_fishing.setup(local_player, player_state, fishing_minigame)
	_connect_fishing_signals()

	inventory_hud.bind_player_state(player_state)
	coins_hud.bind_player_state(player_state)

	_setup_camera_limits()

	if _return_spawn_pending:
		hint_label.text = "Volviste a la orilla del río."
		hint_label.visible = true
		status_label.visible = false


func _setup_camera_limits() -> void:
	var world_size := Vector2(50 * 32, 38 * 32)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_size.x)
	camera.limit_bottom = int(world_size.y)
	camera.limit_smoothed = true


func _connect_fishing_signals() -> void:
	_fishing.hint_changed.connect(_on_hint_changed)
	_fishing.status_changed.connect(_on_status_changed)
	_fishing.fishing_prompt_changed.connect(_on_fishing_prompt_changed)
	_fishing.session_message.connect(_on_session_message)


func _physics_process(_delta: float) -> void:
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
		hint_label.text = "E — Entrar a la tienda"
		hint_label.visible = true
		_reset_hint_style()
		return
	_fishing.update_idle_hint()


func _try_enter_shop() -> bool:
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
	return local_player.call("is_free")


func _reset_hint_style() -> void:
	hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	hint_label.add_theme_color_override("font_outline_color", Color(0.1, 0.12, 0.16, 1))
	hint_label.add_theme_constant_override("outline_size", 4)
