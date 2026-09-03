class_name CharacterData
extends RefCounted

var id: String
var display_name: String
var title: String
var age: int
var traits: Array[String]
var desires: Array[String]
var loyalty: int
var opinion_of_player: int
var base_opinion_of_player: int
var memories: Array[Dictionary] = []

func _init(
	character_id: String,
	name: String,
	character_title: String,
	character_age: int,
	character_traits: Array[String],
	character_desires: Array[String],
	starting_loyalty: int,
	starting_opinion: int
) -> void:
	id = character_id
	display_name = name
	title = character_title
	age = character_age
	traits = character_traits
	desires = character_desires
	loyalty = clampi(starting_loyalty, -100, 100)
	base_opinion_of_player = clampi(starting_opinion, -100, 100)
	opinion_of_player = base_opinion_of_player

func remember(memory_id: String, description: String, emotional_weight: int) -> void:
	for memory in memories:
		if String(memory.get("id", "")) == memory_id:
			memory["description"] = description
			memory["weight"] = emotional_weight
			_recalculate_opinion()
			return
	memories.append({
		"id": memory_id,
		"description": description,
		"weight": emotional_weight
	})
	_recalculate_opinion()

func has_memory(memory_id: String) -> bool:
	for memory in memories:
		if String(memory.get("id", "")) == memory_id:
			return true
	return false

func get_memory_influence() -> int:
	var total: int = 0
	for memory in memories:
		total += int(memory.get("weight", 0))
	return clampi(total, -40, 40)

func get_diplomatic_modifier(proposal: String) -> int:
	var modifier: int = int(float(opinion_of_player) / 4.0)
	if proposal == "trade":
		if traits.has("Pragmatic"): modifier += 12
		if desires.has("Prosperous trade"): modifier += 10
	if proposal == "alliance":
		if traits.has("Loyal"): modifier += 10
		if traits.has("Suspicious"): modifier -= 12
		if desires.has("Secure borders"): modifier += 8
	return modifier

func get_opinion_label() -> String:
	if opinion_of_player >= 70: return "Deeply devoted"
	if opinion_of_player >= 40: return "Supportive"
	if opinion_of_player >= 15: return "Well disposed"
	if opinion_of_player >= -15: return "Reserved"
	if opinion_of_player >= -40: return "Distrustful"
	return "Hostile"

func get_summary() -> String:
	var trait_text: String = ", ".join(traits)
	var desire_text: String = ", ".join(desires)
	return "%s %s • Age %d • Traits: %s • Wants: %s • Attitude: %s" % [title, display_name, age, trait_text, desire_text, get_opinion_label()]

func get_memory_summary() -> String:
	if memories.is_empty():
		return "Memories: none yet."
	var descriptions: Array[String] = []
	for memory in memories:
		descriptions.append(String(memory.get("description", "")))
	return "Memories: " + " • ".join(descriptions)

func get_debug_summary() -> String:
	return "%s • Opinion: %d • Memory influence: %d" % [get_summary(), opinion_of_player, get_memory_influence()]

func _recalculate_opinion() -> void:
	var memory_total: int = get_memory_influence()
	opinion_of_player = clampi(base_opinion_of_player + memory_total, -100, 100)
