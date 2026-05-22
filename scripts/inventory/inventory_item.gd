class_name InventoryItem
extends RefCounted

enum Category { ROD, BAIT, FISH, MISC }

var id: String
var display_name: String
var category: Category
var quantity: int = 1
var fish_catches: Array[FishCatch] = []


func get_label() -> String:
	if category == Category.BAIT and quantity > 1:
		return "%s x%d" % [display_name, quantity]
	if category == Category.FISH:
		if quantity > 1:
			return "%s x%d" % [display_name, quantity]
		var fish := peek_fish()
		if fish != null:
			return fish.get_summary()
	return display_name


func get_species_id() -> String:
	if category != Category.FISH:
		return ""
	return id.trim_prefix("fish_")


func get_icon() -> String:
	match category:
		Category.ROD:
			return "🎣"
		Category.BAIT:
			return "🪱"
		Category.FISH:
			return "🐟"
		_:
			return "📦"


func peek_fish() -> FishCatch:
	if fish_catches.is_empty():
		return null
	return fish_catches[0]


func add_fish_catch(catch: FishCatch) -> void:
	fish_catches.append(catch)
	quantity = fish_catches.size()


func pop_fish() -> FishCatch:
	if fish_catches.is_empty():
		return null
	var fish: FishCatch = fish_catches.pop_front()
	quantity = fish_catches.size()
	return fish


static func create_rod() -> InventoryItem:
	var item := InventoryItem.new()
	item.id = "rod_basic"
	item.display_name = "Caña"
	item.category = Category.ROD
	item.quantity = 1
	return item


static func create_bait(amount: int = 8) -> InventoryItem:
	var item := InventoryItem.new()
	item.id = "bait_worm"
	item.display_name = "Carnada"
	item.category = Category.BAIT
	item.quantity = maxi(amount, 0)
	return item


static func from_fish_catch(catch: FishCatch) -> InventoryItem:
	var item := InventoryItem.new()
	item.id = "fish_%s" % catch.species_id
	item.display_name = catch.display_name
	item.category = Category.FISH
	item.add_fish_catch(catch)
	return item
