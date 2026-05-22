extends Control

signal closed

const BAIT_PACK_AMOUNT := 5
const BAIT_PACK_PRICE := 12

@onready var _coin_icon: TextureRect = $Panel/Margin/VBox/CoinsRow/CoinIcon
@onready var _coins_label: Label = $Panel/Margin/VBox/CoinsRow/CoinsLabel
@onready var _buy_icon: TextureRect = $Panel/Margin/VBox/BuyRow/BuyIcon
@onready var _message_label: Label = $Panel/Margin/VBox/MessageLabel
@onready var _buy_button: Button = $Panel/Margin/VBox/BuyButton
@onready var _sell_fish_icon: TextureRect = $Panel/Margin/VBox/SellSection/SellFishRow/SellFishIcon
@onready var _sell_fish_label: Label = $Panel/Margin/VBox/SellSection/SellFishRow/SellFishLabel
@onready var _sell_button: Button = $Panel/Margin/VBox/SellSection/SellButton
@onready var _close_button: Button = $Panel/Margin/VBox/CloseButton

var _is_open := false
var _bait_preview := InventoryItem.create_bait(1)
var _player_state: PlayerState


func _ready() -> void:
	visible = false
	_setup_static_icons()
	_buy_button.pressed.connect(_on_buy_pressed)
	_sell_button.pressed.connect(_on_sell_pressed)
	_close_button.pressed.connect(_on_close_pressed)


func bind_player_state(state: PlayerState) -> void:
	if _player_state != null:
		if _player_state.money_changed.is_connected(_refresh_labels):
			_player_state.money_changed.disconnect(_refresh_labels)
		if _player_state.slot_changed.is_connected(_on_inventory_slot_changed):
			_player_state.slot_changed.disconnect(_on_inventory_slot_changed)
	_player_state = state
	if _player_state == null:
		return
	_player_state.money_changed.connect(_refresh_labels)
	_player_state.slot_changed.connect(_on_inventory_slot_changed)


func _setup_static_icons() -> void:
	var coin := UiSprites.get_coin_icon()
	if coin != null:
		_coin_icon.texture = coin

	var bait_tex := ItemIcons.get_inventory_icon(_bait_preview)
	if bait_tex != null:
		_buy_icon.texture = bait_tex


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _is_open


func open_shop() -> void:
	_is_open = true
	visible = true
	_message_label.text = ""
	_refresh_labels()


func close_shop() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	closed.emit()


func _on_inventory_slot_changed(slot: PlayerState.InventorySlot) -> void:
	if _player_state.is_free_slot(slot) and _is_open:
		_refresh_labels()


func _refresh_labels() -> void:
	if _player_state == null:
		return
	_coins_label.text = str(_player_state.coins)
	_buy_button.text = "Comprar x%d — %d $" % [BAIT_PACK_AMOUNT, BAIT_PACK_PRICE]
	_refresh_sell_section()


func _refresh_sell_section() -> void:
	var slot_index := _player_state.get_first_fish_slot()
	if slot_index < 0:
		_sell_fish_icon.visible = false
		_sell_fish_label.text = "Sin peces para vender."
		_sell_button.text = "Vender captura"
		_sell_button.disabled = true
		return

	var fish := _player_state.get_fish_in_slot(slot_index as PlayerState.InventorySlot)
	var price := FishPricing.get_sell_price(fish)
	var texture := FishIcons.get_icon(fish.species_id)

	if texture != null:
		_sell_fish_icon.texture = texture
		_sell_fish_icon.visible = true
	else:
		_sell_fish_icon.visible = false

	_sell_fish_label.text = "%s\nPrecio: %d $ (según peso)" % [fish.get_summary(), price]
	_sell_button.text = "Vender por %d $" % price
	_sell_button.disabled = false


func _on_buy_pressed() -> void:
	if _player_state == null:
		return
	if not _player_state.can_afford(BAIT_PACK_PRICE):
		_message_label.text = "No tienes suficientes monedas."
		return
	if not _player_state.spend(BAIT_PACK_PRICE):
		_message_label.text = "No tienes suficientes monedas."
		return
	_player_state.add_bait(BAIT_PACK_AMOUNT)
	_message_label.text = "¡Compraste %d carnadas!" % BAIT_PACK_AMOUNT
	_refresh_labels()


func _on_sell_pressed() -> void:
	if _player_state == null:
		return
	var price := _player_state.sell_first_fish()
	if price < 0:
		_message_label.text = "No tienes peces para vender."
		_refresh_sell_section()
		return
	_player_state.add_coins(price)
	_message_label.text = "¡Vendiste tu captura por %d $!" % price
	_refresh_labels()


func _on_close_pressed() -> void:
	close_shop()
