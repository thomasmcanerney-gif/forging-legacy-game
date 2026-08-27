class_name GameTime
extends Node

signal time_changed(display_text: String)
signal speed_changed(speed_name: String)

const MINUTES_PER_DAY := 24 * 60
const DAYS_PER_MONTH := 30
const MONTHS_PER_YEAR := 12

var year: int = 1
var month: int = 1
var day: int = 1
var hour: int = 8
var minute: int = 0
var speed_multiplier: float = 1.0
var accumulated_minutes: float = 0.0

func _ready() -> void:
	_emit_time()
	_emit_speed()

func _process(delta: float) -> void:
	if speed_multiplier <= 0.0:
		return

	# Prototype pacing: at 1x, one real second advances one game minute.
	# We will tune this heavily once the annual rhythm and travel systems exist.
	accumulated_minutes += delta * speed_multiplier
	var whole_minutes := int(accumulated_minutes)
	if whole_minutes <= 0:
		return

	accumulated_minutes -= float(whole_minutes)
	_advance_minutes(whole_minutes)

func set_speed(multiplier: float) -> void:
	speed_multiplier = multiplier
	_emit_speed()

func get_speed_name() -> String:
	if speed_multiplier <= 0.0:
		return "Paused"
	return "%dx" % int(speed_multiplier)

func get_display_text() -> String:
	return "Year %d • Month %d • Day %d • %02d:%02d" % [year, month, day, hour, minute]

func _advance_minutes(amount: int) -> void:
	var total_minutes := hour * 60 + minute + amount
	var days_to_add := int(total_minutes / MINUTES_PER_DAY)
	var minute_of_day := total_minutes % MINUTES_PER_DAY

	hour = int(minute_of_day / 60)
	minute = minute_of_day % 60
	day += days_to_add

	while day > DAYS_PER_MONTH:
		day -= DAYS_PER_MONTH
		month += 1

	while month > MONTHS_PER_YEAR:
		month -= MONTHS_PER_YEAR
		year += 1

	_emit_time()

func _emit_time() -> void:
	time_changed.emit(get_display_text())

func _emit_speed() -> void:
	speed_changed.emit(get_speed_name())
