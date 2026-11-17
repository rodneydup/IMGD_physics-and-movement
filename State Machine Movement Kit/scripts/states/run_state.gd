## ============================================================================
##  RunState
## ----------------------------------------------------------------------------
##  The "moving fast" state. Entered when:
##    * the player holds the sprint key while moving (from Walk or Idle)
##    * they land from a jump while sprinting + moving
##
##  What happens here:
##    * horizontal velocity is set to `run_speed` (faster than walk)
##    * vertical velocity is zero (we're on the ground)
##    * jump          -> Air
##    * dash          -> Dash
##    * sprint (release) -> Walk or Idle
##    * stop input    -> Idle
##
##  NOTE on exit(): we do NOT zero the horizontal velocity when leaving.
##    This is intentional — if the player was running and then jumps, they
##    should KEEP their forward speed (that's what makes a running jump feel
##    "fast"). Every state we can transition into manages its own velocity,
##    so there's no risk of stale speed leaking into the wrong state.
## ============================================================================
class_name RunState
extends MovementState


func _init() -> void:
	state_name = &"run"


## ---------------------------------------------------------------------------
##  ENTER — one-time setup
## ---------------------------------------------------------------------------
func enter() -> void:
	# Grounded, so no vertical motion. Zero velocity.y to be safe.
	# Keep the horizontal velocity (a running player who was already moving
	# keeps that momentum; physics_process will retarget it next frame).
	player.velocity.y = 0.0


## ---------------------------------------------------------------------------
##  PER-FRAME LOGIC
## ---------------------------------------------------------------------------
func physics_process(delta: float) -> void:
	# --- Decide whether to LEAVE this state (priority order) ---------------

	# 1) Ground vanished -> falling.
	if not player.is_on_floor():
		transition_to(&"air")
		return

	# 2) Jump — highest priority.
	if Input.is_action_just_pressed("jump") and player.can_jump():
		player.perform_jump()
		transition_to(&"air")
		return

	# 3) Dash — next priority.
	if Input.is_action_just_pressed("dash"):
		transition_to(&"dash")
		return

	# 4) Sprint key released -> no longer running.
	#    Still moving? -> Walk. Stopped? -> Idle.
	if not Input.is_action_pressed("sprint"):
		if player.input_direction.length() > 0.01:
			transition_to(&"walk")
		else:
			transition_to(&"idle")
		return

	# 5) Stopped moving entirely (sprint still held but no direction) -> Idle.
	if player.input_direction.length() <= 0.01:
		transition_to(&"idle")
		return

	# --- STAY: apply running speed in the camera-relative direction ---------
	player.velocity.x = player.input_direction.x * player.run_speed
	player.velocity.z = player.input_direction.z * player.run_speed


## ---------------------------------------------------------------------------
##  ALLOWED TRANSITIONS
## ---------------------------------------------------------------------------
func get_allowed_transitions() -> Array[StringName]:
	return [&"idle", &"walk", &"air", &"dash"]
