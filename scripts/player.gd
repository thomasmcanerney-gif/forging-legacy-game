class_name Player
extends CharacterBody2D

@export var speed: float = 180.0

var movement_enabled := true

func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not movement_enabled:
		velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
