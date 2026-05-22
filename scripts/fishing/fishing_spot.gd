class_name FishingSpot
extends Area2D

@export var spot_name := "Orilla del río"

var _bodies_inside: Array[Node2D] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body not in _bodies_inside:
		_bodies_inside.append(body)


func _on_body_exited(body: Node2D) -> void:
	_bodies_inside.erase(body)


func is_body_inside(body: Node2D) -> bool:
	return body != null and body in _bodies_inside
