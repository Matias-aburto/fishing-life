extends Node2D

const TILE := 32

const COLOR_WALL := Color(0.78, 0.68, 0.52)
const COLOR_WALL_DARK := Color(0.68, 0.58, 0.44)
const COLOR_ROOF := Color(0.55, 0.32, 0.28)
const COLOR_ROOF_LIGHT := Color(0.62, 0.38, 0.32)
const COLOR_DOOR := Color(0.42, 0.28, 0.18)
const COLOR_WINDOW := Color(0.55, 0.75, 0.9)
const COLOR_SIGN := Color(0.2, 0.45, 0.32)
const COLOR_AWNING := Color(0.85, 0.35, 0.28)

var shop_rect := Rect2()


func setup(anchor_tx: int, anchor_ty: int) -> Rect2:
	var origin := Vector2(anchor_tx * TILE, anchor_ty * TILE)
	shop_rect = Rect2(origin.x, origin.y, 5 * TILE, 4 * TILE)

	_build_walls(origin)
	_build_roof(origin)
	_build_awning(origin)
	_build_door(origin)
	_build_windows(origin)
	_add_sign(origin)
	_add_door_zone(origin)
	_build_collisions(origin)
	z_index = 6

	return shop_rect


func _build_walls(origin: Vector2) -> void:
	for row in 3:
		for col in 5:
			var pos := origin + Vector2(col * TILE, (row + 1) * TILE)
			var color := COLOR_WALL if (row + col) % 2 == 0 else COLOR_WALL_DARK
			_add_rect(pos, Vector2(TILE, TILE), color)


func _build_roof(origin: Vector2) -> void:
	_add_rect(origin + Vector2(-TILE * 0.25, -TILE * 0.35), Vector2(TILE * 5.5, TILE * 0.9), COLOR_ROOF)
	_add_rect(origin + Vector2(0, -TILE * 0.1), Vector2(TILE * 5, TILE * 0.35), COLOR_ROOF_LIGHT)


func _build_awning(origin: Vector2) -> void:
	_add_rect(origin + Vector2(-TILE * 0.5, TILE * 3.85), Vector2(TILE * 1.6, TILE * 0.35), COLOR_AWNING)


func _build_door(origin: Vector2) -> void:
	_add_rect(origin + Vector2(-TILE * 0.15, TILE * 2.1), Vector2(TILE * 0.85, TILE * 1.75), COLOR_DOOR)


func _build_windows(origin: Vector2) -> void:
	_add_rect(origin + Vector2(TILE * 1.2, TILE * 1.5), Vector2(TILE * 0.75, TILE * 0.75), COLOR_WINDOW)
	_add_rect(origin + Vector2(TILE * 3.1, TILE * 1.5), Vector2(TILE * 0.75, TILE * 0.75), COLOR_WINDOW)


func _add_sign(origin: Vector2) -> void:
	var board := Polygon2D.new()
	board.color = COLOR_SIGN
	board.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(118, 0), Vector2(118, 28), Vector2(0, 28),
	])
	board.position = origin + Vector2(TILE * 0.6, -TILE * 0.95)
	board.z_index = 2
	add_child(board)

	var label := Label.new()
	label.text = "Tienda de pesca"
	label.position = origin + Vector2(TILE * 0.75, -TILE * 0.88)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.z_index = 3
	add_child(label)


func _add_door_zone(origin: Vector2) -> void:
	var door_center := origin + Vector2(TILE * 0.28, TILE * 3.0)
	var zone: ShopDoorZone = preload("res://scenes/world/shop_door_zone.tscn").instantiate()
	zone.position = door_center
	add_child(zone)

	var marker := Polygon2D.new()
	marker.color = Color(0.35, 0.75, 0.45, 0.4)
	marker.polygon = PackedVector2Array([
		Vector2(-18, -16), Vector2(18, -16), Vector2(18, 16), Vector2(-18, 16),
	])
	marker.position = door_center
	marker.z_index = 1
	add_child(marker)


func _build_collisions(origin: Vector2) -> void:
	var blocks: Array[Rect2] = [
		Rect2(origin.x, origin.y + TILE, TILE * 5, TILE * 3),
		Rect2(origin.x + TILE * 4.2, origin.y + TILE, TILE * 0.9, TILE * 3),
	]
	for block in blocks:
		_add_wall(block)


func _add_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0),
		size,
		Vector2(0, size.y),
	])
	poly.position = pos
	poly.color = color
	add_child(poly)


func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size
	shape.position = rect.position + rect.size * 0.5
	shape.shape = rect_shape
	body.add_child(shape)
	add_child(body)
