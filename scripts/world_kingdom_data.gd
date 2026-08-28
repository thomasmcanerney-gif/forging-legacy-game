class_name WorldKingdomData
extends RefCounted

var id: String
var display_name: String
var ruler_name: String
var ruler_title: String
var capital_name: String
var world_position: Vector2
var territory: PackedVector2Array
var relation_to_player: int
var relation_label: String
var disposition: String

func _init(
	kingdom_id: String,
	name: String,
	ruler: String,
	title: String,
	capital: String,
	position: Vector2,
	polygon: PackedVector2Array,
	relation: int,
	relation_text: String,
	disposition_text: String
) -> void:
	id = kingdom_id
	display_name = name
	ruler_name = ruler
	ruler_title = title
	capital_name = capital
	world_position = position
	territory = polygon
	relation_to_player = relation
	relation_label = relation_text
	disposition = disposition_text

func get_summary() -> String:
	return "%s • %s %s • Capital: %s • Relations: %s (%d)" % [display_name, ruler_title, ruler_name, capital_name, relation_label, relation_to_player]
