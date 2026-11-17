## ============================================================================
##  WalkState
## ----------------------------------------------------------------------------
##  The "moving slowly" state. Entered when:
##    * the player presses a move key while standing (Idle)
##    * they land from a jump while still holding a move key
##    * they stop sprinting while moving
##
##  What happens here:
##    * horizontal velocity is set to `walk_speed` in the camera-relative
##      direction the player is pressing
##    * vertical velocity is zero (we're on the ground)
##    * jump          -> Air
##    * dash          -> Dash
##    * sprint (hold) -> Run
##    * stop input    -> Idle
## ============================================================================
class_name WalkState
extends MovementState


func _init() -> void:
	state_name = &"walk"


## ---------------------------------------------------------------------------
##  ENTER — one-time setup
## ---------------------------------------------------------------------------
func enter() -> void:
	# We're on the ground, so there's no vertical motion. Zero velocity.y
	# (it's usually already 0, but this guards against a landing bounce).
	# We deliberately KEEP the horizontal velocity: it lets a landing carry a
	# little momentum for one frame before physics_process takes over.
	player.velocity.y = 0.0


## ---------------------------------------------------------------------------
##  PER-FRAME LOGIC
## ---------------------------------------------------------------------------
func physics_process(delta: float) -> void:
	# --- Decide whether to LEAVE this state (priority order) ---------------

	# 1) Ground vanished -> we're falling now.
	if not player.is_on_floor():
		transition_to(&"air")
		return

	# 2) Jump — highest priority so a walking player can always hop.
	if Input.is_action_just_pressed("jump") and player.can_jump():
		player.perform_jump()
		transition_to(&"air")
		return

	# 3) Dash — next priority.
	if Input.is_action_just_pressed("dash"):
		transition_to(&"dash")
		return

	# 4) Sprint released? -> drop back to idle if no input, else we keep
	#    walking (handled below). Sprint is a hold-key, so pressing it
	#    while walking should upgrade us to Run.
	if Input.is_action_pressed("sprint"):
		transition_to(&"run")
		return

	# 5) Stopped moving entirely -> Idle.
	if player.input_direction.length() <= 0.01:
		transition_to(&"idle")
		return

	# --- STAY: apply walking speed in the camera-relative direction ---------
	# player.input_direction is a normalized Vector3 the Player computed from
	# the WASD keys + camera rotation, so this always moves "where you look".
	player.velocity.x = player.input_direction.x * player.walk_speed
	player.velocity.z = player.input_direction.z * player.walk_speed


## ---------------------------------------------------------------------------
##  ALLOWED TRANSITIONS
## ---------------------------------------------------------------------------
func get_allowed_transitions() -> Array[StringName]:
	return [&"idle", &"run", &"air", &"dash"]
