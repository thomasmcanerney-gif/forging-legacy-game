class_name DynastySystem
extends Node

signal marriage_council_called(text: String)

var elapsed_minutes: float = 0.0
var phase: String = "waiting"
var spouse_id: String = ""
var dynasty_stability: int = 20
var heirs: Array[String] = []

const COUNCIL_START_MINUTES := 7200.0

func advance(delta: float, speed_multiplier: float) -> void:
	if phase != "waiting" or speed_multiplier <= 0.0:
		return
	elapsed_minutes += delta * speed_multiplier
	if elapsed_minutes >= COUNCIL_START_MINUTES:
		phase = "awaiting_marriage"
		marriage_council_called.emit("The royal council insists that King Aldren must marry. Two noble houses have presented candidates.")

func is_waiting_for_marriage() -> bool:
	return phase == "awaiting_marriage"

func choose_spouse(candidate_id: String) -> bool:
	if phase != "awaiting_marriage":
		return false
	if candidate_id != "elara" and candidate_id != "sabine":
		return false
	spouse_id = candidate_id
	phase = "married"
	dynasty_stability += 20
	return true

func get_family_summary(king: CharacterData, queen_mother: CharacterData, spouse: CharacterData) -> String:
	var lines: Array[String] = []
	if king != null:
		lines.append("RULER\n%s" % king.get_summary())
	if queen_mother != null:
		lines.append("\nROYAL HOUSEHOLD\n%s" % queen_mother.get_summary())
	if spouse != null:
		lines.append("\nQUEEN CONSORT\n%s" % spouse.get_summary())
	else:
		lines.append("\nQUEEN CONSORT\nThe king is unmarried.")
	if heirs.is_empty():
		lines.append("\nSUCCESSION\nNo acknowledged heir. The succession remains unsecured.")
	else:
		lines.append("\nSUCCESSION\n%s" % ", ".join(heirs))
	return "\n".join(lines)
