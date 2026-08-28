class_name MessengerSystem
extends Node

signal journey_started(target_id: String)
signal journey_progress(progress: float, returning: bool, target_id: String)
signal phase_changed(text: String)
signal journey_completed(target_id: String)

var active := false
var returning := false
var progress_minutes := 0.0
var response_delay_remaining := 0.0
var waiting_for_response := false
var target_id := ""
var target_name := ""
var one_way_travel_minutes := 0.0
var regional_response_delay_minutes := 0.0
var order_description: String = "your order"
var response_report: String = ""
var last_report: String = ""

func start_journey(region: RegionData, custom_order: String = "your order", custom_report: String = "") -> bool:
	if active:
		return false

	active = true
	returning = false
	waiting_for_response = false
	progress_minutes = 0.0
	response_delay_remaining = 0.0
	target_id = region.id
	target_name = region.display_name
	one_way_travel_minutes = region.travel_minutes_from_capital
	regional_response_delay_minutes = region.response_delay_minutes
	order_description = custom_order
	response_report = custom_report
	last_report = ""

	journey_started.emit(target_id)
	phase_changed.emit("Messenger departed the capital for %s with %s." % [target_name, order_description])
	journey_progress.emit(0.0, false, target_id)
	return true

func advance(delta: float, game_speed: float) -> void:
	if not active or game_speed <= 0.0:
		return

	var game_minutes: float = delta * game_speed

	if waiting_for_response:
		response_delay_remaining -= game_minutes
		if response_delay_remaining <= 0.0:
			waiting_for_response = false
			returning = true
			progress_minutes = 0.0
			phase_changed.emit("The governor of %s has acted. A response messenger is returning to the capital." % target_name)
			journey_progress.emit(0.0, true, target_id)
		return

	progress_minutes += game_minutes
	var progress: float = clampf(progress_minutes / one_way_travel_minutes, 0.0, 1.0)
	journey_progress.emit(progress, returning, target_id)

	if progress < 1.0:
		return

	if returning:
		active = false
		returning = false
		last_report = response_report if not response_report.is_empty() else "The governor reports that your order has been carried out."
		phase_changed.emit("Response received from %s: %s" % [target_name, last_report])
		journey_completed.emit(target_id)
	else:
		waiting_for_response = true
		response_delay_remaining = regional_response_delay_minutes
		phase_changed.emit("Your instructions reached %s. The governor is carrying them out." % target_name)
