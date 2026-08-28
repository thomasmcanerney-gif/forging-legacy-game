class_name RegionalDecisionSystem
extends Node

signal crisis_arrived(text: String)
signal decision_requested(text: String)

var active: bool = true
var phase: String = "waiting"
var elapsed_minutes: float = 0.0
var choice: String = ""
var report_text: String = ""
var memory_description: String = ""
var memory_weight: int = 0

const CRISIS_START_MINUTES := 1440.0

func advance(delta: float, speed_multiplier: float) -> void:
	if not active or speed_multiplier <= 0.0 or phase != "waiting":
		return
	elapsed_minutes += delta * speed_multiplier
	if elapsed_minutes >= CRISIS_START_MINUTES:
		phase = "awaiting_decision"
		crisis_arrived.emit("A rider from Northern March reports that a bandit company is attacking merchants along the frontier road. Governor Elian asks for royal instructions.")
		decision_requested.emit("H: Hunt them aggressively • G: Guard the roads • P: Offer pardon for service")

func is_waiting_for_decision() -> bool:
	return phase == "awaiting_decision"

func choose_response(selected_choice: String) -> bool:
	if phase != "awaiting_decision":
		return false
	if selected_choice != "hunt" and selected_choice != "guard" and selected_choice != "pardon":
		return false
	choice = selected_choice
	phase = "order_in_transit"
	if choice == "hunt":
		report_text = "Governor Elian reports that the marshal's riders broke the bandit company. Trade is safe, but several villages complain that the soldiers seized supplies."
		memory_description = "You answered the March with decisive force"
		memory_weight = 5
	elif choice == "guard":
		report_text = "Governor Elian reports that guarded caravans reached the capital safely. The bandits remain in the hills, but commerce has resumed with little bloodshed."
		memory_description = "You chose patient protection over a costly pursuit"
		memory_weight = 3
	else:
		report_text = "Governor Elian reports that half the bandits accepted your pardon and entered frontier service. Merchants are uneasy, but the northern garrison gained experienced scouts."
		memory_description = "You turned former outlaws into royal servants"
		memory_weight = -2
	return true

func complete_decision() -> void:
	phase = "resolved"
	active = false
