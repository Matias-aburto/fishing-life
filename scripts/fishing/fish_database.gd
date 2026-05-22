extends Node

# Rangos orientativos para río/lago del sur de Chile (Loncoche y zona).
const SPECIES: Dictionary = {
	"trucha_arcoiris": {
		"name": "Trucha arcoíris",
		"min_kg": 0.25,
		"max_kg": 4.20,
		"skew": 2.2,
		"is_trout": true,
	},
	"trucha_fario": {
		"name": "Trucha fario",
		"min_kg": 0.22,
		"max_kg": 4.80,
		"skew": 2.1,
		"is_trout": true,
	},
	"pejerrey": {
		"name": "Pejerrey",
		"min_kg": 0.07,
		"max_kg": 0.45,
		"skew": 2.6,
	},
	"carpa": {
		"name": "Carpa",
		"min_kg": 0.85,
		"max_kg": 8.50,
		"skew": 2.0,
	},
	"perca": {
		"name": "Perca",
		"min_kg": 0.15,
		"max_kg": 1.20,
		"skew": 2.4,
	},
}

const TROUT_HEAVY_KG := 1.0
# Probabilidad de que una trucha pese más de 1 kg (antes del minijuego).
const TROUT_HEAVY_WEIGHT_CHANCE := 0.20


func is_trout(species_id: String) -> bool:
	return SPECIES.get(species_id, {}).get("is_trout", false)


func pick_random_species_id(rng: RandomNumberGenerator) -> String:
	var keys: Array = SPECIES.keys()
	return keys[rng.randi_range(0, keys.size() - 1)]


func get_species_name(species_id: String) -> String:
	return SPECIES[species_id].name


func roll_catch(species_id: String, rng: RandomNumberGenerator) -> FishCatch:
	var spec: Dictionary = SPECIES[species_id]
	return build_catch(species_id, _roll_weight(species_id, spec, rng))


func build_catch(species_id: String, weight_kg: float) -> FishCatch:
	var spec: Dictionary = SPECIES[species_id]
	var fish := FishCatch.new()
	fish.species_id = species_id
	fish.display_name = spec.name
	fish.weight_kg = weight_kg
	return fish


func get_trout_escape_chance(weight_kg: float) -> float:
	# Trucha > 1 kg: chance extra de perderla tras el minijuego (se escapa al sacarla).
	if weight_kg <= TROUT_HEAVY_KG:
		return 0.0
	var excess: float = weight_kg - TROUT_HEAVY_KG
	return clampf(excess * 0.12, 0.08, 0.40)


func _roll_weight(species_id: String, spec: Dictionary, rng: RandomNumberGenerator) -> float:
	if is_trout(species_id):
		return _roll_trout_weight(spec, rng)

	var t := pow(rng.randf(), spec.get("skew", 2.0))
	var weight := lerpf(spec.min_kg, spec.max_kg, t)

	if rng.randf() < 0.07:
		weight = lerpf(weight, spec.max_kg, rng.randf_range(0.55, 1.0))

	return _round_weight(clampf(weight, spec.min_kg, spec.max_kg))


func _roll_trout_weight(spec: Dictionary, rng: RandomNumberGenerator) -> float:
	var weight: float

	if rng.randf() > TROUT_HEAVY_WEIGHT_CHANCE:
		var t_light := pow(rng.randf(), 3.0)
		var max_light := minf(TROUT_HEAVY_KG - 0.01, spec.max_kg)
		weight = lerpf(spec.min_kg, max_light, t_light)
	else:
		var t_heavy := pow(rng.randf(), 2.4)
		weight = lerpf(TROUT_HEAVY_KG, spec.max_kg, t_heavy)
		if rng.randf() < 0.04:
			weight = lerpf(weight, spec.max_kg, rng.randf_range(0.6, 1.0))

	return _round_weight(clampf(weight, spec.min_kg, spec.max_kg))


func _round_weight(weight: float) -> float:
	if weight < 1.0:
		return float(snappedi(roundi(weight * 1000.0), 5)) / 1000.0
	return floorf(weight * 100.0) / 100.0
