## ============================================================================
##  IdleState
## ----------------------------------------------------------------------------
##  The "standing still" state. Entered when:
##    * the player starts the game (default state)
##    * they land from a jump
##    * they stop moving while grounded
##    * a dash finishes while grounded
##
##  What happens here:
##    * horizontal velocity eases to zero (so we don't keep sliding)
##    * vertical velocity is zero (we're on the ground)
##    * if the player presses a move key -> Walk (or Run if sprinting)
##    * if the player jumps              -> Air
##    * if the player dashes             -> Dash
## ============================================================================
class_name IdleState
extends MovementState


func _init() -> void:
	state_name = &"idle"


## One-time setup when we enter idle.
func enter() -> void:
	# Zero the horizontal speed so we come to a clean stop.
	# We keep velocity.y (usually 0 while grounded) so we don't fight gravity.
	player.velocity.x = 0.0
	player.velocity.z = 0.0


## Every-frame logic while standing still.
func physics_process(delta: float) -> void:
	# Keep us planted: cancel any stray horizontal velocity (e.g. from a bump).
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	# We're on the ground, so there's no vertical motion to manage.
	# (Gravity lives in AirState — only the "Air" state makes us fall.)

	# --- Decide whether to LEAVE this state -------------------------------

	# Edge case: if the ground just vanished from under us (e.g. a moving
	# platform), we're now falling -> go to Air.
	if not player.is_on_floor():
		transition_to(&"air")
		return

	# Read the "move" axis.  Input.get_vector() gives us a Vector2 where:
	#   x: -1 (left) .. +1 (right)
	#   y: -1 (up/W)  .. +1 (down/S)
	var move_input: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)

	# Jump first — it has priority so the player can jump from a standstill.
	# perform_jump() is the ONE place that sets velocity.y and counts the
	# jump (so we can track double-jumps). Then we move to the Air state,
	# which takes over gravity + air control from here on.
	if Input.is_action_just_pressed("jump") and player.can_jump():
		player.perform_jump()
		transition_to(&"air")
		return

	# Dash has next-highest priority.
	if Input.is_action_just_pressed("dash"):
		transition_to(&"dash")
		return

	# Movement: any non-zero input means we start walking (or running).
	# (A tiny epsilon avoids reacting to floating-point noise.)
	if move_input.length() > 0.01:
		if Input.is_action_pressed("sprint"):
			transition_to(&"run")
		else:
			transition_to(&"walk")


## Which states can we go to from Idle?
func get_allowed_transitions() -> Array[StringName]:
	return [&"walk", &"run", &"air", &"dash"]
