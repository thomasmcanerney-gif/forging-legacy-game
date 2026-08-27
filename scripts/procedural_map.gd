class_name ProceduralMap
extends Control

signal region_clicked(region_id: String)
var kingdom_state: KingdomState

func setup(state: KingdomState) -> void:
	kingdom_state = state
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.49, 0.45, 0.29))
	if kingdom_state == null: return

	# Faint territories make the realm readable without turning the map into a board game.
	_draw_territory("capital", Color(0.55, 0.48, 0.28, 0.22))
	_draw_territory("western_hills", Color(0.38, 0.31, 0.23, 0.24))
	_draw_territory("riverlands", Color(0.34, 0.49, 0.34, 0.20))
	_draw_territory("northern_march", Color(0.32, 0.37, 0.27, 0.22))

	for p in kingdom_state.field_positions:
		draw_circle(p, 34.0, Color(0.56, 0.53, 0.32))
		draw_circle(p + Vector2(22, 8), 24.0, Color(0.54, 0.50, 0.30))

	for p in kingdom_state.mountain_positions:
		var tri := PackedVector2Array([p + Vector2(-13, 12), p + Vector2(0, -15), p + Vector2(14, 12)])
		draw_colored_polygon(tri, Color(0.31, 0.29, 0.25))

	# Mark the usable mountain pass before roads so the route visibly threads it.
	var pass := kingdom_state.mountain_pass_position
	draw_circle(pass, 8.0, Color(0.70, 0.61, 0.39))
	draw_string(ThemeDB.fallback_font, pass + Vector2(-28, -12), "Pass", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.16, 0.13, 0.08))

	if kingdom_state.river_points.size() > 1:
		draw_polyline(kingdom_state.river_points, Color(0.18, 0.42, 0.60), 14.0, true)

	for region_id in kingdom_state.get_region_ids():
		var region := kingdom_state.get_region(region_id)
		if region == null: continue
		var route := kingdom_state.get_route(region_id)
		if route.size() > 1:
			draw_polyline(route, Color(0.31, 0.23, 0.14), _road_width(region.road_quality), true)
		if kingdom_state.crossing_points.has(region_id):
			var crossing: Vector2 = kingdom_state.crossing_points[region_id]
			# A short pale bridge/ford line sits across the blue river.
			draw_line(crossing + Vector2(-15, 0), crossing + Vector2(15, 0), Color(0.82, 0.70, 0.45), 7.0, true)
			draw_string(ThemeDB.fallback_font, crossing + Vector2(-16, -14), "Ford", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.16, 0.13, 0.08))

	var capital := kingdom_state.capital_position
	draw_circle(capital, 15.0, Color(0.80, 0.68, 0.31))
	draw_string(ThemeDB.fallback_font, capital + Vector2(-38, 34), "The Capital", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.12, 0.10, 0.07))

	for region_id in kingdom_state.get_region_ids():
		var region := kingdom_state.get_region(region_id)
		if region == null: continue
		var marker_color := Color(0.29, 0.39, 0.25)
		if region.id == "riverlands": marker_color = Color(0.27, 0.45, 0.40)
		elif region.id == "western_hills": marker_color = Color(0.45, 0.34, 0.25)
		draw_circle(region.map_position, 12.0, marker_color)
		draw_string(ThemeDB.fallback_font, region.map_position + Vector2(-45, 31), region.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.12, 0.10, 0.07))

func _draw_territory(id: String, fill: Color) -> void:
	if not kingdom_state.territory_polygons.has(id): return
	var polygon: PackedVector2Array = kingdom_state.territory_polygons[id]
	draw_colored_polygon(polygon, fill)
	for i in range(polygon.size()):
		draw_line(polygon[i], polygon[(i + 1) % polygon.size()], Color(0.24, 0.20, 0.13, 0.34), 1.5, true)

func _road_width(road_quality: String) -> float:
	match road_quality:
		"Basic road": return 6.0
		"Rough track": return 4.0
		"Poor road": return 3.0
		_: return 3.0

func _gui_input(event: InputEvent) -> void:
	if kingdom_state == null: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for region_id in kingdom_state.get_region_ids():
			var region := kingdom_state.get_region(region_id)
			if region != null and event.position.distance_to(region.map_position) <= 32.0:
				region_clicked.emit(region_id)
				accept_event()
				return
