extends Node2D

@onready var local_player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var interior: Node2D = $Interior
@onready var hint_label: Label = $UI/HUD/HintLabel
@onready var guide_label: Label = $UI/HUD/GuideLabel
@onready var fishing_shop_ui: Control = $UI/FishingShopUI
@onready var inventory_hud: Control = $UI/InventoryHud
@onready var coins_hud: Control = $UI/CoinsHud

var _player_state: PlayerState
var _shop_ui_open := false


func _ready() -> void:
	local_player.add_to_group("local_player")

	_player_state = GameSession.ensure_player_state()
	_player_state.restore_starting_loadout_if_empty()
	var spawn: Vector2 = interior.build()
	local_player.global_position = spawn

	inventory_hud.bind_player_state(_player_state)
	coins_hud.bind_player_state(_player_state)
	fishing_shop_ui.bind_player_state(_player_state)
	fishing_shop_ui.closed.connect(_on_shop_ui_closed)

	guide_label.text = "Camina hacia arriba hasta la zona amarilla del mostrador."
	_setup_camera()


func _setup_camera() -> void:
	var bounds := Rect2(0, 0, 480, 300)
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.limit_smoothed = true


func _physics_process(_delta: float) -> void:
	if _shop_ui_open:
		return

	_update_hint()

	if not _is_player_free():
		return

	if not Input.is_action_just_pressed("interact"):
		return

	if ZoneOverlap.find_shop_counter(local_player) != null:
		_open_shop_ui()
	elif ZoneOverlap.find_shop_exit(local_player) != null:
		_exit_to_overworld()


func _update_hint() -> void:
	if ZoneOverlap.find_shop_counter(local_player) != null:
		hint_label.text = "E — Hablar con el vendedor"
		hint_label.visible = true
		guide_label.visible = false
		return
	if ZoneOverlap.find_shop_exit(local_player) != null:
		hint_label.text = "E — Salir de la tienda"
		hint_label.visible = true
		guide_label.visible = false
		return
	hint_label.visible = false
	guide_label.visible = true


func _open_shop_ui() -> void:
	_shop_ui_open = true
	hint_label.visible = false
	guide_label.visible = false
	local_player.call("set_input_blocked", true)
	local_player.call("set_activity", PlayerActivity.Type.IN_SHOP)
	fishing_shop_ui.open_shop()


func _on_shop_ui_closed() -> void:
	_shop_ui_open = false
	local_player.call("set_input_blocked", false)
	local_player.call("set_activity", PlayerActivity.Type.IDLE)
	_update_hint()


func _exit_to_overworld() -> void:
	GameSession.return_to_overworld()


func _is_player_free() -> bool:
	return local_player.call("is_free")
