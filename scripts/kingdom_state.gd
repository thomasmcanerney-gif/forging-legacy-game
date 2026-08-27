class_name KingdomState
extends Node

const CAPITAL_ID := "capital"
const MAP_SIZE := Vector2(960, 340)

var regions: Dictionary = {}
var region_order: Array[String] = []
var capital_position := Vector2.ZERO
var river_points: PackedVector2Array = PackedVector2Array()
var mountain_positions: Array[Vector2] = []
var field_positions: Array[Vector2] = []
var map_seed := 271828

func _ready() -> void:
	generate_geography(map_seed)

func generate_geography(seed: int) -> void:
	map_seed = seed
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	river_points = PackedVector2Array()
	mountain_positions.clear()
	field_positions.clear()
	regions.clear()
	region_order.clear()

	var river_x: float = rng.randf_range(455.0, 610.0)
	river_points.append(Vector2(river_x, 0.0))
	for y in range(55, 341, 55):
		river_x += rng.randf_range(-40.0, 40.0)
		river_x = clampf(river_x, 385.0, 690.0)
		river_points.append(Vector2(river_x, float(y)))

	var mountain_y: float = rng.randf_range(72.0, 120.0)
	for i in range(12):
		var x: float = 285.0 + float(i) * 43.0 + rng.randf_range(-14.0, 14.0)
		var y: float = mountain_y + sin(float(i) * 0.75) * 24.0 + rng.randf_range(-10.0, 10.0)
		mountain_positions.append(Vector2(x, y))

	for i in range(7):
		field_positions.append(Vector2(rng.randf_range(105.0, 850.0), rng.randf_range(185.0, 312.0)))

	# The founder established the capital on open ground on the near side of the river.
	var lower_river_x: float = _river_x_at_y(240.0)
	capital_position = Vector2(clampf(lower_river_x - rng.randf_range(250.0, 315.0), 120.0, 300.0), rng.randf_range(220.0, 285.0))

	# Riverlands sits beside the lower river; its road is the best of the young kingdom.
	var riverlands_y: float = rng.randf_range(245.0, 300.0)
	var riverlands_x: float = _river_x_at_y(riverlands_y) + rng.randf_range(75.0, 125.0)
	_add_generated_region("riverlands", "Riverlands", Vector2(riverlands_x, riverlands_y), "Fertile river valley", "Basic road", 1.0, 0.78, 90.0)

	# Western Hills is anchored against the mountain belt and is slower to reach despite being closer.
	var western_position := mountain_positions[rng.randi_range(1, 4)] + Vector2(rng.randf_range(-30.0, 20.0), rng.randf_range(38.0, 62.0))
	_add_generated_region("western_hills", "Western Hills", western_position, "Rocky hill country", "Poor road", 1.45, 1.18, 180.0)

	# Northern March is deliberately beyond the river and near the frontier/mountains.
	var northern_y: float = rng.randf_range(78.0, 130.0)
	var northern_x: float = clampf(_river_x_at_y(northern_y) + rng.randf_range(245.0, 320.0), 760.0, 885.0)
	_add_generated_region("northern_march", "Northern March", Vector2(northern_x, northern_y), "Rugged frontier", "Rough track", 1.30, 1.08, 120.0)

func _add_generated_region(region_id: String, name: String, position: Vector2, terrain: String, road: String, terrain_mod: float, road_mod: float, response_minutes: float) -> void:
	var crosses_river := _route_crosses_river(capital_position, position)
	var travel_minutes := _calculate_travel_minutes(capital_position, position, terrain_mod, road_mod, crosses_river)
	_add_region(RegionData.new(region_id, name, position, terrain, road, travel_minutes, response_minutes, crosses_river, terrain_mod, road_mod))

func _calculate_travel_minutes(origin: Vector2, destination: Vector2, terrain_mod: float, road_mod: float, crosses_river: bool) -> float:
	# Effective travel time includes normal rest. The icon still moves steadily for readability.
	var distance_minutes: float = origin.distance_to(destination) * 1.55
	var total: float = distance_minutes * terrain_mod * road_mod
	if crosses_river:
		total += 120.0
	return maxf(total, 180.0)

func _route_crosses_river(origin: Vector2, destination: Vector2) -> bool:
	var river_x_origin: float = _river_x_at_y(origin.y)
	var river_x_destination: float = _river_x_at_y(destination.y)
	var origin_side: float = origin.x - river_x_origin
	var destination_side: float = destination.x - river_x_destination
	return origin_side * destination_side < 0.0

func _river_x_at_y(target_y: float) -> float:
	if river_points.is_empty():
		return MAP_SIZE.x * 0.55
	var closest := river_points[0]
	var best_distance: float = absf(closest.y - target_y)
	for point in river_points:
		var distance: float = absf(point.y - target_y)
		if distance < best_distance:
			closest = point
			best_distance = distance
	return closest.x

func _add_region(region: RegionData) -> void:
	regions[region.id] = region
	region_order.append(region.id)

func get_region(region_id: String) -> RegionData:
	return regions.get(region_id) as RegionData

func get_region_ids() -> Array[String]:
	return region_order.duplicate()
