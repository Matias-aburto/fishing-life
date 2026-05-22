class_name FishPricing
extends RefCounted

# Precio base por kg; el peso es el factor principal.
const COINS_PER_KG := 10
const MIN_PRICE := 2

const SPECIES_VALUE: Dictionary = {
	"trucha_arcoiris": 1.25,
	"trucha_fario": 1.2,
	"pejerrey": 0.85,
	"carpa": 1.0,
	"perca": 0.95,
}


static func get_sell_price(catch: FishCatch) -> int:
	if catch == null:
		return 0
	var multiplier: float = SPECIES_VALUE.get(catch.species_id, 1.0)
	var raw := catch.weight_kg * COINS_PER_KG * multiplier
	return maxi(MIN_PRICE, int(round(raw)))
