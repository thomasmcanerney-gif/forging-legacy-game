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
var trade_agreement: bool = false
var alliance: bool = false

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

func change_relation(amount: int) -> void:
	relation_to_player = clampi(relation_to_player + amount, -100, 100)
	_refresh_relation_label()

func _refresh_relation_label() -> void:
	if id == "player":
		relation_label = "Your Realm"
	elif alliance:
		relation_label = "Allied"
	elif relation_to_player >= 50:
		relation_label = "Warm"
	elif relation_to_player >= 20:
		relation_label = "Friendly"
	elif relation_to_player >= -10:
		relation_label = "Neutral"
	elif relation_to_player >= -40:
		relation_label = "Wary"
	else:
		relation_label = "Hostile"

func get_summary() -> String:
	var agreements: String = ""
	if trade_agreement:
		agreements += " • Trade"
	if alliance:
		agreements += " • Alliance"
	return "%s • %s %s • Capital: %s • Relations: %s (%d)%s" % [display_name, ruler_title, ruler_name, capital_name, relation_label, relation_to_player, agreements]
