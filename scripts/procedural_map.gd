class_name ProceduralMap
extends Control

signal region_clicked(region_id: String)

var kingdom_state: KingdomState

func setup(state: KingdomState) -> void:
	kingdom_state = state
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.49, 0.45, 0.29))
	if kingdom_state == null:
		return

	for p in kingdom_state.field_positions:
		draw_circle(p, 34.0, Color(0.56, 0.53, 0.32))
		draw_circle(p + Vector2(22, 8), 24.0, Color(0.54, 0.50, 0.30))

	for p in kingdom_state.mountain_positions:
		var tri := PackedVector2Array([p + Vector2(-13, 12), p + Vector2(0, -15), p + Vector2(14, 12)])
		draw_colored_polygon(tri, Color(0.31, 0.29, 0.25))

	if kingdom_state.river_points.size() > 1:
		draw_polyline(kingdom_state.river_points, Color(0.18, 0.42, 0.60), 14.0, true)

	var capital := kingdom_state.capital_position
	for region_id in kingdom_state.get_region_ids():
		var region := kingdom_state.get_region(region_id)
		if region == null:
			continue
		var midpoint := capital.lerp(region.map_position, 0.5)
		midpoint += Vector2(_seeded_offset(region_id, -18.0, 18.0), _seeded_offset(region_id + "y", -14.0, 14.0))
		var road_width := _road_width(region.road_quality)
		draw_polyline(PackedVector2Array([capital, midpoint, region.map_position]), Color(0.31, 0.23, 0.14), road_width, true)
		if region.river_crossing:
			var crossing := _approximate_crossing(capital, region.map_position)
			draw_line(crossing + Vector2(-9, -4), crossing + Vector2(9, 4), Color(0.77, 0.66, 0.43), 5.0, true)

	draw_circle(capital, 15.0, Color(0.80, 0.68, 0.31))
	draw_string(ThemeDB.fallback_font, capital + Vector2(-38, 34), "The Capital", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.12, 0.10, 0.07))

	for region_id in kingdom_state.get_region_ids():
		var region := kingdom_state.get_region(region_id)
		if region == null:
			continue
		var marker_color := Color(0.29, 0.39, 0.25)
		if region.id == "riverlands":
			marker_color = Color(0.27, 0.45, 0.40)
		elif region.id == "western_hills":
			marker_color = Color(0.45, 0.34, 0.25)
		draw_circle(region.map_position, 12.0, marker_color)
		draw_string(ThemeDB.fallback_font, region.map_position + Vector2(-45, 31), region.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.12, 0.10, 0.07))

func _road_width(road_quality: String) -> float:
	match road_quality:
		"Basic road": return 6.0
		"Rough track": return 4.0
		"Poor road": return 3.0
		_: return 3.0

func _seeded_offset(key: String, minimum: float, maximum: float) -> float:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = kingdom_state.map_seed + key.hash()
	return local_rng.randf_range(minimum, maximum)

func _approximate_crossing(origin: Vector2, destination: Vector2) -> Vector2:
	# For this prototype, find the point along the direct route closest to the river belt.
	var best := origin.lerp(destination, 0.5)
	var best_distance := 100000.0
	for river_point in kingdom_state.river_points:
		var t: float = clampf((river_point.y - origin.y) / maxf(destination.y - origin.y, 0.001), 0.0, 1.0)
		var route_point := origin.lerp(destination, t)
		var distance: float = route_point.distance_to(river_point)
		if distance < best_distance:
			best = route_point
			best_distance = distance
	return best

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
