class_name PlayerSpriteFramesBuilder
extends RefCounted
## Construye SpriteFrames desde fisherman_sheet.png (grid 4×5, celdas 256×256).

const SHEET_PATH := "res://assets/sprites/player/fisherman_sheet.png"
const FRAME_W := 256
const FRAME_H := 307
const ROW_COUNT := 5


static func build() -> SpriteFrames:
	var tex: Texture2D = load(SHEET_PATH) as Texture2D
	var sf := SpriteFrames.new()
	if tex == null:
		push_warning("No se encontró %s" % SHEET_PATH)
		return sf

	_add_row(sf, "idle_front", tex, 0, [0, 3], 4.0, true)
	_add_row(sf, "idle_back", tex, 0, [1, 2], 4.0, true)
	_add_row(sf, "walk_front", tex, 0, [0, 3], 8.0, true)
	_add_row(sf, "walk_back", tex, 0, [1, 2], 8.0, true)
	_add_row(sf, "walk_side_rod", tex, 1, [0, 1, 2, 3], 9.0, true)
	_add_row(sf, "walk_side", tex, 2, [0, 1, 2, 3], 9.0, true)
	_add_row(sf, "fish_hold", tex, 3, [0, 1, 2, 3], 6.0, true)
	_add_row(sf, "fish_reel", tex, 4, [0, 1, 2, 3], 8.0, true)

	return sf


static func _add_row(
	sf: SpriteFrames,
	anim_name: String,
	tex: Texture2D,
	row: int,
	cols: Array,
	fps: float,
	loop: bool
) -> void:
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	var sheet_h := tex.get_height()
	for col in cols:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		var row_y := row * FRAME_H
		var row_h := FRAME_H if row < ROW_COUNT - 1 else sheet_h - row_y
		atlas.region = Rect2(col * FRAME_W, row_y, FRAME_W, row_h)
		sf.add_frame(anim_name, atlas)
