extends Control

var minigame: Control


func _draw() -> void:
	if minigame == null or not minigame.active:
		return
	minigame.paint_bar(self)
