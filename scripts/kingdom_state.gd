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
var territory_polygons: Dictionary = {}
var route_points: Dictionary = {}
var crossing_points: Dictionary = {}
var mountain_pass_position := Vector2.ZERO
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
	territory_polygons.clear()
	route_points.clear()
	crossing_points.clear()
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
	mountain_pass_position = mountain_positions[5] + Vector2(0.0, 24.0)

	for i in range(7):
		field_positions.append(Vector2(rng.randf_range(105.0, 850.0), rng.randf_range(185.0, 312.0)))

	var lower_river_x: float = _river_x_at_y(240.0)
	capital_position = Vector2(clampf(lower_river_x - rng.randf_range(250.0, 315.0), 120.0, 300.0), rng.randf_range(220.0, 285.0))

	var riverlands_y: float = rng.randf_range(245.0, 300.0)
	var riverlands_x: float = _river_x_at_y(riverlands_y) + rng.randf_range(75.0, 125.0)
	_add_generated_region("riverlands", "Riverlands", Vector2(riverlands_x, riverlands_y), "Fertile river valley", "Basic road", 1.0, 0.78, 90.0)

	var western_position := mountain_positions[rng.randi_range(1, 4)] + Vector2(rng.randf_range(-30.0, 20.0), rng.randf_range(38.0, 62.0))
	_add_generated_region("western_hills", "Western Hills", western_position, "Rocky hill country", "Poor road", 1.45, 1.18, 180.0)

	var northern_y: float = rng.randf_range(78.0, 130.0)
	var northern_x: float = clampf(_river_x_at_y(northern_y) + rng.randf_range(245.0, 320.0), 760.0, 885.0)
	_add_generated_region("northern_march", "Northern March", Vector2(northern_x, northern_y), "Rugged frontier", "Rough track", 1.30, 1.08, 120.0)

	_build_routes()
	_build_territories()

func _add_generated_region(region_id: String, name: String, position: Vector2, terrain: String, road: String, terrain_mod: float, road_mod: float, response_minutes: float) -> void:
	var crosses_river := _route_crosses_river(capital_position, position)
	_add_region(RegionData.new(region_id, name, position, terrain, road, 180.0, response_minutes, crosses_river, terrain_mod, road_mod))

func _build_routes() -> void:
	for region_id in get_region_ids():
		var region := get_region(region_id)
		if region == null:
			continue
		var points := PackedVector2Array([capital_position])
		if region.id == "western_hills":
			points.append(mountain_pass_position)
		elif region.river_crossing:
			var crossing := _find_crossing_for_route(capital_position, region.map_position)
			crossing_points[region.id] = crossing
			points.append(crossing + Vector2(-18.0, 0.0))
			points.append(crossing + Vector2(18.0, 0.0))
		points.append(region.map_position)
		route_points[region.id] = points
		region.travel_minutes_from_capital = _calculate_route_minutes(points, region.terrain_modifier, region.road_modifier, region.river_crossing)

func _calculate_route_minutes(points: PackedVector2Array, terrain_mod: float, road_mod: float, crosses_river: bool) -> float:
	var route_distance := 0.0
	for i in range(points.size() - 1):
		route_distance += points[i].distance_to(points[i + 1])
	var total: float = route_distance * 1.55 * terrain_mod * road_mod
	if crosses_river:
		total += 120.0
	return maxf(total, 180.0)

func _find_crossing_for_route(origin: Vector2, destination: Vector2) -> Vector2:
	var desired_y: float = clampf(origin.lerp(destination, 0.55).y, 40.0, 310.0)
	return Vector2(_river_x_at_y(desired_y), desired_y)

func _build_territories() -> void:
	var capital := capital_position
	var west := get_region("western_hills").map_position
	var river := get_region("riverlands").map_position
	var north := get_region("northern_march").map_position
	territory_polygons["capital"] = PackedVector2Array([
		Vector2(55, 175), Vector2(330, 155), Vector2(430, 225), Vector2(400, 340), Vector2(55, 340)
	])
	territory_polygons["western_hills"] = PackedVector2Array([
		Vector2(55, 0), Vector2(500, 0), Vector2(455, 155), Vector2(330, 155), Vector2(55, 175)
	])
	territory_polygons["riverlands"] = PackedVector2Array([
		Vector2(430, 225), Vector2(960, 190), Vector2(960, 340), Vector2(400, 340)
	])
	territory_polygons["northern_march"] = PackedVector2Array([
		Vector2(500, 0), Vector2(960, 0), Vector2(960, 190), Vector2(430, 225), Vector2(455, 155)
	])

func _route_crosses_river(origin: Vector2, destination: Vector2) -> bool:
	var origin_side: float = origin.x - _river_x_at_y(origin.y)
	var destination_side: float = destination.x - _river_x_at_y(destination.y)
	return origin_side * destination_side < 0.0

func _river_x_at_y(target_y: float) -> float:
	if river_points.is_empty(): return MAP_SIZE.x * 0.55
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

func get_route(region_id: String) -> PackedVector2Array:
	return route_points.get(region_id, PackedVector2Array()) as PackedVector2Array
