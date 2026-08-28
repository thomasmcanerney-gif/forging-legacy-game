extends Node2D

@onready var player: Player = $Player
@onready var advisor: Area2D = $Advisor
@onready var game_time: GameTime = $GameTime
@onready var messenger_system: MessengerSystem = $MessengerSystem
@onready var kingdom_state: KingdomState = $KingdomState
@onready var prompt: Label = $UI/InteractionPrompt
@onready var dialogue_panel: PanelContainer = $UI/DialoguePanel
@onready var dialogue_text: Label = $UI/DialoguePanel/MarginContainer/DialogueText
@onready var date_label: Label = $UI/DateLabel
@onready var speed_label: Label = $UI/SpeedLabel
@onready var map_panel: Panel = $UI/MapPanel
@onready var map_title: Label = $UI/MapPanel/MapTitle
@onready var map_help: Label = $UI/MapPanel/MapHelp
@onready var map_status: Label = $UI/MapPanel/MapStatus
@onready var selected_region_label: Label = $UI/MapPanel/SelectedRegion
@onready var procedural_map: ProceduralMap = $UI/MapPanel/ProceduralMap
@onready var messenger_marker: Polygon2D = $UI/MapPanel/ProceduralMap/Messenger

var dialogue_open := false
var map_open := false
var world_view := false
var selected_region_index := 0
var selected_kingdom_id := "player"

func _ready() -> void:
	dialogue_panel.visible = false
	prompt.visible = false
	map_panel.visible = false
	messenger_marker.visible = false
	procedural_map.setup(kingdom_state)
	procedural_map.region_clicked.connect(_select_region_by_id)
	procedural_map.kingdom_clicked.connect(_select_kingdom_by_id)
	game_time.time_changed.connect(_on_time_changed)
	game_time.speed_changed.connect(_on_speed_changed)
	messenger_system.journey_started.connect(_on_journey_started)
	messenger_system.journey_progress.connect(_on_journey_progress)
	messenger_system.phase_changed.connect(_on_messenger_phase_changed)
	messenger_system.journey_completed.connect(_on_journey_completed)
	_on_time_changed(game_time.get_display_text())
	_on_speed_changed(game_time.get_speed_name())
	_update_map_mode_text()
	_update_selected_region_display()

func _process(delta: float) -> void:
	messenger_system.advance(delta, game_time.speed_multiplier)
	var close_enough: bool = player.global_position.distance_to(advisor.global_position) < 90.0
	prompt.visible = close_enough and not dialogue_open and not map_open
	if close_enough and Input.is_action_just_pressed("interact") and not map_open:
		_set_dialogue_open(not dialogue_open)
		if dialogue_open:
			dialogue_text.text = "My king, our borders do not end the world. Edrath lies to the west and Tirath to the east.\n\nOpen the map with M. Press V to change between the realm and the wider world."
	if dialogue_open and Input.is_action_just_pressed("ui_cancel"):
		_set_dialogue_open(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				game_time.set_speed(0.0)
			KEY_2:
				game_time.set_speed(1.0)
			KEY_3:
				game_time.set_speed(10.0)
			KEY_4:
				game_time.set_speed(100.0)
			KEY_M:
				_toggle_map()
			KEY_V:
				if map_open:
					_toggle_world_view()
			KEY_T:
				if map_open and not world_view and not messenger_system.active:
					_cycle_selected_region()
			KEY_O:
				if map_open and not world_view:
					_send_regional_order()
			KEY_ESCAPE:
				if map_open:
					_set_map_open(false)

func _toggle_map() -> void:
	_set_map_open(not map_open)

func _set_map_open(open: bool) -> void:
	map_open = open
	map_panel.visible = open
	if open and dialogue_open:
		_set_dialogue_open(false)
	player.set_movement_enabled(not open and not dialogue_open)
	prompt.visible = false
	if open:
		_update_map_mode_text()
		if world_view:
			_update_selected_kingdom_display()
		elif not messenger_system.active:
			_update_selected_region_display()

func _toggle_world_view() -> void:
	world_view = not world_view
	procedural_map.set_world_view(world_view)
	messenger_marker.visible = messenger_system.active and not world_view
	_update_map_mode_text()
	if world_view:
		_update_selected_kingdom_display()
	else:
		_update_selected_region_display()

func _update_map_mode_text() -> void:
	if world_view:
		map_title.text = "THE THREE KINGDOMS"
		map_help.text = "Click a capital • V: Realm view • Esc/M: Close"
	else:
		map_title.text = "THE YOUNG KINGDOM"
		map_help.text = "Click regional center • O: Send order • V: World view • Esc/M: Close"

func _cycle_selected_region() -> void:
	var ids: Array[String] = kingdom_state.get_region_ids()
	if ids.is_empty():
		return
	selected_region_index = (selected_region_index + 1) % ids.size()
	_update_selected_region_display()

func _select_region_by_id(region_id: String) -> void:
	if messenger_system.active:
		map_status.text = "A royal messenger is already carrying a matter. Wait for the response."
		return
	var ids: Array[String] = kingdom_state.get_region_ids()
	var index: int = ids.find(region_id)
	if index == -1:
		return
	selected_region_index = index
	_update_selected_region_display()

func _select_kingdom_by_id(kingdom_id: String) -> void:
	selected_kingdom_id = kingdom_id
	_update_selected_kingdom_display()

func _get_selected_region() -> RegionData:
	var ids: Array[String] = kingdom_state.get_region_ids()
	if ids.is_empty():
		return null
	return kingdom_state.get_region(ids[selected_region_index])

func _update_selected_region_display() -> void:
	var region: RegionData = _get_selected_region()
	if region == null:
		selected_region_label.text = "No region selected"
		return
	selected_region_label.text = "Selected: %s" % region.get_summary()
	map_status.text = "Selected %s. Roads use crossings and passes. Press V for the wider world." % region.display_name

func _update_selected_kingdom_display() -> void:
	var world_kingdom: WorldKingdomData = kingdom_state.get_world_kingdom(selected_kingdom_id)
	if world_kingdom == null:
		selected_region_label.text = "No kingdom selected"
		map_status.text = "Click a capital to inspect a neighboring kingdom."
		return
	selected_region_label.text = "Selected: %s" % world_kingdom.get_summary()
	map_status.text = world_kingdom.disposition

func _send_regional_order() -> void:
	if messenger_system.active:
		map_status.text = "A royal messenger is already carrying a matter."
		return
	var region: RegionData = _get_selected_region()
	if region != null:
		messenger_system.start_journey(region)

func _set_dialogue_open(open: bool) -> void:
	dialogue_open = open
	dialogue_panel.visible = open
	player.set_movement_enabled(not open and not map_open)
	prompt.visible = false

func _on_time_changed(display_text: String) -> void:
	date_label.text = display_text

func _on_speed_changed(speed_name: String) -> void:
	speed_label.text = "Time: %s   [1 Pause • 2 1x • 3 10x • 4 100x]" % speed_name

func _on_journey_started(target_id: String) -> void:
	messenger_marker.visible = not world_view
	messenger_marker.position = kingdom_state.capital_position
	var region: RegionData = kingdom_state.get_region(target_id)
	if region != null and not world_view:
		selected_region_label.text = "Active route: %s" % region.get_summary()

func _on_journey_progress(progress: float, returning: bool, target_id: String) -> void:
	var route: PackedVector2Array = kingdom_state.get_route(target_id)
	if route.size() < 2:
		return
	var route_progress: float = 1.0 - progress if returning else progress
	messenger_marker.position = _position_along_route(route, route_progress)

func _position_along_route(route: PackedVector2Array, progress: float) -> Vector2:
	progress = clampf(progress, 0.0, 1.0)
	var total_length: float = 0.0
	for i in range(route.size() - 1):
		total_length += route[i].distance_to(route[i + 1])
	var target_distance: float = total_length * progress
	var traveled: float = 0.0
	for i in range(route.size() - 1):
		var segment_length: float = route[i].distance_to(route[i + 1])
		if traveled + segment_length >= target_distance:
			var segment_progress: float = (target_distance - traveled) / maxf(segment_length, 0.001)
			return route[i].lerp(route[i + 1], segment_progress)
		traveled += segment_length
	return route[route.size() - 1]

func _on_messenger_phase_changed(text: String) -> void:
	if not world_view:
		map_status.text = text

func _on_journey_completed(_target_id: String) -> void:
	messenger_marker.position = kingdom_state.capital_position
	messenger_marker.visible = false
	if not world_view:
		_update_selected_region_display()
