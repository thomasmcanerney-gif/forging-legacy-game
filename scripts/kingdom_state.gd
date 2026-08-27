class_name KingdomState
extends Node

const CAPITAL_ID := "capital"
const CAPITAL_POSITION := Vector2(255, 235)

var regions: Dictionary = {}
var region_order: Array[String] = []

func _ready() -> void:
	_build_prototype_regions()

func _build_prototype_regions() -> void:
	regions.clear()
	region_order.clear()

	_add_region(RegionData.new(
		"northern_march",
		"Northern March",
		Vector2(805, 105),
		"Rugged frontier",
		"Rough track",
		1440.0,
		120.0
	))
	_add_region(RegionData.new(
		"riverlands",
		"Riverlands",
		Vector2(835, 285),
		"Fertile river valley",
		"Basic road",
		900.0,
		90.0
	))
	_add_region(RegionData.new(
		"western_hills",
		"Western Hills",
		Vector2(420, 115),
		"Rocky hill country",
		"Poor road",
		1860.0,
		180.0
	))

func _add_region(region: RegionData) -> void:
	regions[region.id] = region
	region_order.append(region.id)

func get_region(region_id: String) -> RegionData:
	return regions.get(region_id) as RegionData

func get_region_ids() -> Array[String]:
	return region_order.duplicate()
