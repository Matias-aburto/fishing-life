class_name GamePlayer
extends CharacterBody2D

const WALK_SPEED := 140.0
const RUN_SPEED := 230.0

var activity: PlayerActivity.Type = PlayerActivity.Type.IDLE
## Réplica numérica para MultiplayerSynchronizer.
var synced_activity: int = PlayerActivity.Type.IDLE

var facing := Vector2.DOWN
var input_blocked := false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var _camera: Camera2D = $Camera2D
@onready var _name_label: Label = $NameLabel
@onready var _player_state: PlayerState = $PlayerState


func _ready() -> void:
	sprite.sprite_frames = PlayerSpriteFramesBuilder.build()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	call_deferred("_setup_network_role")
	_update_animation(true)


func _setup_network_role() -> void:
	var is_local := is_local_player()
	_camera.enabled = is_local
	if is_local:
		add_to_group("local_player")
		if NetworkManager.solo_mode or not NetworkManager.is_online():
			activate_camera()
	var peer_id := get_multiplayer_authority()
	_name_label.text = "Tú" if is_local else "Jugador %d" % peer_id
	_name_label.visible = not is_local or NetworkManager.is_online()


func activate_camera() -> void:
	_camera.enabled = true
	_camera.make_current()


func get_player_state() -> PlayerState:
	return _player_state


func is_local_player() -> bool:
	return get_multiplayer_authority() == multiplayer.get_unique_id()


func _physics_process(_delta: float) -> void:
	if not is_local_player():
		_apply_synced_activity()
		_update_animation()
		return

	if _is_movement_locked():
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		return

	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if input.length_squared() > 0.0:
		input = input.normalized()
		facing = input
		var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
		velocity = input * speed
		set_activity(PlayerActivity.Type.WALKING)
	else:
		velocity = Vector2.ZERO
		if activity == PlayerActivity.Type.WALKING:
			set_activity(PlayerActivity.Type.IDLE)

	move_and_slide()
	_update_animation()


func _apply_synced_activity() -> void:
	if activity != synced_activity:
		activity = synced_activity as PlayerActivity.Type


func _is_movement_locked() -> bool:
	return input_blocked or activity in [
		PlayerActivity.Type.FISHING_WAIT,
		PlayerActivity.Type.FISHING_BITE,
		PlayerActivity.Type.FISHING_MINIGAME,
		PlayerActivity.Type.IN_SHOP,
	]


func _is_fishing_activity() -> bool:
	return activity in [
		PlayerActivity.Type.FISHING_WAIT,
		PlayerActivity.Type.FISHING_BITE,
		PlayerActivity.Type.FISHING_MINIGAME,
	]


func _has_rod() -> bool:
	return _player_state.has_rod()


func _update_animation(force := false) -> void:
	if sprite.sprite_frames == null:
		return

	var anim := _pick_animation()
	var flip_h := facing.x < -0.1

	if not force and sprite.animation == anim and sprite.flip_h == flip_h:
		return

	sprite.flip_h = flip_h
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
	elif sprite.sprite_frames.has_animation("idle_front"):
		sprite.play("idle_front")


func _pick_animation() -> String:
	if _is_fishing_activity():
		if activity == PlayerActivity.Type.FISHING_MINIGAME:
			return "fish_reel"
		return "fish_hold"

	var moving := activity == PlayerActivity.Type.WALKING and velocity.length_squared() > 1.0

	if absf(facing.y) > absf(facing.x):
		if facing.y > 0.0:
			return "walk_front" if moving else "idle_front"
		return "walk_back" if moving else "idle_back"

	if _has_rod():
		return "walk_side_rod" if moving else "idle_front"
	return "walk_side" if moving else "idle_front"


func set_activity(new_activity: PlayerActivity.Type) -> void:
	if activity == new_activity:
		return
	activity = new_activity
	synced_activity = new_activity as int
	_update_animation(true)


func start_fishing() -> void:
	velocity = Vector2.ZERO
	set_activity(PlayerActivity.Type.FISHING_WAIT)


func stop_fishing() -> void:
	set_activity(PlayerActivity.Type.IDLE)


func is_free() -> bool:
	return activity == PlayerActivity.Type.IDLE and not input_blocked


func set_input_blocked(blocked: bool) -> void:
	input_blocked = blocked
	if blocked:
		velocity = Vector2.ZERO
