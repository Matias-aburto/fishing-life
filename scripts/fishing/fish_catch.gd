class_name FishCatch
extends RefCounted

var species_id: String
var display_name: String
var weight_kg: float


func get_weight_text() -> String:
	if weight_kg < 1.0:
		return "%d g" % roundi(weight_kg * 1000.0)
	return "%.2f kg" % weight_kg


func get_summary() -> String:
	return "%s (%s)" % [display_name, get_weight_text()]
