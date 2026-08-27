class_name ProceduralMap
extends Control

signal region_clicked(region_id: String)

@export var map_seed: int = 271828

var kingdom_state: KingdomState
var rng := RandomNumberGenerator.new()
var river_points: PackedVector2Array = PackedVector2Array()
var mountain_positions: Array[Vector2] = []
var field_positions: Array[Vector2] = []

func setup(state: KingdomState) -> void:
	kingdom_state = state
	rng.seed = map_seed
	_generate_features()
	queue_redraw()

func regenerate() -> void:
	map_seed += 1
	rng.seed = map_seed
	_generate_features()
	queue_redraw()

func _generate_features() -> void:
	river_points = PackedVector2Array()
	mountain_positions.clear()
	field_positions.clear()

	var river_x := rng.randf_range(470.0, 610.0)
	river_points.append(Vector2(river_x, 0.0))
	for y in range(55, 341, 55):
		river_x += rng.randf_range(-45.0, 45.0)
		river_points.append(Vector2(clampf(river_x, 380.0, 680.0), float(y)))
	river_points.append(Vector2(clampf(river_x + rng.randf_range(-30.0, 30.0), 380.0, 680.0), 340.0))

	for i in range(11):
		mountain_positions.append(Vector2(rng.randf_range(330.0, 760.0), rng.randf_range(45.0, 150.0)))
	for i in range(6):
		field_positions.append(Vector2(rng.randf_range(120.0, 850.0), rng.randf_range(180.0, 315.0)))

func _draw() -> void:
	# Land parchment.
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.49, 0.45, 0.29))

	# Open fields: deliberately sparse, broad settled patches rather than villages.
	for p in field_positions:
		draw_circle(p, 34.0, Color(0.56, 0.53, 0.32))
		draw_circle(p + Vector2(22, 8), 24.0, Color(0.54, 0.50, 0.30))

	# Mountains form a loose natural northern boundary.
	for p in mountain_positions:
		var tri := PackedVector2Array([p + Vector2(-13, 12), p + Vector2(0, -15), p + Vector2(14, 12)])
		draw_colored_polygon(tri, Color(0.31, 0.29, 0.25))

	# Main river reaches both edges of the map.
	if river_points.size() > 1:
		draw_polyline(river_points, Color(0.18, 0.42, 0.60), 14.0, true)

	if kingdom_state == null:
		return

	var capital := Vector2(255, 235)
	# Sparse roads: only direct routes needed by the young kingdom.
	for region_id in kingdom_state.get_region_ids():
		var region := kingdom_state.get_region(region_id)
		if region == null:
			continue
		var midpoint := capital.lerp(region.map_position, 0.5)
		midpoint += Vector2(rng_offset(region_id, -18.0, 18.0), rng_offset(region_id + "y", -14.0, 14.0))
		draw_polyline(PackedVector2Array([capital, midpoint, region.map_position]), Color(0.31, 0.23, 0.14), 4.0, true)

	# Capital.
	draw_circle(capital, 15.0, Color(0.80, 0.68, 0.31))
	draw_string(ThemeDB.fallback_font, capital + Vector2(-38, 34), "The Capital", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.12, 0.10, 0.07))

	for region_id in kingdom_state.get_region_ids():
		var region := kingdom_state.get_region(region_id)
		if region == null:
			continue
		draw_circle(region.map_position, 12.0, Color(0.29, 0.39, 0.25))
		draw_string(ThemeDB.fallback_font, region.map_position + Vector2(-45, 31), region.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.12, 0.10, 0.07))

func rng_offset(key: String, minimum: float, maximum: float) -> float:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = map_seed + key.hash()
	return local_rng.randf_range(minimum, maximum)

func _gui_input(event: InputEvent) -> void:
	if kingdom_state == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for region_id in kingdom_state.get_region_ids():
			var region := kingdom_state.get_region(region_id)
			if region != null and event.position.distance_to(region.map_position) <= 32.0:
				region_clicked.emit(region_id)
				accept_event()
				return
