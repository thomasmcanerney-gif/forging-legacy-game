class_name RegionData
extends RefCounted

var id: String
var display_name: String
var map_position: Vector2
var terrain: String
var road_quality: String
var travel_minutes_from_capital: float
var response_delay_minutes: float
var river_crossing: bool
var terrain_multiplier: float
var road_multiplier: float

func _init(
	region_id: String,
	name: String,
	position: Vector2,
	terrain_name: String,
	road: String,
	travel_minutes: float,
	response_minutes: float = 120.0,
	crosses_river: bool = false,
	terrain_mod: float = 1.0,
	road_mod: float = 1.0
) -> void:
	id = region_id
	display_name = name
	map_position = position
	terrain = terrain_name
	road_quality = road
	travel_minutes_from_capital = travel_minutes
	response_delay_minutes = response_minutes
	river_crossing = crosses_river
	terrain_multiplier = terrain_mod
	road_multiplier = road_mod

func get_summary() -> String:
	var hours: float = travel_minutes_from_capital / 60.0
	var crossing_text := " • River crossing" if river_crossing else ""
	return "%s • %s • Road: %s • Travel: %.1f hours%s" % [display_name, terrain, road_quality, hours, crossing_text]
