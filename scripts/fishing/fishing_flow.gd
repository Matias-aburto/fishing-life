class_name FishingFlow
extends RefCounted

enum Phase { IDLE, WAITING_BITE, BITE_WINDOW, MINIGAME }

const WAIT_MIN_SEC := 2.5
const WAIT_MAX_SEC := 11.0
const BITE_WINDOW_MIN_SEC := 0.85
const BITE_WINDOW_MAX_SEC := 1.55

var phase: Phase = Phase.IDLE


func start_waiting() -> float:
	phase = Phase.WAITING_BITE
	return randf_range(WAIT_MIN_SEC, WAIT_MAX_SEC)


func trigger_bite() -> float:
	phase = Phase.BITE_WINDOW
	return randf_range(BITE_WINDOW_MIN_SEC, BITE_WINDOW_MAX_SEC)


func start_minigame() -> void:
	phase = Phase.MINIGAME


func reset() -> void:
	phase = Phase.IDLE


func is_idle() -> bool:
	return phase == Phase.IDLE


func is_waiting_bite() -> bool:
	return phase == Phase.WAITING_BITE


func is_bite_window() -> bool:
	return phase == Phase.BITE_WINDOW


func is_in_minigame() -> bool:
	return phase == Phase.MINIGAME
