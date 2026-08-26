extends Node2D

@onready var player: Player = $Player
@onready var advisor: Area2D = $Advisor
@onready var game_time: GameTime = $GameTime
@onready var prompt: Label = $UI/InteractionPrompt
@onready var dialogue_panel: PanelContainer = $UI/DialoguePanel
@onready var dialogue_text: Label = $UI/DialoguePanel/MarginContainer/DialogueText
@onready var date_label: Label = $UI/DateLabel
@onready var speed_label: Label = $UI/SpeedLabel

var dialogue_open := false

func _ready() -> void:
	dialogue_panel.visible = false
	prompt.visible = false
	game_time.time_changed.connect(_on_time_changed)
	game_time.speed_changed.connect(_on_speed_changed)
	_on_time_changed(game_time.get_display_text())
	_on_speed_changed(game_time.get_speed_name())

func _process(_delta: float) -> void:
	var close_enough := player.global_position.distance_to(advisor.global_position) < 90.0
	prompt.visible = close_enough and not dialogue_open

	if close_enough and Input.is_action_just_pressed("interact"):
		_set_dialogue_open(not dialogue_open)
		if dialogue_open:
			dialogue_text.text = "My king, your father is gone. The kingdom now looks to you.\n\nThere is much to discuss, but first we must prepare for the funeral."

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

func _set_dialogue_open(open: bool) -> void:
	dialogue_open = open
	dialogue_panel.visible = open
	player.set_movement_enabled(not open)
	prompt.visible = false

func _on_time_changed(display_text: String) -> void:
	date_label.text = display_text

func _on_speed_changed(speed_name: String) -> void:
	speed_label.text = "Time: %s   [1 Pause • 2 1x • 3 10x • 4 100x]" % speed_name
