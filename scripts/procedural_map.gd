class_name ProceduralMap
extends Control

signal region_clicked(region_id: String)
signal kingdom_clicked(kingdom_id: String)

var kingdom_state: KingdomState
var world_view := false

func setup(state: KingdomState) -> void:
	kingdom_state = state
	queue_redraw()

func set_world_view(enabled: bool) -> void:
	world_view = enabled
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.49, 0.45, 0.29))
	if kingdom_state == null:
		return
	if world_view:
		_draw_world_view()
	else:
		_draw_realm_view()

func _draw_world_view() -> void:
	# A broad political view. These shapes are intentionally simple for the prototype;
	# later the same data can drive irregular borders and a larger world map.
	for kingdom_id in kingdom_state.get_world_kingdom_ids():
		var world_kingdom: WorldKingdomData = kingdom_state.get_world_kingdom(kingdom_id)
		if world_kingdom == null:
			continue
		var fill := Color(0.42, 0.39, 0.25, 0.70)
		if kingdom_id == "player":
			fill = Color(0.54, 0.45, 0.24, 0.82)
		elif world_kingdom.relation_to_player > 0:
			fill = Color(0.31, 0.43, 0.30, 0.75)
		else:
			fill = Color(0.46, 0.30, 0.25, 0.75)
		draw_colored_polygon(world_kingdom.territory, fill)
		for i in range(world_kingdom.territory.size()):
			draw_line(world_kingdom.territory[i], world_kingdom.territory[(i + 1) % world_kingdom.territory.size()], Color(0.18, 0.14, 0.09, 0.75), 2.0, true)

	var player_kingdom: WorldKingdomData = kingdom_state.get_world_kingdom("player")
	if player_kingdom != null:
		for kingdom_id in ["edrath", "tirath"]:
			var neighbor: WorldKingdomData = kingdom_state.get_world_kingdom(kingdom_id)
			if neighbor != null:
				draw_dashed_line(player_kingdom.world_position, neighbor.world_position, Color(0.31, 0.23, 0.14), 3.0, 12.0, true)

	for kingdom_id in kingdom_state.get_world_kingdom_ids():
		var world_kingdom: WorldKingdomData = kingdom_state.get_world_kingdom(kingdom_id)
		if world_kingdom == null:
			continue
		var capital_color := Color(0.76, 0.64, 0.31)
		if kingdom_id == "edrath":
			capital_color = Color(0.32, 0.56, 0.36)
		elif kingdom_id == "tirath":
			capital_color = Color(0.62, 0.33, 0.28)
		draw_circle(world_kingdom.world_position, 15.0, capital_color)
		draw_circle(world_kingdom.world_position, 5.0, Color(0.14, 0.11, 0.07))
		draw_string(ThemeDB.fallback_font, world_kingdom.world_position + Vector2(-72, 32), world_kingdom.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.10, 0.08, 0.05))
		draw_string(ThemeDB.fallback_font, world_kingdom.world_position + Vector2(-62, 50), "%s • %s %s" % [world_kingdom.capital_name, world_kingdom.ruler_title, world_kingdom.ruler_name], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.14, 0.11, 0.07))

func _draw_realm_view() -> void:
	_draw_territory("capital", Color(0.55, 0.48, 0.28, 0.22))
	_draw_territory("western_hills", Color(0.38, 0.31, 0.23, 0.24))
	_draw_territory("riverlands", Color(0.34, 0.49, 0.34, 0.20))
	_draw_territory("northern_march", Color(0.32, 0.37, 0.27, 0.22))

	for field_position in kingdom_state.field_positions:
		draw_circle(field_position, 34.0, Color(0.56, 0.53, 0.32))
		draw_circle(field_position + Vector2(22, 8), 24.0, Color(0.54, 0.50, 0.30))

	for mountain_position in kingdom_state.mountain_positions:
		var triangle := PackedVector2Array([mountain_position + Vector2(-13, 12), mountain_position + Vector2(0, -15), mountain_position + Vector2(14, 12)])
		draw_colored_polygon(triangle, Color(0.31, 0.29, 0.25))

	var pass_position: Vector2 = kingdom_state.mountain_pass_position
	draw_circle(pass_position, 8.0, Color(0.70, 0.61, 0.39))
	draw_string(ThemeDB.fallback_font, pass_position + Vector2(-28, -12), "Pass", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.16, 0.13, 0.08))

	if kingdom_state.river_points.size() > 1:
		draw_polyline(kingdom_state.river_points, Color(0.18, 0.42, 0.60), 14.0, true)

	for region_id in kingdom_state.get_region_ids():
		var region: RegionData = kingdom_state.get_region(region_id)
		if region == null:
			continue
		var route: PackedVector2Array = kingdom_state.get_route(region_id)
		if route.size() > 1:
			draw_polyline(route, Color(0.31, 0.23, 0.14), _road_width(region.road_quality), true)
		if kingdom_state.crossing_points.has(region_id):
			var crossing: Vector2 = kingdom_state.crossing_points[region_id]
			draw_line(crossing + Vector2(-15, 0), crossing + Vector2(15, 0), Color(0.82, 0.70, 0.45), 7.0, true)
			draw_string(ThemeDB.fallback_font, crossing + Vector2(-16, -14), "Ford", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.16, 0.13, 0.08))

	var capital: Vector2 = kingdom_state.capital_position
	draw_circle(capital, 15.0, Color(0.80, 0.68, 0.31))
	draw_string(ThemeDB.fallback_font, capital + Vector2(-38, 34), "The Capital", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.12, 0.10, 0.07))

	for region_id in kingdom_state.get_region_ids():
		var region: RegionData = kingdom_state.get_region(region_id)
		if region == null:
			continue
		var marker_color := Color(0.29, 0.39, 0.25)
		if region.id == "riverlands":
			marker_color = Color(0.27, 0.45, 0.40)
		elif region.id == "western_hills":
			marker_color = Color(0.45, 0.34, 0.25)
		draw_circle(region.map_position, 12.0, marker_color)
		draw_string(ThemeDB.fallback_font, region.map_position + Vector2(-45, 31), region.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.12, 0.10, 0.07))

func _draw_territory(id: String, fill: Color) -> void:
	if not kingdom_state.territory_polygons.has(id):
		return
	var polygon: PackedVector2Array = kingdom_state.territory_polygons[id]
	draw_colored_polygon(polygon, fill)
	for i in range(polygon.size()):
		draw_line(polygon[i], polygon[(i + 1) % polygon.size()], Color(0.24, 0.20, 0.13, 0.34), 1.5, true)

func _road_width(road_quality: String) -> float:
	match road_quality:
		"Basic road":
			return 6.0
		"Rough track":
			return 4.0
		"Poor road":
			return 3.0
		_:
			return 3.0

func _gui_input(event: InputEvent) -> void:
	if kingdom_state == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if world_view:
			for kingdom_id in kingdom_state.get_world_kingdom_ids():
				var world_kingdom: WorldKingdomData = kingdom_state.get_world_kingdom(kingdom_id)
				if world_kingdom != null and event.position.distance_to(world_kingdom.world_position) <= 36.0:
					kingdom_clicked.emit(kingdom_id)
					accept_event()
					return
		else:
			for region_id in kingdom_state.get_region_ids():
				var region: RegionData = kingdom_state.get_region(region_id)
				if region != null and event.position.distance_to(region.map_position) <= 32.0:
					region_clicked.emit(region_id)
					accept_event()
					return
