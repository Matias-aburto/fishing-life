extends Control

@onready var _slot_icon_labels: Array[Label] = [
	$Panel/Margin/HBox/SlotRod/Overlay/IconArea/IconLabel,
	$Panel/Margin/HBox/SlotBait/Overlay/IconArea/IconLabel,
	$Panel/Margin/HBox/SlotFree1/Overlay/IconArea/IconLabel,
	$Panel/Margin/HBox/SlotFree2/Overlay/IconArea/IconLabel,
	$Panel/Margin/HBox/SlotFree3/Overlay/IconArea/IconLabel,
]
@onready var _slot_icon_textures: Array[TextureRect] = [
	$Panel/Margin/HBox/SlotRod/Overlay/IconArea/IconTexture,
	$Panel/Margin/HBox/SlotBait/Overlay/IconArea/IconTexture,
	$Panel/Margin/HBox/SlotFree1/Overlay/IconArea/IconTexture,
	$Panel/Margin/HBox/SlotFree2/Overlay/IconArea/IconTexture,
	$Panel/Margin/HBox/SlotFree3/Overlay/IconArea/IconTexture,
]
@onready var _slot_qty_labels: Array[Label] = [
	$Panel/Margin/HBox/SlotRod/Overlay/QtyLabel,
	$Panel/Margin/HBox/SlotBait/Overlay/QtyLabel,
	$Panel/Margin/HBox/SlotFree1/Overlay/QtyLabel,
	$Panel/Margin/HBox/SlotFree2/Overlay/QtyLabel,
	$Panel/Margin/HBox/SlotFree3/Overlay/QtyLabel,
]

var _player_state: PlayerState


func bind_player_state(state: PlayerState) -> void:
	if _player_state != null and _player_state.slot_changed.is_connected(_on_slot_changed):
		_player_state.slot_changed.disconnect(_on_slot_changed)
	_player_state = state
	if _player_state == null:
		return
	for slot in _player_state.all_slots():
		_refresh_slot(slot)
	_player_state.slot_changed.connect(_on_slot_changed)


func _on_slot_changed(slot: PlayerState.InventorySlot) -> void:
	_refresh_slot(slot)


func _refresh_slot(slot: PlayerState.InventorySlot) -> void:
	var index: int = slot as int
	var item := _player_state.get_item(slot)
	_set_slot_icon(index, item)
	_set_slot_quantity(index, item, slot)


func _set_slot_icon(index: int, item: InventoryItem) -> void:
	var texture_rect := _slot_icon_textures[index]
	var label := _slot_icon_labels[index]

	var texture := ItemIcons.get_inventory_icon(item)
	if texture != null:
		texture_rect.texture = texture
		texture_rect.visible = true
		label.visible = false
		return

	texture_rect.texture = null
	texture_rect.visible = false

	if item == null:
		label.visible = false
		return

	label.visible = true
	label.text = item.get_icon()


func _set_slot_quantity(index: int, item: InventoryItem, slot: PlayerState.InventorySlot) -> void:
	var qty_label := _slot_qty_labels[index]
	if not _should_show_quantity(item, slot):
		qty_label.visible = false
		return

	qty_label.text = str(item.quantity)
	qty_label.visible = true


func _should_show_quantity(item: InventoryItem, slot: PlayerState.InventorySlot) -> bool:
	if item == null or slot == PlayerState.InventorySlot.ROD:
		return false
	match item.category:
		InventoryItem.Category.BAIT:
			return item.quantity > 0
		InventoryItem.Category.FISH:
			return item.quantity > 1
	return false
