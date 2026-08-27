extends Node2D

@onready var player: Player = $Player
@onready var advisor: Area2D = $Advisor
@onready var game_time: GameTime = $GameTime
@onready var messenger_system: MessengerSystem = $MessengerSystem
@onready var prompt: Label = $UI/InteractionPrompt
@onready var dialogue_panel: PanelContainer = $UI/DialoguePanel
@onready var dialogue_text: Label = $UI/DialoguePanel/MarginContainer/DialogueText
@onready var date_label: Label = $UI/DateLabel
@onready var speed_label: Label = $UI/SpeedLabel
@onready var map_panel: Panel = $UI/MapPanel
@onready var map_status: Label = $UI/MapPanel/MapStatus
@onready var messenger_marker: Polygon2D = $UI/MapPanel/Messenger

const CAPITAL_POS := Vector2(255, 285)
const NORTHERN_MARCH_POS := Vector2(805, 175)

var dialogue_open := false
var map_open := false

func _ready() -> void:
	dialogue_panel.visible = false
	prompt.visible = false
	map_panel.visible = false
	messenger_marker.visible = false

	game_time.time_changed.connect(_on_time_changed)
	game_time.speed_changed.connect(_on_speed_changed)
	messenger_system.journey_started.connect(_on_journey_started)
	messenger_system.journey_progress.connect(_on_journey_progress)
	messenger_system.phase_changed.connect(_on_messenger_phase_changed)
	messenger_system.journey_completed.connect(_on_journey_completed)

	_on_time_changed(game_time.get_display_text())
	_on_speed_changed(game_time.get_speed_name())

func _process(delta: float) -> void:
	messenger_system.advance(delta, game_time.speed_multiplier)

	var close_enough := player.global_position.distance_to(advisor.global_position) < 90.0
	prompt.visible = close_enough and not dialogue_open and not map_open

	if close_enough and Input.is_action_just_pressed("interact") and not map_open:
		_set_dialogue_open(not dialogue_open)
		if dialogue_open:
			dialogue_text.text = "My king, reports from the Northern March require your attention.\n\nOpen the kingdom map with M. When you are ready, send the governor an order with O."

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
			KEY_O:
				if map_open:
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

func _send_regional_order() -> void:
	if messenger_system.active:
		map_status.text = "A royal messenger is already carrying this matter."
		return

	messenger_system.start_journey()

func _set_dialogue_open(open: bool) -> void:
	dialogue_open = open
	dialogue_panel.visible = open
	player.set_movement_enabled(not open and not map_open)
	prompt.visible = false

func _on_time_changed(display_text: String) -> void:
	date_label.text = display_text

func _on_speed_changed(speed_name: String) -> void:
	speed_label.text = "Time: %s   [1 Pause • 2 1x • 3 10x • 4 100x]" % speed_name

func _on_journey_started() -> void:
	messenger_marker.visible = true
	messenger_marker.position = CAPITAL_POS

func _on_journey_progress(progress: float, returning: bool) -> void:
	if returning:
		messenger_marker.position = NORTHERN_MARCH_POS.lerp(CAPITAL_POS, progress)
	else:
		messenger_marker.position = CAPITAL_POS.lerp(NORTHERN_MARCH_POS, progress)

func _on_messenger_phase_changed(text: String) -> void:
	map_status.text = text

func _on_journey_completed() -> void:
	messenger_marker.position = CAPITAL_POS
	messenger_marker.visible = false
