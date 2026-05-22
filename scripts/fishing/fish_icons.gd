class_name FishIcons
extends RefCounted

const ICON_DIR := "res://assets/sprites/fish/icon/"

static var _cache: Dictionary = {}


static func get_icon(species_id: String) -> Texture2D:
	if species_id.is_empty():
		return null
	if _cache.has(species_id):
		return _cache[species_id]

	var path := ICON_DIR + species_id + ".png"
	if not ResourceLoader.exists(path):
		_cache[species_id] = null
		return null

	var texture: Texture2D = load(path) as Texture2D
	_cache[species_id] = texture
	return texture


static func get_icon_for_item(item: InventoryItem) -> Texture2D:
	if item == null or item.category != InventoryItem.Category.FISH:
		return null
	return get_icon(item.get_species_id())
