class_name ForeignEventSystem
extends Node

signal news_arrived(text: String)
signal decision_requested(text: String)
signal event_resolved(text: String)

var active: bool = true
var phase: String = "waiting"
var elapsed_minutes: float = 0.0
var decision: String = ""

const COUP_START_MINUTES := 2880.0
const NEWS_TRAVEL_MINUTES := 720.0
const RESOLUTION_MINUTES := 720.0

func advance(delta: float, speed_multiplier: float) -> void:
	if not active or speed_multiplier <= 0.0:
		return
	var game_minutes: float = delta * speed_multiplier
	elapsed_minutes += game_minutes

	if phase == "waiting" and elapsed_minutes >= COUP_START_MINUTES:
		phase = "news_travel"
		elapsed_minutes = 0.0
	elif phase == "news_travel" and elapsed_minutes >= NEWS_TRAVEL_MINUTES:
		phase = "awaiting_decision"
		elapsed_minutes = 0.0
		news_arrived.emit("News from Edrath: soldiers have surrounded King Malek's palace in Sarem. Reports are confused, and no one yet knows who controls the city.")
		decision_requested.emit("Edrath is in crisis. R: support King Malek • C: recognize the rebels if they prevail • N: remain neutral")
	elif phase == "resolving" and elapsed_minutes >= RESOLUTION_MINUTES:
		phase = "resolved"
		active = false
		event_resolved.emit(_resolution_text())

func choose_response(choice: String) -> bool:
	if phase != "awaiting_decision":
		return false
	if choice != "support" and choice != "recognize" and choice != "neutral":
		return false
	decision = choice
	phase = "resolving"
	elapsed_minutes = 0.0
	return true

func is_waiting_for_decision() -> bool:
	return phase == "awaiting_decision"

func _resolution_text() -> String:
	if decision == "support":
		return "A second report reaches the capital: loyal troops rallied around King Malek. The coup has failed. Malek remembers that you backed him when his throne was uncertain."
	if decision == "recognize":
		return "A second report reaches the capital: the rebels seized Sarem and proclaimed Lord Varos king. Your early recognition pleased the new regime, but Malek's surviving loyalists now regard you as an enemy."
	return "A second report reaches the capital: the rebels seized Sarem and proclaimed Lord Varos king. Your neutrality kept your hands clean, but the new ruler has no reason yet to trust you."
