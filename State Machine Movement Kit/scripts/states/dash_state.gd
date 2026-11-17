## ============================================================================
##  DashState
## ----------------------------------------------------------------------------
##  The "burst of speed" state. Entered when:
##    * the player presses the dash key while in ANY other state
##
##  What happens here:
##    * On ENTER we call player.start_dash(direction) which locks the dash
##      direction and starts a timer (player.dash_duration).
##    * While the dash timer is running we OVERWRITE velocity with
##      dash_direction * dash_speed. This means:
##        - no gravity (a dash "floats" — feels snappy, not arced)
##        - no steering (the player is committed to the dash direction)
##        - no jump (jumping mid-dash would fight the dash)
##    * When the timer expires we transition OUT to wherever we should be:
##        grounded  -> Idle / Walk / Run (based on current input)
##        airborne  -> Air
## ============================================================================
class_name DashState
extends MovementState


func _init() -> void:
	state_name = &"dash"


## ---------------------------------------------------------------------------
##  ENTER — one-time setup
## ---------------------------------------------------------------------------
func enter() -> void:
	# Lock the dash direction to where the player was heading (or where the
	# camera is facing if they were stationary). start_dash() also resets the
	# timer, so we can use it as the source of truth for "is the dash done?".
	player.start_dash()
	# Zero the vertical velocity so we start the dash level.
	player.velocity.y = 0.0


## ---------------------------------------------------------------------------
##  PER-FRAME LOGIC
## ---------------------------------------------------------------------------
func physics_process(delta: float) -> void:
	# While the dash is active, OVERWRITE velocity entirely. This is the key
	# "lock" that makes a dash feel committed — no gravity, no steering, no
	# jump, just a straight line at full speed.
	if player.is_dash_active():
		player.velocity = player.dash_direction * player.dash_speed
		# Note: we do NOT call move_and_slide() here. The Player does that
		# once per frame AFTER the state machine updates. This keeps the
		# physics step consistent across all states.
		return

	# --- Dash is over: decide where to go -----------------------------------
	# Grounded? -> the usual grounded logic based on current input.
	if player.is_on_floor():
		if player.input_direction.length() > 0.01:
			if Input.is_action_pressed("sprint"):
				transition_to(&"run")
			else:
				transition_to(&"walk")
		else:
			transition_to(&"idle")
		return

	# Airborne? -> back to Air so gravity + air control resume.
	transition_to(&"air")


## ---------------------------------------------------------------------------
##  ALLOWED TRANSITIONS
## ---------------------------------------------------------------------------
## NOTE: we do NOT allow "dash" here — a dash cannot chain into another dash
## (no double-dash). If the player wants to dash again they have to go
## through one of the grounded/air states first.
func get_allowed_transitions() -> Array[StringName]:
	return [&"idle", &"walk", &"run", &"air"]
