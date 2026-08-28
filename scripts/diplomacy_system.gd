class_name DiplomacySystem
extends Node

signal mission_started(target_id: String, proposal_type: String)
signal mission_progress(progress: float, returning: bool, target_id: String)
signal phase_changed(text: String)
signal mission_completed(target_id: String, proposal_type: String, outcome: String)

var active: bool = false
var target_id: String = ""
var proposal_type: String = ""
var phase: String = "idle"
var elapsed_minutes: float = 0.0
var outbound_minutes: float = 0.0
var court_delay_minutes: float = 180.0
var return_minutes: float = 0.0
var pending_outcome: String = ""

func start_mission(target: WorldKingdomData, proposal: String, player_position: Vector2) -> bool:
	if active or target == null or target.id == "player":
		return false
	active = true
	target_id = target.id
	proposal_type = proposal
	phase = "outbound"
	elapsed_minutes = 0.0
	outbound_minutes = maxf(player_position.distance_to(target.world_position) * 2.4, 360.0)
	return_minutes = outbound_minutes
	pending_outcome = ""
	mission_started.emit(target_id, proposal_type)
	phase_changed.emit("Your envoy has departed for %s with a proposal of %s." % [target.display_name, _proposal_label(proposal_type)])
	return true

func advance(delta: float, speed_multiplier: float, target: WorldKingdomData) -> void:
	if not active or speed_multiplier <= 0.0 or target == null:
		return
	var game_minutes: float = delta * speed_multiplier
	elapsed_minutes += game_minutes

	if phase == "outbound":
		var progress: float = clampf(elapsed_minutes / outbound_minutes, 0.0, 1.0)
		mission_progress.emit(progress, false, target_id)
		if elapsed_minutes >= outbound_minutes:
			phase = "court"
			elapsed_minutes = 0.0
			pending_outcome = _decide_outcome(target)
			phase_changed.emit("Your envoy has reached %s. %s is considering the proposal." % [target.capital_name, target.ruler_title + " " + target.ruler_name])
	elif phase == "court":
		if elapsed_minutes >= court_delay_minutes:
			phase = "returning"
			elapsed_minutes = 0.0
			phase_changed.emit("The foreign court has answered. Your envoy is returning with the reply.")
	elif phase == "returning":
		var progress: float = clampf(elapsed_minutes / return_minutes, 0.0, 1.0)
		mission_progress.emit(progress, true, target_id)
		if elapsed_minutes >= return_minutes:
			var completed_target: String = target_id
			var completed_proposal: String = proposal_type
			var completed_outcome: String = pending_outcome
			_reset()
			mission_completed.emit(completed_target, completed_proposal, completed_outcome)

func _decide_outcome(target: WorldKingdomData) -> String:
	if proposal_type == "trade":
		if target.relation_to_player >= 20:
			return "accepted"
		if target.relation_to_player >= -30:
			return "countered"
		return "refused"
	if proposal_type == "alliance":
		if target.relation_to_player >= 50:
			return "accepted"
		if target.relation_to_player >= 20:
			return "countered"
		return "refused"
	return "refused"

func _proposal_label(proposal: String) -> String:
	if proposal == "trade":
		return "a trade agreement"
	if proposal == "alliance":
		return "an alliance"
	return proposal

func _reset() -> void:
	active = false
	target_id = ""
	proposal_type = ""
	phase = "idle"
	elapsed_minutes = 0.0
	outbound_minutes = 0.0
	return_minutes = 0.0
	pending_outcome = ""
