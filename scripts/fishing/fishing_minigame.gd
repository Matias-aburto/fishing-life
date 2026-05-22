extends Control

signal finished(success: bool, catch: FishCatch)

@onready var _bar_area: Control = $BarArea

# Posiciones 0 (abajo) – 1 (arriba), dentro del área jugable.
const POS_EDGE := 0.08

var fish_pos := 0.5
var bar_pos := 0.5
var fish_velocity := 0.0
var catch_progress := 0.0
var active := false

const _BASE_CATCH_ZONE := 0.28
const _BASE_PROGRESS_GAIN := 38.0
const _BASE_PROGRESS_LOSS := 22.0
const _BASE_FISH_WANDER := 1.4

@export var catch_zone_size := 0.28
@export var progress_gain := 38.0
@export var progress_loss := 22.0
@export var fish_wander_strength := 1.4
@export var bar_rise_speed := 1.6
@export var bar_fall_speed := 0.9

var _rng := RandomNumberGenerator.new()
var _pending_catch: FishCatch


func _ready() -> void:
	_rng.randomize()
	_bar_area.minigame = self
	hide()


func start_minigame(pending_catch: FishCatch, visual_rng: RandomNumberGenerator = null) -> void:
	active = true
	fish_pos = 0.5
	bar_pos = 0.5
	fish_velocity = 0.0
	catch_progress = 0.0
	_pending_catch = pending_catch
	if visual_rng != null:
		_rng = visual_rng
	_apply_difficulty(_pending_catch)
	show()
	_bar_area.queue_redraw()


func _apply_difficulty(catch: FishCatch) -> void:
	catch_zone_size = _BASE_CATCH_ZONE
	progress_gain = _BASE_PROGRESS_GAIN
	progress_loss = _BASE_PROGRESS_LOSS
	fish_wander_strength = _BASE_FISH_WANDER

	if not FishDatabase.is_trout(catch.species_id) or catch.weight_kg <= FishDatabase.TROUT_HEAVY_KG:
		return

	var excess: float = catch.weight_kg - FishDatabase.TROUT_HEAVY_KG
	var factor: float = clampf(excess / 3.0, 0.0, 1.0)
	catch_zone_size = lerpf(_BASE_CATCH_ZONE, 0.17, factor)
	progress_gain = lerpf(_BASE_PROGRESS_GAIN, 22.0, factor)
	progress_loss = lerpf(_BASE_PROGRESS_LOSS, 36.0, factor)
	fish_wander_strength = lerpf(_BASE_FISH_WANDER, 2.3, factor)


func _process(delta: float) -> void:
	if not active:
		return

	fish_velocity += _rng.randf_range(-fish_wander_strength, fish_wander_strength) * delta
	fish_velocity = clampf(fish_velocity, -1.2, 1.2)
	fish_pos += fish_velocity * delta * 0.55
	fish_pos = clampf(fish_pos, POS_EDGE, 1.0 - POS_EDGE)

	if Input.is_action_pressed("fish_reel"):
		bar_pos += bar_rise_speed * delta
	else:
		bar_pos -= bar_fall_speed * delta
	bar_pos = clampf(bar_pos, POS_EDGE, 1.0 - POS_EDGE)

	var half_zone := catch_zone_size * 0.5
	var in_zone := fish_pos >= bar_pos - half_zone and fish_pos <= bar_pos + half_zone

	if in_zone:
		catch_progress += progress_gain * delta
	else:
		catch_progress -= progress_loss * delta

	catch_progress = clampf(catch_progress, 0.0, 100.0)
	_bar_area.queue_redraw()

	if catch_progress >= 100.0:
		_end_minigame(true)
	elif catch_progress <= 0.0:
		_end_minigame(false)


func _end_minigame(success: bool) -> void:
	active = false
	hide()
	var result: FishCatch = _pending_catch if success else null
	finished.emit(success, result)


func _get_bar_frame_rect(area_size: Vector2) -> Rect2:
	const PROGRESS_RESERVE := 28.0
	return Rect2(
		Vector2(area_size.x * 0.28, 0),
		Vector2(area_size.x * 0.44, maxf(area_size.y - PROGRESS_RESERVE, 120.0))
	)


func _get_bar_play_rect(frame: Rect2) -> Rect2:
	# Margen para que pez y barra del jugador no sobresalgan del canal.
	const PAD_TOP := 12.0
	const PAD_BOTTOM := 12.0
	return Rect2(
		frame.position.x + 4.0,
		frame.position.y + PAD_TOP,
		frame.size.x - 8.0,
		frame.size.y - PAD_TOP - PAD_BOTTOM
	)


func _play_y(play: Rect2, pos: float) -> float:
	return play.position.y + play.size.y * (1.0 - clampf(pos, 0.0, 1.0))


func paint_bar(canvas: Control) -> void:
	var area_size := canvas.size
	var bar_rect := _get_bar_frame_rect(area_size)
	var play_rect := _get_bar_play_rect(bar_rect)

	# Marco oscuro + canal del río (contrasta con el panel claro)
	canvas.draw_rect(bar_rect.grow(5), Color(0.12, 0.14, 0.18, 1.0))
	canvas.draw_rect(bar_rect.grow(3), Color(0.2, 0.24, 0.3, 1.0))
	canvas.draw_rect(bar_rect, Color(0.14, 0.28, 0.42, 1.0))
	canvas.draw_rect(play_rect, Color(0.1, 0.22, 0.36, 1.0))

	var half_zone := catch_zone_size * 0.5
	var zone_bottom_y := _play_y(play_rect, bar_pos - half_zone)
	var zone_top_y := _play_y(play_rect, bar_pos + half_zone)
	zone_bottom_y = clampf(zone_bottom_y, play_rect.position.y, play_rect.position.y + play_rect.size.y)
	zone_top_y = clampf(zone_top_y, play_rect.position.y, play_rect.position.y + play_rect.size.y)
	var zone_rect := Rect2(
		play_rect.position.x,
		zone_top_y,
		play_rect.size.x,
		maxf(zone_bottom_y - zone_top_y, 1.0)
	)
	canvas.draw_rect(zone_rect, Color(0.15, 0.72, 0.38, 0.75))
	canvas.draw_rect(zone_rect.grow(-1), Color(0.35, 0.92, 0.52, 0.55))

	var fish_center := Vector2(play_rect.position.x + play_rect.size.x * 0.5, _play_y(play_rect, fish_pos))
	canvas.draw_circle(fish_center, 10.0, Color(0.15, 0.1, 0.05, 0.5))
	canvas.draw_circle(fish_center, 9.0, Color(1.0, 0.62, 0.12, 1.0))
	canvas.draw_arc(fish_center, 9.0, 0, TAU, 24, Color(0.45, 0.22, 0.05, 1.0), 2.5)

	const PLAYER_BAR_H := 8.0
	var bar_center_y := _play_y(play_rect, bar_pos)
	var player_top := clampf(bar_center_y - PLAYER_BAR_H * 0.5, play_rect.position.y, play_rect.position.y + play_rect.size.y - PLAYER_BAR_H)
	var player_rect := Rect2(play_rect.position.x + 2, player_top, play_rect.size.x - 4, PLAYER_BAR_H)
	canvas.draw_rect(player_rect.grow(2), Color(0.05, 0.08, 0.12, 0.9))
	canvas.draw_rect(player_rect, Color(0.45, 0.88, 1.0, 1.0))

	var progress_rect := Rect2(Vector2(4, area_size.y - 22), Vector2(area_size.x - 8, 14))
	canvas.draw_rect(progress_rect.grow(1), Color(0.15, 0.17, 0.22, 1.0))
	canvas.draw_rect(progress_rect, Color(0.32, 0.36, 0.42, 1.0))
	var fill_w := progress_rect.size.x * (catch_progress / 100.0)
	if fill_w > 0.0:
		canvas.draw_rect(Rect2(progress_rect.position, Vector2(fill_w, progress_rect.size.y)), Color(0.2, 0.85, 0.45, 1.0))
