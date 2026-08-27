class_name MessengerSystem
extends Node

signal journey_started
signal journey_progress(progress: float, returning: bool)
signal phase_changed(text: String)
signal journey_completed

@export var one_way_travel_minutes: float = 1440.0
@export var regional_response_delay_minutes: float = 120.0

var active := false
var returning := false
var progress_minutes := 0.0
var response_delay_remaining := 0.0
var waiting_for_response := false

func start_journey() -> bool:
	if active:
		return false

	active = true
	returning = false
	waiting_for_response = false
	progress_minutes = 0.0
	response_delay_remaining = 0.0
	journey_started.emit()
	phase_changed.emit("Messenger departed the capital with your order.")
	journey_progress.emit(0.0, false)
	return true

func advance(delta: float, game_speed: float) -> void:
	if not active or game_speed <= 0.0:
		return

	var game_minutes := delta * game_speed

	if waiting_for_response:
		response_delay_remaining -= game_minutes
		if response_delay_remaining <= 0.0:
			waiting_for_response = false
			returning = true
			progress_minutes = 0.0
			phase_changed.emit("The governor has acted. A response messenger is returning to the capital.")
			journey_progress.emit(0.0, true)
		return

	progress_minutes += game_minutes
	var progress := clamp(progress_minutes / one_way_travel_minutes, 0.0, 1.0)
	journey_progress.emit(progress, returning)

	if progress < 1.0:
		return

	if returning:
		active = false
		returning = false
		phase_changed.emit("Response received: the governor reports that your order has been carried out.")
		journey_completed.emit()
	else:
		waiting_for_response = true
		response_delay_remaining = regional_response_delay_minutes
		phase_changed.emit("Your order reached the Northern March. The governor is carrying it out.")
