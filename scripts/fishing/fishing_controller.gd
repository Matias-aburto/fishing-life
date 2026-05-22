class_name FishingController
extends Node
## Flujo de pesca por jugador. Validación local hoy; misma API para servidor mañana.

signal hint_changed(text: String, visible: bool)
signal status_changed(text: String, visible: bool)
signal fishing_prompt_changed(text: String, visible: bool, is_bite: bool)
signal session_message(message: String)

const CAST_FAIL_NO_ROD := "Necesitas una caña en su slot."
const CAST_FAIL_NO_BAIT := "No te queda carnada."
const CAST_FAIL_FULL_INV := "Inventario lleno (3 especies distintas). Vende en la tienda."

var _player: CharacterBody2D
var _state: PlayerState
var _minigame: Control
var _flow := FishingFlow.new()
var _session_rng := RandomNumberGenerator.new()
var _pending_catch: FishCatch
var _active_spot: FishingSpot
var _heavy_trout_escaped := false

var _bite_wait_timer: Timer
var _bite_window_timer: Timer


func setup(player: CharacterBody2D, state: PlayerState, minigame: Control) -> void:
	_player = player
	_state = state
	_minigame = minigame
	if _minigame.has_signal("finished"):
		_minigame.finished.connect(_on_minigame_finished)


func _player_activity() -> PlayerActivity.Type:
	return _player.get("activity") as PlayerActivity.Type


func _set_player_activity(act: PlayerActivity.Type) -> void:
	_player.call("set_activity", act)


func _ready() -> void:
	_setup_timers()


func _setup_timers() -> void:
	_bite_wait_timer = Timer.new()
	_bite_wait_timer.one_shot = true
	_bite_wait_timer.timeout.connect(_on_bite_wait_finished)
	add_child(_bite_wait_timer)

	_bite_window_timer = Timer.new()
	_bite_window_timer.one_shot = true
	_bite_window_timer.timeout.connect(_on_bite_window_expired)
	add_child(_bite_window_timer)


func is_idle() -> bool:
	return _flow.is_idle()


func refresh_zones() -> void:
	_active_spot = ZoneOverlap.find_spot_for_body(_player)


func get_active_spot() -> FishingSpot:
	return _active_spot


func update_idle_hint() -> void:
	refresh_zones()
	if _active_spot != null:
		hint_changed.emit("E — Pescar en %s" % _active_spot.spot_name, true)
		return
	hint_changed.emit("", false)


func wants_interact() -> bool:
	return Input.is_action_just_pressed("interact")


func process_interact() -> void:
	if _flow.is_idle():
		refresh_zones()
		if _active_spot != null:
			var err := try_start_cast(_active_spot)
			if not err.is_empty():
				status_changed.emit(err, true)
		return

	if _flow.is_bite_window() and wants_interact():
		try_hook_bite()


func process_fishing_tick() -> void:
	if _flow.is_idle():
		return
	_check_left_fishing_spot()


func try_start_cast(spot: FishingSpot) -> String:
	if spot == null or not spot.is_body_inside(_player):
		return "No estás en una zona de pesca."

	if not _state.has_rod():
		return CAST_FAIL_NO_ROD
	if not _state.has_bait():
		return CAST_FAIL_NO_BAIT
	if not _state.has_empty_free_slot():
		return CAST_FAIL_FULL_INV
	if not _state.consume_bait():
		return CAST_FAIL_NO_BAIT

	_active_spot = spot
	_session_rng.randomize()
	_player.call("start_fishing")
	status_changed.emit("", false)
	hint_changed.emit("", false)
	fishing_prompt_changed.emit("Esperando el pique…", true, false)
	_bite_wait_timer.start(_flow.start_waiting())
	return ""


func try_hook_bite() -> bool:
	if not _flow.is_bite_window():
		return false
	_bite_window_timer.stop()
	var species_id := FishDatabase.pick_random_species_id(_session_rng)
	_pending_catch = FishDatabase.roll_catch(species_id, _session_rng)
	_flow.start_minigame()
	_set_player_activity(PlayerActivity.Type.FISHING_MINIGAME)
	fishing_prompt_changed.emit("", false, false)
	if _minigame.has_method("start_minigame"):
		_minigame.start_minigame(_pending_catch, _session_rng)
	return true


func _on_bite_wait_finished() -> void:
	if not _flow.is_waiting_bite():
		return
	var react_time := _flow.trigger_bite()
	_set_player_activity(PlayerActivity.Type.FISHING_BITE)
	fishing_prompt_changed.emit("¡PICÓ!\nPulsa E rápido", true, true)
	_bite_window_timer.start(react_time)


func _on_bite_window_expired() -> void:
	if not _flow.is_bite_window():
		return
	_end_session("Perdiste el pique… Vuelve a intentar.")


func _on_minigame_finished(success: bool, catch: FishCatch) -> void:
	_heavy_trout_escaped = false
	if success and _pending_catch != null:
		var escape_chance := FishDatabase.get_trout_escape_chance(_pending_catch.weight_kg)
		if escape_chance > 0.0 and _session_rng.randf() < escape_chance:
			_heavy_trout_escaped = true
			success = false
		else:
			catch = _pending_catch
	resolve_minigame(success, catch)


func resolve_minigame(success: bool, catch: FishCatch) -> void:
	if success and catch != null:
		if _state.try_store_fish(catch):
			_end_session("¡Capturaste %s! (en inventario)" % catch.get_summary())
		else:
			_end_session("¡Capturaste %s!, pero no tienes espacio en el inventario." % catch.get_summary())
	elif _heavy_trout_escaped:
		_end_session("¡Casi! Una trucha grande se escapó al sacarla del agua.")
	else:
		_end_session("Se escapó… Vuelve a intentar.")


func _check_left_fishing_spot() -> void:
	refresh_zones()
	if _active_spot == null or not _active_spot.is_body_inside(_player):
		_cancel_session("Te alejaste del agua.")


func _cancel_session(message: String) -> void:
	_bite_wait_timer.stop()
	_bite_window_timer.stop()
	_end_session(message)


func _end_session(message: String) -> void:
	_flow.reset()
	_pending_catch = null
	_bite_wait_timer.stop()
	_bite_window_timer.stop()
	_player.call("stop_fishing")
	if _minigame.has_method("hide"):
		_minigame.hide()
	fishing_prompt_changed.emit("", false, false)
	session_message.emit(message)
