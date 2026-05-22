extends Node2D

# Escenario: pradera — orilla — río meandrante — orilla — pradera (Loncoche).

const TILE := 32
const MAP_W := 50
const MAP_H := 38

const RIVER_BASE_CENTER := 27.0
const RIVER_WATER_TILES := 7
const SHORE_TILES := 1

const BRIDGE_CENTER_Y_TILE := 31
const BRIDGE_HEIGHT_TILES := 3

const COLOR_SKY := Color(0.72, 0.86, 0.96)
const COLOR_GRASS := Color(0.52, 0.76, 0.42)
const COLOR_GRASS_DARK := Color(0.44, 0.66, 0.36)
const COLOR_SHORE := Color(0.82, 0.72, 0.52)
const COLOR_WATER := Color(0.38, 0.68, 0.82)
const COLOR_WATER_DEEP := Color(0.28, 0.55, 0.72)
const COLOR_TREE := Color(0.32, 0.58, 0.28)
const COLOR_TREE_TRUNK := Color(0.55, 0.4, 0.24)
const COLOR_BRIDGE_PLANK := Color(0.68, 0.5, 0.32)
const COLOR_BRIDGE_PLANK_DARK := Color(0.56, 0.4, 0.26)
const COLOR_BRIDGE_RAIL := Color(0.42, 0.3, 0.18)

enum TileKind { GRASS, WEST_SHORE, WATER, EAST_SHORE, BRIDGE }

var _river_center_by_row: PackedFloat32Array = PackedFloat32Array()
var _pier_rect := Rect2()
var _bridge_rect := Rect2()
var _bridge_tile_range := Vector2i.ZERO
var _pier: Node2D
var _water_material: ShaderMaterial


func _ready() -> void:
	_precompute_river_path()
	_bridge_rect = _compute_bridge_rect()
	_water_material = _create_water_material()
	_build_sky()
	_build_terrain()
	_build_trees()
	_pier_rect = _build_pier()
	_build_bridge()
	_build_collisions()
	_build_fishing_spots()
	_build_pier_fishing_spots()
	_build_shop()
	_add_sign()


func _precompute_river_path() -> void:
	_river_center_by_row.resize(MAP_H)
	for ty in MAP_H:
		_river_center_by_row[ty] = _calculate_river_center(ty)


func _calculate_river_center(ty: int) -> float:
	var y := float(ty)
	var along := (y / float(MAP_H - 1)) - 0.5
	var meander := sin(y * 0.17) * 3.8
	meander += sin(y * 0.06 + 2.0) * 2.2
	meander += sin(y * 0.31 + 0.6) * 1.4
	meander += along * 2.0
	return clampf(RIVER_BASE_CENTER + meander, 14.0, float(MAP_W - 16))


func _river_center_at(ty: int) -> float:
	return _river_center_by_row[ty]


func _water_half_width() -> int:
	return RIVER_WATER_TILES / 2


func _water_bounds_at(ty: int) -> Vector2i:
	var center := int(round(_river_center_at(ty)))
	var half := _water_half_width()
	return Vector2i(center - half, center + half)


func _west_shore_tile_at(ty: int) -> int:
	return _water_bounds_at(ty).x - SHORE_TILES


func _east_shore_tile_at(ty: int) -> int:
	return _water_bounds_at(ty).y + SHORE_TILES


func _bridge_y_range() -> Vector2i:
	var y0: int = BRIDGE_CENTER_Y_TILE - int(BRIDGE_HEIGHT_TILES / 2)
	return Vector2i(y0, y0 + BRIDGE_HEIGHT_TILES - 1)


func _compute_bridge_rect() -> Rect2:
	var y_range := _bridge_y_range()
	var min_x := MAP_W
	var max_x := 0
	for ty in range(y_range.x, y_range.y + 1):
		min_x = mini(min_x, _west_shore_tile_at(ty))
		max_x = maxi(max_x, _east_shore_tile_at(ty))
	_bridge_tile_range = Vector2i(min_x, max_x)
	var y0 := y_range.x * TILE
	return Rect2(min_x * TILE, y0, (max_x - min_x + 1) * TILE, (y_range.y - y_range.x + 1) * TILE)


func _classify_tile(tx: int, ty: int) -> TileKind:
	var y_range := _bridge_y_range()
	if ty >= y_range.x and ty <= y_range.y:
		if tx >= _bridge_tile_range.x and tx <= _bridge_tile_range.y:
			return TileKind.BRIDGE

	var bounds := _water_bounds_at(ty)
	if tx >= bounds.x and tx <= bounds.y:
		return TileKind.WATER
	if tx == _west_shore_tile_at(ty):
		return TileKind.WEST_SHORE
	if tx == _east_shore_tile_at(ty):
		return TileKind.EAST_SHORE
	return TileKind.GRASS


func _tile_rect(tx: int, ty: int) -> Rect2:
	return Rect2(tx * TILE, ty * TILE, TILE, TILE)


func _build_sky() -> void:
	var sky := Polygon2D.new()
	sky.color = COLOR_SKY
	sky.z_index = -10
	sky.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(MAP_W * TILE, 0),
		Vector2(MAP_W * TILE, MAP_H * TILE),
		Vector2(0, MAP_H * TILE),
	])
	add_child(sky)


func _build_terrain() -> void:
	for ty in MAP_H:
		var center := _river_center_at(ty)

		for tx in MAP_W:
			var pos := Vector2(tx * TILE, ty * TILE)
			var kind := _classify_tile(tx, ty)

			match kind:
				TileKind.BRIDGE:
					var plank := COLOR_BRIDGE_PLANK if (tx + ty) % 2 == 0 else COLOR_BRIDGE_PLANK_DARK
					_add_tile(pos, Vector2(TILE, TILE), plank)
				TileKind.WATER:
					var depth := absf(float(tx) - center) / maxf(float(_water_half_width()), 1.0)
					var water_color := COLOR_WATER.lerp(COLOR_WATER_DEEP, clampf(depth, 0.0, 1.0))
					_add_water_tile(pos, Vector2(TILE, TILE), water_color)
				TileKind.WEST_SHORE, TileKind.EAST_SHORE:
					_add_tile(pos, Vector2(TILE, TILE), COLOR_SHORE)
				_:
					var grass := COLOR_GRASS if (tx + ty) % 2 == 0 else COLOR_GRASS_DARK
					_add_tile(pos, Vector2(TILE, TILE), grass)


func _create_water_material() -> ShaderMaterial:
	var shader := load("res://shaders/water_flow.gdshader") as Shader
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _add_tile(pos: Vector2, rect_size: Vector2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(rect_size.x, 0),
		rect_size,
		Vector2(0, rect_size.y),
	])
	poly.position = pos
	poly.color = color
	add_child(poly)


func _add_water_tile(pos: Vector2, rect_size: Vector2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(rect_size.x, 0),
		rect_size,
		Vector2(0, rect_size.y),
	])
	poly.position = pos
	poly.color = color
	poly.material = _water_material
	poly.z_index = -5
	add_child(poly)


func _build_bridge() -> void:
	var z := 5
	var y_range := _bridge_y_range()
	for ty in range(y_range.x, y_range.y + 1):
		for tx in range(_bridge_tile_range.x, _bridge_tile_range.y + 1):
			if _classify_tile(tx, ty) != TileKind.BRIDGE:
				continue
			if tx == _bridge_tile_range.x or tx == _bridge_tile_range.y:
				_add_bridge_rail(Vector2(tx * TILE + 4, ty * TILE + 10), z)
				_add_bridge_rail(Vector2(tx * TILE + TILE - 8, ty * TILE + 10), z)

	var label := Label.new()
	label.text = "Puente"
	label.position = _bridge_rect.position + Vector2(8, -28)
	label.z_index = z + 1
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.18, 0.14, 0.1))
	label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)


func _add_bridge_rail(pos: Vector2, z: int) -> void:
	var rail := Polygon2D.new()
	rail.z_index = z
	rail.color = COLOR_BRIDGE_RAIL
	rail.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(4, 0), Vector2(4, 14), Vector2(0, 14),
	])
	rail.position = pos
	add_child(rail)


func _build_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	for i in 40:
		var tx := rng.randi_range(2, MAP_W - 3)
		var ty := rng.randi_range(2, MAP_H - 3)
		var kind := _classify_tile(tx, ty)
		if kind != TileKind.GRASS:
			continue
		_add_tree(Vector2(tx * TILE + 16, ty * TILE + 16))


func _add_tree(pos: Vector2) -> void:
	var trunk := Polygon2D.new()
	trunk.color = COLOR_TREE_TRUNK
	trunk.polygon = PackedVector2Array([
		Vector2(-3, 0), Vector2(3, 0), Vector2(3, 10), Vector2(-3, 10),
	])
	trunk.position = pos
	add_child(trunk)

	var crown := Polygon2D.new()
	crown.color = COLOR_TREE
	var pts: PackedVector2Array = []
	for i in 8:
		var angle := i * TAU / 8.0
		pts.append(Vector2(cos(angle), sin(angle)) * 14.0)
	crown.polygon = pts
	crown.position = pos + Vector2(0, -10)
	add_child(crown)


func _build_pier() -> Rect2:
	_pier = preload("res://scenes/world/pier.tscn").instantiate()
	var center_y := int(MAP_H * 0.42)
	var west_water := _water_bounds_at(center_y).x
	add_child(_pier)
	return _pier.setup(west_water, center_y, 4, 2)


func _build_collisions() -> void:
	var world_w := MAP_W * TILE
	var world_h := MAP_H * TILE
	var thickness := 16
	var walkable: Array[Rect2] = [_pier_rect, _bridge_rect]

	_add_wall(Rect2(-thickness, 0, thickness, world_h))
	_add_wall(Rect2(world_w, 0, thickness, world_h))
	_add_wall(Rect2(0, -thickness, world_w, thickness))
	_add_wall(Rect2(0, world_h, world_w, thickness))

	for ty in MAP_H:
		for tx in MAP_W:
			if _classify_tile(tx, ty) != TileKind.WATER:
				continue
			var tile_r := _tile_rect(tx, ty)
			if _rect_overlaps_any(tile_r, walkable):
				continue
			_add_wall(tile_r)


func _rect_overlaps_any(rect: Rect2, others: Array[Rect2]) -> bool:
	for other in others:
		if rect.intersects(other):
			return true
	return false


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


func _build_fishing_spots() -> void:
	var spot_scene: PackedScene = preload("res://scenes/fishing/fishing_spot.tscn")
	var pier_center_y := int(MAP_H * 0.42)
	var pier_half_h := 2
	var bridge_range := _bridge_y_range()

	for ty in range(4, MAP_H - 4, 5):
		if abs(ty - pier_center_y) <= pier_half_h + 1:
			continue
		if ty >= bridge_range.x and ty <= bridge_range.y:
			continue

		var west: FishingSpot = spot_scene.instantiate()
		west.position = Vector2(_west_shore_tile_at(ty) * TILE + TILE * 0.5, ty * TILE + TILE * 0.5)
		west.spot_name = "Orilla oeste"
		add_child(west)

		var east: FishingSpot = spot_scene.instantiate()
		east.position = Vector2(_east_shore_tile_at(ty) * TILE + TILE * 0.5, ty * TILE + TILE * 0.5)
		east.spot_name = "Orilla este"
		add_child(east)


func _build_pier_fishing_spots() -> void:
	if _pier == null:
		return

	var spot_scene: PackedScene = preload("res://scenes/fishing/fishing_spot.tscn")
	for pos in _pier.get_fishing_positions():
		var spot: FishingSpot = spot_scene.instantiate()
		spot.position = pos
		spot.spot_name = "Muelle"
		add_child(spot)


func _build_shop() -> void:
	var shop_y := 10
	var east_shore := _east_shore_tile_at(shop_y)
	var shop_x := mini(MAP_W - 7, east_shore + 8)
	var shop: Node2D = preload("res://scenes/world/fishing_shop.tscn").instantiate()
	shop.setup(shop_x, shop_y)
	add_child(shop)


func _add_sign() -> void:
	var label := Label.new()
	var sign_y := 5
	var sign_x := _west_shore_tile_at(sign_y)
	label.text = "Río — Loncoche"
	label.position = Vector2(sign_x * TILE - 200, sign_y * TILE)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.15, 0.2, 0.28))
	label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
