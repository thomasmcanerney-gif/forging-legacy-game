extends Node2D

@onready var player: Player = $Player
@onready var advisor: Area2D = $Advisor
@onready var game_time: GameTime = $GameTime
@onready var messenger_system: MessengerSystem = $MessengerSystem
@onready var kingdom_state: KingdomState = $KingdomState
@onready var prompt: Label = $UI/InteractionPrompt
@onready var dialogue_panel: PanelContainer = $UI/DialoguePanel
@onready var dialogue_text: Label = $UI/DialoguePanel/MarginContainer/DialogueText
@onready var date_label: Label = $UI/DateLabel
@onready var speed_label: Label = $UI/SpeedLabel
@onready var map_panel: Panel = $UI/MapPanel
@onready var map_title: Label = $UI/MapPanel/MapTitle
@onready var map_help: Label = $UI/MapPanel/MapHelp
@onready var map_status: Label = $UI/MapPanel/MapStatus
@onready var selected_region_label: Label = $UI/MapPanel/SelectedRegion
@onready var procedural_map: ProceduralMap = $UI/MapPanel/ProceduralMap
@onready var messenger_marker: Polygon2D = $UI/MapPanel/ProceduralMap/Messenger
@onready var chronicle_panel: Panel = $UI/ChroniclePanel
@onready var chronicle_text: RichTextLabel = $UI/ChroniclePanel/ChronicleText
@onready var dynasty_panel: Panel = $UI/DynastyPanel
@onready var dynasty_text: Label = $UI/DynastyPanel/DynastyText
@onready var dynasty_help: Label = $UI/DynastyPanel/DynastyHelp

var diplomacy_system: DiplomacySystem = DiplomacySystem.new()
var foreign_event_system: ForeignEventSystem = ForeignEventSystem.new()
var regional_decision_system: RegionalDecisionSystem = RegionalDecisionSystem.new()
var chronicle: Chronicle = Chronicle.new()
var dynasty_system: DynastySystem = DynastySystem.new()
var dialogue_open: bool = false
var map_open: bool = false
var world_view: bool = false
var selected_region_index: int = 0
var selected_kingdom_id: String = "player"
var chronicle_open: bool = false
var speed_before_chronicle: float = 1.0
var dynasty_open: bool = false
var speed_before_dynasty: float = 1.0

func _ready() -> void:
	add_child(diplomacy_system)
	add_child(foreign_event_system)
	add_child(regional_decision_system)
	add_child(dynasty_system)
	dialogue_panel.visible = false
	prompt.visible = false
	map_panel.visible = false
	chronicle_panel.visible = false
	dynasty_panel.visible = false
	messenger_marker.visible = false
	procedural_map.setup(kingdom_state)
	procedural_map.region_clicked.connect(_select_region_by_id)
	procedural_map.kingdom_clicked.connect(_select_kingdom_by_id)
	game_time.time_changed.connect(_on_time_changed)
	game_time.speed_changed.connect(_on_speed_changed)
	messenger_system.journey_started.connect(_on_journey_started)
	messenger_system.journey_progress.connect(_on_journey_progress)
	messenger_system.phase_changed.connect(_on_messenger_phase_changed)
	messenger_system.journey_completed.connect(_on_journey_completed)
	diplomacy_system.mission_started.connect(_on_diplomacy_started)
	diplomacy_system.mission_progress.connect(_on_diplomacy_progress)
	diplomacy_system.phase_changed.connect(_on_diplomacy_phase_changed)
	diplomacy_system.mission_completed.connect(_on_diplomacy_completed)
	foreign_event_system.news_arrived.connect(_on_foreign_news_arrived)
	foreign_event_system.decision_requested.connect(_on_foreign_decision_requested)
	foreign_event_system.event_resolved.connect(_on_foreign_event_resolved)
	regional_decision_system.crisis_arrived.connect(_on_regional_crisis_arrived)
	regional_decision_system.decision_requested.connect(_on_regional_decision_requested)
	dynasty_system.marriage_council_called.connect(_on_marriage_council_called)
	_on_time_changed(game_time.get_display_text())
	_on_speed_changed(game_time.get_speed_name())
	_update_map_mode_text()
	_update_selected_region_display()
	_record_chronicle("Realm", "The First Year of King Aldren", "A young king took the throne of a realm still being forged.")

func _process(delta: float) -> void:
	messenger_system.advance(delta, game_time.speed_multiplier)
	foreign_event_system.advance(delta, game_time.speed_multiplier)
	regional_decision_system.advance(delta, game_time.speed_multiplier)
	dynasty_system.advance(delta, game_time.speed_multiplier)
	if diplomacy_system.active:
		var diplomatic_target: WorldKingdomData = kingdom_state.get_world_kingdom(diplomacy_system.target_id)
		var diplomatic_ruler: CharacterData = kingdom_state.get_ruler_for_kingdom(diplomacy_system.target_id)
		diplomacy_system.advance(delta, game_time.speed_multiplier, diplomatic_target, diplomatic_ruler)
	var close_enough: bool = player.global_position.distance_to(advisor.global_position) < 90.0
	prompt.visible = close_enough and not dialogue_open and not map_open and not chronicle_open and not dynasty_open
	if close_enough and Input.is_action_just_pressed("interact") and not map_open and not chronicle_open and not dynasty_open:
		_set_dialogue_open(not dialogue_open)
		if dialogue_open:
			var steward: CharacterData = kingdom_state.get_character("steward")
			if steward != null:
				dialogue_text.text = "%s\n\n%s" % [steward.get_summary(), steward.get_memory_summary()]
	if dialogue_open and Input.is_action_just_pressed("ui_cancel"):
		_set_dialogue_open(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: game_time.set_speed(0.0)
			KEY_2: game_time.set_speed(1.0)
			KEY_3: game_time.set_speed(10.0)
			KEY_4: game_time.set_speed(100.0)
			KEY_M: _toggle_map()
			KEY_K: _toggle_chronicle()
			KEY_J: _toggle_dynasty()
			KEY_E:
				if dynasty_system.is_waiting_for_marriage(): _choose_spouse("elara")
			KEY_S:
				if dynasty_system.is_waiting_for_marriage(): _choose_spouse("sabine")
			KEY_V:
				if map_open: _toggle_world_view()
			KEY_T:
				if map_open and world_view: _send_diplomatic_proposal("trade")
				elif map_open and not messenger_system.active: _cycle_selected_region()
			KEY_A:
				if map_open and world_view: _send_diplomatic_proposal("alliance")
			KEY_O:
				if map_open and not world_view: _send_regional_order()
			KEY_R:
				if foreign_event_system.is_waiting_for_decision(): _choose_coup_response("support")
			KEY_C:
				if foreign_event_system.is_waiting_for_decision(): _choose_coup_response("recognize")
			KEY_N:
				if foreign_event_system.is_waiting_for_decision(): _choose_coup_response("neutral")
			KEY_H:
				if regional_decision_system.is_waiting_for_decision(): _choose_regional_response("hunt")
			KEY_G:
				if regional_decision_system.is_waiting_for_decision(): _choose_regional_response("guard")
			KEY_P:
				if regional_decision_system.is_waiting_for_decision(): _choose_regional_response("pardon")
			KEY_ESCAPE:
				if dynasty_open and not dynasty_system.is_waiting_for_marriage(): _set_dynasty_open(false)
				elif chronicle_open: _set_chronicle_open(false)
				elif map_open and not foreign_event_system.is_waiting_for_decision() and not regional_decision_system.is_waiting_for_decision(): _set_map_open(false)

func _toggle_dynasty() -> void:
	if foreign_event_system.is_waiting_for_decision() or regional_decision_system.is_waiting_for_decision() or dynasty_system.is_waiting_for_marriage():
		return
	_set_dynasty_open(not dynasty_open)

func _set_dynasty_open(open: bool) -> void:
	dynasty_open = open
	dynasty_panel.visible = open
	if open:
		if map_open: _set_map_open(false)
		if dialogue_open: _set_dialogue_open(false)
		if chronicle_open: _set_chronicle_open(false)
		speed_before_dynasty = game_time.speed_multiplier
		game_time.set_speed(0.0)
		_refresh_dynasty_text()
	else:
		game_time.set_speed(speed_before_dynasty)
	player.set_movement_enabled(not open and not map_open and not dialogue_open and not chronicle_open)
	prompt.visible = false

func _refresh_dynasty_text() -> void:
	if dynasty_system.is_waiting_for_marriage():
		var elara: CharacterData = kingdom_state.get_character("elara")
		var sabine: CharacterData = kingdom_state.get_character("sabine")
		dynasty_text.text = "THE MARRIAGE COUNCIL\n\nE — LADY ELARA OF RIVERLANDS\n%s\n\nA diplomatic match favored by merchants and peacemakers.\n\nS — LADY SABINE OF THE WESTERN HILLS\n%s\n\nA powerful match favored by soldiers and the western nobility." % [elara.get_summary(), sabine.get_summary()]
		dynasty_help.text = "Choose E: Elara • S: Sabine"
		return
	var king: CharacterData = kingdom_state.get_character("player_king")
	var queen_mother: CharacterData = kingdom_state.get_character("queen_mother")
	var spouse: CharacterData = kingdom_state.get_character(dynasty_system.spouse_id) if not dynasty_system.spouse_id.is_empty() else null
	dynasty_text.text = dynasty_system.get_family_summary(king, queen_mother, spouse)
	dynasty_help.text = "J or Esc: Close"

func _choose_spouse(candidate_id: String) -> void:
	if not dynasty_system.choose_spouse(candidate_id): return
	var spouse: CharacterData = kingdom_state.get_character(candidate_id)
	var queen_mother: CharacterData = kingdom_state.get_character("queen_mother")
	if spouse != null:
		spouse.title = "Queen"
		spouse.remember("royal_marriage", "King Aldren chose her as his queen", 20)
	if queen_mother != null:
		queen_mother.remember("aldren_married", "The king secured the royal marriage", 8)
	var match_description: String = "Lady Elara of Riverlands, a diplomatic and compassionate noblewoman." if candidate_id == "elara" else "Lady Sabine of the Western Hills, a bold and ambitious noblewoman."
	_record_chronicle("Dynasty", "The Marriage of King Aldren", "King Aldren took as his queen %s" % match_description)
	dynasty_help.text = "The royal marriage is concluded • J or Esc: Close"
	_refresh_dynasty_text()

func _toggle_chronicle() -> void:
	if dynasty_open: return
	if foreign_event_system.is_waiting_for_decision() or regional_decision_system.is_waiting_for_decision():
		return
	_set_chronicle_open(not chronicle_open)

func _set_chronicle_open(open: bool) -> void:
	chronicle_open = open
	chronicle_panel.visible = open
	if open:
		if map_open: _set_map_open(false)
		if dialogue_open: _set_dialogue_open(false)
		speed_before_chronicle = game_time.speed_multiplier
		game_time.set_speed(0.0)
		chronicle_text.text = chronicle.get_display_text()
	else:
		game_time.set_speed(speed_before_chronicle)
	player.set_movement_enabled(not open and not map_open and not dialogue_open)
	prompt.visible = false

func _record_chronicle(category: String, title: String, description: String) -> void:
	chronicle.record(game_time.get_display_text(), category, title, description)
	if chronicle_open:
		chronicle_text.text = chronicle.get_display_text()

func _toggle_map() -> void:
	if chronicle_open or dynasty_open: return
	if (foreign_event_system.is_waiting_for_decision() or regional_decision_system.is_waiting_for_decision()) and map_open:
		return
	_set_map_open(not map_open)

func _set_map_open(open: bool) -> void:
	map_open = open
	map_panel.visible = open
	if open and dialogue_open: _set_dialogue_open(false)
	player.set_movement_enabled(not open and not dialogue_open)
	prompt.visible = false
	if open:
		_update_map_mode_text()
		if world_view: _update_selected_kingdom_display()
		else: _update_selected_region_display()
		_update_marker_visibility()

func _toggle_world_view() -> void:
	if foreign_event_system.is_waiting_for_decision() or regional_decision_system.is_waiting_for_decision(): return
	world_view = not world_view
	procedural_map.set_world_view(world_view)
	_update_map_mode_text()
	_update_marker_visibility()
	if world_view: _update_selected_kingdom_display()
	else: _update_selected_region_display()

func _update_marker_visibility() -> void:
	if world_view: messenger_marker.visible = diplomacy_system.active
	else: messenger_marker.visible = messenger_system.active

func _update_map_mode_text() -> void:
	if world_view:
		map_title.text = "THE THREE KINGDOMS"
		if foreign_event_system.is_waiting_for_decision():
			map_help.text = "CRISIS • R: Support Malek • C: Recognize rebels • N: Neutral"
		else:
			map_help.text = "Click capital • T: Trade • A: Alliance • V: Realm view • Esc/M: Close"
	else:
		map_title.text = "THE YOUNG KINGDOM"
		if regional_decision_system.is_waiting_for_decision():
			map_help.text = "BANDITS • H: Hunt • G: Guard roads • P: Offer pardon"
		else:
			map_help.text = "Click region • O: Send order • V: World view • Esc/M: Close"

func _cycle_selected_region() -> void:
	var ids: Array[String] = kingdom_state.get_region_ids()
	if ids.is_empty(): return
	selected_region_index = (selected_region_index + 1) % ids.size()
	_update_selected_region_display()

func _select_region_by_id(region_id: String) -> void:
	if messenger_system.active:
		map_status.text = "A royal messenger is already carrying a matter. Wait for the response."
		return
	var ids: Array[String] = kingdom_state.get_region_ids()
	var index: int = ids.find(region_id)
	if index == -1: return
	selected_region_index = index
	_update_selected_region_display()

func _select_kingdom_by_id(kingdom_id: String) -> void:
	selected_kingdom_id = kingdom_id
	_update_selected_kingdom_display()

func _get_selected_region() -> RegionData:
	var ids: Array[String] = kingdom_state.get_region_ids()
	if ids.is_empty(): return null
	return kingdom_state.get_region(ids[selected_region_index])

func _update_selected_region_display() -> void:
	var region: RegionData = _get_selected_region()
	if region == null:
		selected_region_label.text = "No region selected"
		return
	selected_region_label.text = "Selected: %s" % region.get_summary()
	map_status.text = "Selected %s. Roads use crossings and passes. Press V for the wider world." % region.display_name

func _update_selected_kingdom_display() -> void:
	var world_kingdom: WorldKingdomData = kingdom_state.get_world_kingdom(selected_kingdom_id)
	if world_kingdom == null:
		selected_region_label.text = "No kingdom selected"
		map_status.text = "Click a capital to inspect a neighboring kingdom."
		return
	var ruler: CharacterData = kingdom_state.get_ruler_for_kingdom(world_kingdom.id)
	if ruler != null:
		selected_region_label.text = "Selected: %s" % world_kingdom.get_summary()
	else:
		selected_region_label.text = "Selected: %s" % world_kingdom.get_summary()
	if foreign_event_system.is_waiting_for_decision() and world_kingdom.id == "edrath":
		map_status.text = "COUP IN EDRATH: choose R to support Malek, C to recognize the rebels if they prevail, or N to remain neutral."
	elif diplomacy_system.active:
		map_status.text = "An envoy is already abroad. Only one diplomatic mission is supported in this prototype."
	elif world_kingdom.id == "player":
		map_status.text = world_kingdom.disposition
	else:
		var profile_text: String = ruler.get_summary() if ruler != null else "Ruler profile unavailable."
		var memory_text: String = ruler.get_memory_summary() if ruler != null else "Memories: unavailable."
		map_status.text = "%s\n%s\n%s\nT: propose trade • A: propose alliance" % [world_kingdom.disposition, profile_text, memory_text]

func _send_regional_order() -> void:
	if regional_decision_system.is_waiting_for_decision():
		map_status.text = "Choose how to answer the Northern March first."
		return
	if messenger_system.active:
		map_status.text = "A royal messenger is already carrying a matter."
		return
	var region: RegionData = _get_selected_region()
	if region != null: messenger_system.start_journey(region)

func _send_diplomatic_proposal(proposal: String) -> void:
	if foreign_event_system.is_waiting_for_decision():
		map_status.text = "The Edrath crisis demands a response first."
		return
	if diplomacy_system.active:
		map_status.text = "Your envoy is already abroad."
		return
	var target: WorldKingdomData = kingdom_state.get_world_kingdom(selected_kingdom_id)
	var player_kingdom: WorldKingdomData = kingdom_state.get_world_kingdom("player")
	if target == null or player_kingdom == null or target.id == "player":
		map_status.text = "Select Edrath or Tirath before sending an envoy."
		return
	if proposal == "trade" and target.trade_agreement:
		map_status.text = "A trade agreement with %s already exists." % target.display_name
		return
	if proposal == "alliance" and target.alliance:
		map_status.text = "%s is already your ally." % target.display_name
		return
	diplomacy_system.start_mission(target, proposal, player_kingdom.world_position)

func _choose_coup_response(choice: String) -> void:
	if not foreign_event_system.choose_response(choice): return
	var coup_choice: String = "Support King Malek" if choice == "support" else ("Recognize the rebels" if choice == "recognize" else "Remain neutral")
	_record_chronicle("Foreign Affairs", "The Edrath Coup", "King Aldren chose to %s." % coup_choice.to_lower())
	var edrath: WorldKingdomData = kingdom_state.get_world_kingdom("edrath")
	if edrath == null: return
	if choice == "support":
		map_status.text = "You order support for King Malek. The decision has been made; now you must wait to learn whether it mattered."
	elif choice == "recognize":
		map_status.text = "You prepare to recognize the rebel regime if it secures Sarem. The decision has been made; now you wait for news."
	else:
		map_status.text = "You order the kingdom to remain neutral. Whatever happens in Sarem, your forces will stay home."
	map_help.text = "Decision sent • Time must pass before the outcome is known"

func _choose_regional_response(choice: String) -> void:
	if messenger_system.active:
		map_status.text = "Another royal messenger is still abroad. The March must wait for his return."
		return
	if not regional_decision_system.choose_response(choice): return
	var choice_title: String = "Hunt the bandits" if choice == "hunt" else ("Guard the roads" if choice == "guard" else "Offer pardon for service")
	_record_chronicle("Royal Decision", "The Bandits of Northern March", "King Aldren ordered: %s." % choice_title)
	var northern_march: RegionData = kingdom_state.get_region("northern_march")
	if northern_march == null: return
	var order_text: String = ""
	if choice == "hunt":
		order_text = "orders to hunt the bandits aggressively"
	elif choice == "guard":
		order_text = "orders to guard the merchant roads"
	else:
		order_text = "an offer of pardon in exchange for frontier service"
	messenger_system.start_journey(northern_march, order_text, regional_decision_system.report_text)
	map_help.text = "Decision sent • Watch the messenger carry your instructions"
	map_status.text = "Your decision is made. Northern March will not act until the royal messenger arrives."

func _set_dialogue_open(open: bool) -> void:
	dialogue_open = open
	dialogue_panel.visible = open
	player.set_movement_enabled(not open and not map_open)
	prompt.visible = false

func _on_time_changed(display_text: String) -> void: date_label.text = display_text
func _on_speed_changed(speed_name: String) -> void: speed_label.text = "Time: %s   [1 Pause • 2 1x • 3 10x • 4 100x]" % speed_name

func _on_journey_started(target_id: String) -> void:
	if not world_view:
		messenger_marker.visible = true
		messenger_marker.position = kingdom_state.capital_position
	var region: RegionData = kingdom_state.get_region(target_id)
	if region != null and not world_view: selected_region_label.text = "Active route: %s" % region.get_summary()

func _on_journey_progress(progress: float, returning: bool, target_id: String) -> void:
	if world_view: return
	var route: PackedVector2Array = kingdom_state.get_route(target_id)
	if route.size() < 2: return
	var route_progress: float = 1.0 - progress if returning else progress
	messenger_marker.position = _position_along_route(route, route_progress)

func _position_along_route(route: PackedVector2Array, progress: float) -> Vector2:
	progress = clampf(progress, 0.0, 1.0)
	var total_length: float = 0.0
	for i in range(route.size() - 1): total_length += route[i].distance_to(route[i + 1])
	var target_distance: float = total_length * progress
	var traveled: float = 0.0
	for i in range(route.size() - 1):
		var segment_length: float = route[i].distance_to(route[i + 1])
		if traveled + segment_length >= target_distance:
			var segment_progress: float = (target_distance - traveled) / maxf(segment_length, 0.001)
			return route[i].lerp(route[i + 1], segment_progress)
		traveled += segment_length
	return route[route.size() - 1]

func _on_messenger_phase_changed(text: String) -> void:
	if not world_view: map_status.text = text

func _on_journey_completed(_target_id: String) -> void:
	if not world_view:
		messenger_marker.position = kingdom_state.capital_position
		messenger_marker.visible = false
		if regional_decision_system.phase == "order_in_transit":
			var steward: CharacterData = kingdom_state.get_character("steward")
			if steward != null:
				steward.remember("northern_bandits_%s" % regional_decision_system.choice, regional_decision_system.memory_description, regional_decision_system.memory_weight)
			regional_decision_system.complete_decision()
			_update_map_mode_text()
			selected_region_label.text = "REPORT FROM NORTHERN MARCH"
			map_status.text = messenger_system.last_report
			_record_chronicle("Regional Report", "The March Answered", messenger_system.last_report)
		else:
			_update_selected_region_display()

func _on_diplomacy_started(target_id: String, proposal: String) -> void:
	if not world_view: return
	var player_kingdom: WorldKingdomData = kingdom_state.get_world_kingdom("player")
	if player_kingdom != null: messenger_marker.position = player_kingdom.world_position
	messenger_marker.visible = true
	selected_kingdom_id = target_id
	selected_region_label.text = "Envoy mission: %s" % proposal.capitalize()

func _on_diplomacy_progress(progress: float, returning: bool, target_id: String) -> void:
	if not world_view: return
	var player_kingdom: WorldKingdomData = kingdom_state.get_world_kingdom("player")
	var target: WorldKingdomData = kingdom_state.get_world_kingdom(target_id)
	if player_kingdom == null or target == null: return
	if returning: messenger_marker.position = target.world_position.lerp(player_kingdom.world_position, progress)
	else: messenger_marker.position = player_kingdom.world_position.lerp(target.world_position, progress)

func _on_diplomacy_phase_changed(text: String) -> void:
	if world_view: map_status.text = text

func _on_diplomacy_completed(target_id: String, proposal: String, outcome: String) -> void:
	var target: WorldKingdomData = kingdom_state.get_world_kingdom(target_id)
	if target == null: return
	var result_text: String = ""
	if proposal == "trade":
		if outcome == "accepted":
			target.trade_agreement = true
			target.change_relation(8)
			result_text = "%s accepted a trade agreement. Relations improved." % target.ruler_name
		elif outcome == "countered":
			target.change_relation(2)
			result_text = "%s declined full trade, but offered a limited border market instead." % target.ruler_name
		else:
			target.change_relation(-3)
			result_text = "%s refused the trade proposal." % target.ruler_name
	elif proposal == "alliance":
		if outcome == "accepted":
			target.alliance = true
			target.change_relation(12)
			result_text = "%s accepted the alliance. Your kingdoms are now bound together." % target.ruler_name
		elif outcome == "countered":
			target.change_relation(4)
			result_text = "%s would not accept an alliance, but proposed a non-aggression understanding." % target.ruler_name
		else:
			target.change_relation(-5)
			result_text = "%s refused the alliance." % target.ruler_name
	_record_chronicle("Diplomacy", "%s: %s" % [target.display_name, proposal.capitalize()], result_text)
	var responding_ruler: CharacterData = kingdom_state.get_ruler_for_kingdom(target_id)
	if responding_ruler != null:
		var memory_weight: int = 4 if outcome == "accepted" else (1 if outcome == "countered" else -3)
		responding_ruler.remember("diplomacy_%s_%s" % [proposal, outcome], "Your %s proposal was %s" % [proposal, outcome], memory_weight)
	selected_kingdom_id = target_id
	if world_view:
		messenger_marker.visible = false
		selected_region_label.text = "Reply: %s" % target.get_summary()
		map_status.text = result_text
	procedural_map.queue_redraw()

func _on_foreign_news_arrived(text: String) -> void:
	_record_chronicle("Foreign Crisis", "Coup in Edrath", text)
	game_time.set_speed(0.0)
	world_view = true
	procedural_map.set_world_view(true)
	selected_kingdom_id = "edrath"
	_set_map_open(true)
	_update_map_mode_text()
	var edrath: WorldKingdomData = kingdom_state.get_world_kingdom("edrath")
	if edrath != null: selected_region_label.text = "CRISIS: %s" % edrath.get_summary()
	map_status.text = text

func _on_foreign_decision_requested(text: String) -> void:
	_update_map_mode_text()
	map_status.text += "\n\n" + text

func _on_foreign_event_resolved(text: String) -> void:
	var edrath: WorldKingdomData = kingdom_state.get_world_kingdom("edrath")
	if edrath == null: return
	if foreign_event_system.decision == "support":
		var malek: CharacterData = kingdom_state.get_character("malek")
		if malek != null: malek.remember("coup_support", "You defended his throne during the coup", 30)
		edrath.change_relation(20)
		edrath.disposition = "King Malek survived the coup and remembers your support."
	else:
		edrath.ruler_name = "Varos"
		edrath.alliance = false
		var varos: CharacterData = kingdom_state.get_character("varos")
		if foreign_event_system.decision == "recognize":
			if varos != null: varos.remember("coup_recognition", "You recognized his claim before victory was certain", 24)
			edrath.change_relation(15)
			edrath.disposition = "King Varos seized the throne and values your early recognition."
		else:
			if varos != null: varos.remember("coup_neutrality", "You withheld support while he fought for the throne", -8)
			edrath.change_relation(-5)
			edrath.disposition = "King Varos seized the throne. Your neutrality avoided war but earned little trust."
	selected_kingdom_id = "edrath"
	_update_map_mode_text()
	selected_region_label.text = "AFTERMATH: %s" % edrath.get_summary()
	map_status.text = text
	_record_chronicle("Foreign Affairs", "The Fate of Edrath", text)
	procedural_map.queue_redraw()

func _on_regional_crisis_arrived(text: String) -> void:
	_record_chronicle("Regional Crisis", "Bandits in Northern March", text)
	game_time.set_speed(0.0)
	world_view = false
	procedural_map.set_world_view(false)
	var ids: Array[String] = kingdom_state.get_region_ids()
	var northern_index: int = ids.find("northern_march")
	if northern_index >= 0: selected_region_index = northern_index
	_set_map_open(true)
	_update_map_mode_text()
	selected_region_label.text = "URGENT REPORT: NORTHERN MARCH"
	map_status.text = text

func _on_regional_decision_requested(text: String) -> void:
	_update_map_mode_text()
	map_status.text += "\n\n" + text

func _on_marriage_council_called(text: String) -> void:
	_record_chronicle("Dynasty", "The Marriage Council", text)
	game_time.set_speed(0.0)
	_set_dynasty_open(true)
	_refresh_dynasty_text()
