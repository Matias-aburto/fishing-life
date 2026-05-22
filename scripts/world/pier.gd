extends Node2D

const TILE := 32

const COLOR_PLANK := Color(0.72, 0.52, 0.34)
const COLOR_PLANK_DARK := Color(0.62, 0.44, 0.28)
const COLOR_POST := Color(0.48, 0.34, 0.2)
const COLOR_RAIL := Color(0.78, 0.58, 0.36)

var pier_rect := Rect2()


func setup(river_tile_x: int, center_y_tile: int, length_tiles: int, width_tiles: int) -> Rect2:
	var start_tile_x := river_tile_x - 2
	var start_tile_y := center_y_tile - int(width_tiles / 2)

	pier_rect = Rect2(
		start_tile_x * TILE,
		start_tile_y * TILE,
		length_tiles * TILE,
		width_tiles * TILE
	)

	_build_deck(start_tile_x, start_tile_y, length_tiles, width_tiles)
	_build_posts(start_tile_x, start_tile_y, length_tiles, width_tiles)
	_build_railings(start_tile_x, start_tile_y, length_tiles, width_tiles)
	_add_label()
	z_index = 4

	return pier_rect


func _build_deck(start_x: int, start_y: int, length: int, width: int) -> void:
	for i in length:
		for j in width:
			var pos := Vector2((start_x + i) * TILE, (start_y + j) * TILE)
			var color := COLOR_PLANK if (i + j) % 2 == 0 else COLOR_PLANK_DARK
			_add_plank(pos, color)


func _add_plank(pos: Vector2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(TILE, 0),
		Vector2(TILE, TILE),
		Vector2(0, TILE),
	])
	poly.position = pos
	poly.color = color
	add_child(poly)


func _build_posts(start_x: int, start_y: int, length: int, width: int) -> void:
	for i in range(0, length, 2):
		for side: int in [-1, width]:
			var pos := Vector2(
				float(start_x + i) * float(TILE) + float(TILE) * 0.5,
				float(start_y + side) * float(TILE)
			)
			_add_post(pos)


func _add_post(pos: Vector2) -> void:
	var post := Polygon2D.new()
	post.color = COLOR_POST
	post.polygon = PackedVector2Array([
		Vector2(-4, -6), Vector2(4, -6), Vector2(4, 10), Vector2(-4, 10),
	])
	post.position = pos
	post.z_index = 1
	add_child(post)


func _build_railings(start_x: int, start_y: int, length: int, width: int) -> void:
	for i in length:
		for side: int in [0, width - 1]:
			var y: float = float(start_y + side) * float(TILE) + float(TILE) * 0.5
			var x: float = float(start_x + i) * float(TILE)
			var rail_y: float = y - 2.0 if side == 0 else y + 10.0
			var rail := Polygon2D.new()
			rail.color = COLOR_RAIL
			rail.polygon = PackedVector2Array([
				Vector2(0, -2), Vector2(TILE, -2), Vector2(TILE, 2), Vector2(0, 2),
			])
			rail.position = Vector2(x, rail_y)
			rail.z_index = 2
			add_child(rail)


func _add_label() -> void:
	var label := Label.new()
	label.text = "Muelle"
	label.position = pier_rect.position + Vector2(8, -36)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.18, 0.14, 0.1))
	label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)


func get_fishing_positions() -> Array[Vector2]:
	var tip_x := pier_rect.position.x + pier_rect.size.x - TILE * 0.75
	var mid_y := pier_rect.position.y + pier_rect.size.y * 0.5
	return [
		Vector2(tip_x, mid_y),
		Vector2(tip_x - TILE * 1.5, mid_y),
	]
