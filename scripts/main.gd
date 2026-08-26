extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var advisor: Area2D = $Advisor
@onready var prompt: Label = $UI/InteractionPrompt
@onready var dialogue_panel: PanelContainer = $UI/DialoguePanel
@onready var dialogue_text: Label = $UI/DialoguePanel/MarginContainer/DialogueText

var dialogue_open := false

func _ready() -> void:
	dialogue_panel.visible = false
	prompt.visible = false

func _process(_delta: float) -> void:
	var close_enough := player.global_position.distance_to(advisor.global_position) < 90.0
	prompt.visible = close_enough and not dialogue_open

	if close_enough and Input.is_action_just_pressed("interact"):
		dialogue_open = not dialogue_open
		dialogue_panel.visible = dialogue_open
		prompt.visible = false
		if dialogue_open:
			dialogue_text.text = "My king, your father is gone. The kingdom now looks to you.\n\nThere is much to discuss, but first we must prepare for the funeral."

	if dialogue_open and Input.is_action_just_pressed("ui_cancel"):
		dialogue_open = false
		dialogue_panel.visible = false
