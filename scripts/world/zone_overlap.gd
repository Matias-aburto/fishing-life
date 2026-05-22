class_name ZoneOverlap
extends RefCounted
## Utilidades para zonas Area2D consultadas por jugador (multi-jugador friendly).


static func find_spot_for_body(body: Node2D) -> FishingSpot:
	if body == null:
		return null
	for node in body.get_tree().get_nodes_in_group("fishing_spot"):
		if node is FishingSpot and node.is_body_inside(body):
			return node
	return null


static func find_shop_door(body: Node2D) -> ShopDoorZone:
	if body == null:
		return null
	for node in body.get_tree().get_nodes_in_group("shop_door"):
		if node is ShopDoorZone and node.is_body_inside(body):
			return node
	return null


static func find_shop_counter(body: Node2D) -> ShopCounterZone:
	if body == null:
		return null
	for node in body.get_tree().get_nodes_in_group("shop_counter"):
		if node is ShopCounterZone and node.is_body_inside(body):
			return node
	return null


static func find_shop_exit(body: Node2D) -> ShopExitZone:
	if body == null:
		return null
	for node in body.get_tree().get_nodes_in_group("shop_exit"):
		if node is ShopExitZone and node.is_body_inside(body):
			return node
	return null
