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
	opinion_of_player = clampi(starting_opinion, -100, 100)

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
	var modifier: int = opinion_of_player / 4
	if proposal == "trade":
		if traits.has("Pragmatic"): modifier += 12
		if desires.has("Prosperous trade"): modifier += 10
	if proposal == "alliance":
		if traits.has("Loyal"): modifier += 10
		if traits.has("Suspicious"): modifier -= 12
		if desires.has("Secure borders"): modifier += 8
	return modifier

func get_summary() -> String:
	var trait_text: String = ", ".join(traits)
	var desire_text: String = ", ".join(desires)
	return "%s %s • Age %d • Traits: %s • Wants: %s • Opinion: %d" % [title, display_name, age, trait_text, desire_text, opinion_of_player]

func get_memory_summary() -> String:
	if memories.is_empty():
		return "Memories: none yet."
	var descriptions: Array[String] = []
	for memory in memories:
		var weight: int = int(memory.get("weight", 0))
		var sign_text: String = "+" if weight >= 0 else ""
		descriptions.append("%s (%s%d)" % [String(memory.get("description", "")), sign_text, weight])
	return "Memories: " + " • ".join(descriptions)

func _recalculate_opinion() -> void:
	var memory_total: int = get_memory_influence()
	opinion_of_player = clampi(opinion_of_player + memory_total, -100, 100)
