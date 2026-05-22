class_name PlayerState
extends Node
## Inventario y monedas de un jugador. Una instancia por Player (no autoload).

enum InventorySlot { ROD, BAIT, FREE_1, FREE_2, FREE_3 }

const FREE_SLOTS: Array[InventorySlot] = [
	InventorySlot.FREE_1, InventorySlot.FREE_2, InventorySlot.FREE_3,
]

signal slot_changed(slot: InventorySlot)
signal money_changed

const SLOT_TITLES: Dictionary = {
	InventorySlot.ROD: "Caña",
	InventorySlot.BAIT: "Carnada",
	InventorySlot.FREE_1: "Libre 1",
	InventorySlot.FREE_2: "Libre 2",
	InventorySlot.FREE_3: "Libre 3",
}

@export var starting_coins: int = 50
@export var starting_bait: int = 8

var coins: int = 0
var _slots: Array[InventoryItem] = [null, null, null, null, null]
var _starting_loadout_applied := false


func _ready() -> void:
	apply_starting_loadout_if_needed()


func apply_starting_loadout_if_needed() -> void:
	if _starting_loadout_applied:
		return
	_apply_starting_loadout()


func restore_starting_loadout_if_empty() -> void:
	if has_rod():
		return
	_apply_starting_loadout()


func _apply_starting_loadout() -> void:
	_starting_loadout_applied = true
	coins = starting_coins
	set_slot(InventorySlot.ROD, InventoryItem.create_rod())
	set_slot(InventorySlot.BAIT, InventoryItem.create_bait(starting_bait))
	money_changed.emit()


func all_slots() -> Array[InventorySlot]:
	return [
		InventorySlot.ROD, InventorySlot.BAIT,
		InventorySlot.FREE_1, InventorySlot.FREE_2, InventorySlot.FREE_3,
	]


func is_free_slot(slot: InventorySlot) -> bool:
	return slot in FREE_SLOTS


func get_slot_title(slot: InventorySlot) -> String:
	return SLOT_TITLES[slot]


func get_item(slot: InventorySlot) -> InventoryItem:
	return _slots[slot]


func set_slot(slot: InventorySlot, item: InventoryItem) -> void:
	_slots[slot] = item
	slot_changed.emit(slot)


func clear_slot(slot: InventorySlot) -> void:
	set_slot(slot, null)


func has_rod() -> bool:
	var item := _slots[InventorySlot.ROD]
	return item != null and item.category == InventoryItem.Category.ROD


func has_bait() -> bool:
	var item := _slots[InventorySlot.BAIT]
	return item != null and item.category == InventoryItem.Category.BAIT and item.quantity > 0


func add_bait(amount: int) -> void:
	if amount <= 0:
		return
	var item := _slots[InventorySlot.BAIT]
	if item == null:
		set_slot(InventorySlot.BAIT, InventoryItem.create_bait(amount))
		return
	if item.category != InventoryItem.Category.BAIT:
		return
	item.quantity += amount
	slot_changed.emit(InventorySlot.BAIT)


func consume_bait() -> bool:
	var item := _slots[InventorySlot.BAIT]
	if item == null or item.category != InventoryItem.Category.BAIT:
		return false
	if item.quantity <= 0:
		return false
	item.quantity -= 1
	if item.quantity <= 0:
		_slots[InventorySlot.BAIT] = null
	slot_changed.emit(InventorySlot.BAIT)
	return true


func has_empty_free_slot() -> bool:
	if find_empty_free_slot() != -1:
		return true
	return get_first_fish_slot() != -1


func find_stack_slot_for_species(species_id: String) -> int:
	var fish_id := "fish_%s" % species_id
	for free_slot in FREE_SLOTS:
		var item := _slots[free_slot]
		if item != null and item.category == InventoryItem.Category.FISH and item.id == fish_id:
			return free_slot as int
	return -1


func find_empty_free_slot() -> int:
	for free_slot in FREE_SLOTS:
		if _slots[free_slot] == null:
			return free_slot as int
	return -1


func can_store_fish(catch: FishCatch) -> bool:
	if catch == null:
		return false
	if find_stack_slot_for_species(catch.species_id) != -1:
		return true
	return find_empty_free_slot() != -1


func try_store_fish(catch: FishCatch) -> bool:
	if catch == null:
		return false

	var stack_slot := find_stack_slot_for_species(catch.species_id)
	if stack_slot != -1:
		var item := _slots[stack_slot as InventorySlot]
		item.add_fish_catch(catch)
		slot_changed.emit(stack_slot as InventorySlot)
		return true

	var empty := find_empty_free_slot()
	if empty < 0:
		return false
	set_slot(empty as InventorySlot, InventoryItem.from_fish_catch(catch))
	return true


func get_first_fish_slot() -> int:
	for free_slot in FREE_SLOTS:
		var item := _slots[free_slot]
		if item != null and item.category == InventoryItem.Category.FISH:
			return free_slot as int
	return -1


func get_fish_in_slot(slot: InventorySlot) -> FishCatch:
	var item := _slots[slot]
	if item == null or item.category != InventoryItem.Category.FISH:
		return null
	return item.peek_fish()


func sell_first_fish() -> int:
	var slot_index := get_first_fish_slot()
	if slot_index < 0:
		return -1
	var slot := slot_index as InventorySlot
	var item := _slots[slot]
	if item == null:
		return -1
	var fish := item.pop_fish()
	if fish == null:
		return -1
	var price := FishPricing.get_sell_price(fish)
	if item.quantity <= 0:
		clear_slot(slot)
	else:
		slot_changed.emit(slot)
	return price


func can_afford(cost: int) -> bool:
	return cost > 0 and coins >= cost


func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	coins -= cost
	money_changed.emit()
	return true


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	money_changed.emit()
