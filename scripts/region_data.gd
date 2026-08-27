class_name RegionData
extends RefCounted

var id: String
var display_name: String
var map_position: Vector2
var terrain: String
var road_quality: String
var travel_minutes_from_capital: float
var response_delay_minutes: float

func _init(
	region_id: String,
	name: String,
	position: Vector2,
	terrain_name: String,
	road: String,
	travel_minutes: float,
	response_minutes: float = 120.0
) -> void:
	id = region_id
	display_name = name
	map_position = position
	terrain = terrain_name
	road_quality = road
	travel_minutes_from_capital = travel_minutes
	response_delay_minutes = response_minutes

func get_summary() -> String:
	var hours: float = travel_minutes_from_capital / 60.0
	return "%s • %s • Road: %s • Travel: %.1f hours" % [display_name, terrain, road_quality, hours]
