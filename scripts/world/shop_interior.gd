extends Node2D

const TILE := 32
const ROOM_W := 11
const ROOM_H := 8

const COLOR_FLOOR := Color(0.72, 0.62, 0.48)
const COLOR_FLOOR_DARK := Color(0.64, 0.54, 0.42)
const COLOR_WALL := Color(0.78, 0.68, 0.52)
const COLOR_WALL_DARK := Color(0.68, 0.58, 0.44)
const COLOR_COUNTER := Color(0.55, 0.38, 0.28)
const COLOR_COUNTER_TOP := Color(0.68, 0.5, 0.32)
const COLOR_VENDOR := Color(0.35, 0.55, 0.75)
const COLOR_CUSTOMER_MAT := Color(0.9, 0.75, 0.2, 0.45)

var counter_customer_pos := Vector2.ZERO
var exit_pos := Vector2.ZERO
var spawn_pos := Vector2.ZERO


func build() -> Vector2:
	var origin := Vector2(32, 24)
	var room_size := Vector2(ROOM_W * TILE, ROOM_H * TILE)
	var counter_base := origin + Vector2(TILE * 1.5, TILE * 1.2)

	_build_floor(origin, room_size)
	_build_walls(origin, room_size)
	_build_counter(counter_base)
	_build_shelves(origin, room_size)

	counter_customer_pos = counter_base + Vector2(TILE * 4, TILE * 1.35)
	exit_pos = origin + Vector2(room_size.x * 0.5, room_size.y - TILE * 0.35)
	spawn_pos = exit_pos + Vector2(0, TILE * 0.85)

	_add_counter_zone()
	_add_exit_zone()
	_build_collisions(origin, room_size, counter_base)
	return spawn_pos


func _build_floor(origin: Vector2, size: Vector2) -> void:
	for row in ROOM_H:
		for col in ROOM_W:
			var pos := origin + Vector2(col * TILE, row * TILE)
			var color := COLOR_FLOOR if (row + col) % 2 == 0 else COLOR_FLOOR_DARK
			_add_rect(pos, Vector2(TILE, TILE), color, 0)


func _build_walls(origin: Vector2, size: Vector2) -> void:
	for col in ROOM_W:
		_add_rect(origin + Vector2(col * TILE, -TILE * 0.15), Vector2(TILE, TILE * 0.35), COLOR_WALL_DARK, 1)
	for row in ROOM_H:
		_add_rect(origin + Vector2(-TILE * 0.2, row * TILE), Vector2(TILE * 0.25, TILE), COLOR_WALL, 2)
		_add_rect(origin + Vector2(size.x, row * TILE), Vector2(TILE * 0.25, TILE), COLOR_WALL_DARK, 2)


func _build_counter(base: Vector2) -> void:
	_add_rect(base, Vector2(TILE * 8, TILE * 1.1), COLOR_COUNTER, 3)
	_add_rect(base + Vector2(0, -TILE * 0.35), Vector2(TILE * 8, TILE * 0.4), COLOR_COUNTER_TOP, 4)

	var vendor := Polygon2D.new()
	vendor.color = COLOR_VENDOR
	vendor.polygon = PackedVector2Array([
		Vector2(-10, -18), Vector2(10, -18), Vector2(10, 14), Vector2(-10, 14),
	])
	vendor.position = base + Vector2(TILE * 4, -TILE * 0.95)
	vendor.z_index = 5
	add_child(vendor)

	var label := Label.new()
	label.text = "Vendedor"
	label.position = vendor.position + Vector2(-28, -36)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.15, 0.2, 0.28, 1))
	label.z_index = 6
	add_child(label)


func _build_shelves(origin: Vector2, size: Vector2) -> void:
	var shelf_color := Color(0.62, 0.48, 0.34)
	_add_rect(origin + Vector2(TILE * 0.4, TILE * 2.8), Vector2(TILE * 1.2, TILE * 3.5), shelf_color, 1)
	_add_rect(origin + Vector2(size.x - TILE * 1.6, TILE * 2.8), Vector2(TILE * 1.2, TILE * 3.5), shelf_color, 1)


func _add_counter_zone() -> void:
	var zone: ShopCounterZone = preload("res://scenes/world/shop_counter_zone.tscn").instantiate()
	zone.position = counter_customer_pos
	add_child(zone)

	var marker := Polygon2D.new()
	marker.color = COLOR_CUSTOMER_MAT
	marker.polygon = PackedVector2Array([
		Vector2(-90, -28), Vector2(90, -28), Vector2(90, 28), Vector2(-90, 28),
	])
	marker.position = counter_customer_pos
	marker.z_index = 1
	add_child(marker)

	var hint := Label.new()
	hint.text = "Mostrador"
	hint.position = counter_customer_pos + Vector2(-42, -52)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1, 1))
	hint.z_index = 2
	add_child(hint)


func _add_exit_zone() -> void:
	var zone: ShopExitZone = preload("res://scenes/world/shop_exit_zone.tscn").instantiate()
	zone.position = exit_pos
	add_child(zone)

	var mat := Polygon2D.new()
	mat.color = Color(0.42, 0.28, 0.18, 0.55)
	mat.polygon = PackedVector2Array([
		Vector2(-26, -18), Vector2(26, -18), Vector2(26, 18), Vector2(-26, 18),
	])
	mat.position = exit_pos
	mat.z_index = 1
	add_child(mat)


func _build_collisions(origin: Vector2, size: Vector2, counter_base: Vector2) -> void:
	# Sin colisión en el mostrador: el jugador puede acercarse por delante.
	var blocks: Array[Rect2] = [
		Rect2(origin.x - TILE * 0.2, origin.y - TILE * 0.2, size.x + TILE * 0.4, TILE * 0.5),
		Rect2(origin.x - TILE * 0.2, origin.y, TILE * 0.35, size.y),
		Rect2(origin.x + size.x - TILE * 0.1, origin.y, TILE * 0.35, size.y),
		Rect2(counter_base.x, counter_base.y - TILE * 0.5, TILE * 8, TILE * 0.45),
		Rect2(origin.x + TILE * 0.2, origin.y + TILE * 2.5, TILE * 1.4, TILE * 4),
		Rect2(origin.x + size.x - TILE * 1.6, origin.y + TILE * 2.5, TILE * 1.4, TILE * 4),
	]
	for block in blocks:
		_add_wall(block)


func _add_rect(pos: Vector2, size: Vector2, color: Color, z: int) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0),
		size,
		Vector2(0, size.y),
	])
	poly.position = pos
	poly.color = color
	poly.z_index = z
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
