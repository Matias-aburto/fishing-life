class_name ItemIcons
extends RefCounted

const ICON_DIR := "res://assets/sprites/items/icon/"

const ITEM_FILES: Dictionary = {
	"rod_basic": "rod",
	"bait_worm": "bait",
}

static var _cache: Dictionary = {}


static func get_inventory_icon(item: InventoryItem) -> Texture2D:
	if item == null:
		return null
	if item.category == InventoryItem.Category.FISH:
		return FishIcons.get_icon_for_item(item)
	return _get_item_texture(item.id)


static func _get_item_texture(item_id: String) -> Texture2D:
	var file_name: String = ITEM_FILES.get(item_id, "")
	if file_name.is_empty():
		return null
	if _cache.has(file_name):
		return _cache[file_name]

	var path := ICON_DIR + file_name + ".png"
	if not ResourceLoader.exists(path):
		_cache[file_name] = null
		return null

	var texture: Texture2D = load(path) as Texture2D
	_cache[file_name] = texture
	return texture
