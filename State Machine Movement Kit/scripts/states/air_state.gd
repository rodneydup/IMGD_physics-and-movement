## ============================================================================
##  AirState
## ----------------------------------------------------------------------------
##  Every state the player spends while NOT touching the ground:
##    * rising after a jump
##    * falling after the apex
##    * the SECOND (double) jump
##    * steering in mid-air ("air control")
##    * landing on a new platform
##
##  THIS STATE OWNS GRAVITY. While we are in Air we apply gravity every
##  frame so the player falls. When we land we leave for Idle/Walk/Run.
##
##  Why lump "jump", "double-jump" and "fall" into ONE state?
##    Because they are all the same physical situation: "in the air".
##    Splitting them into three states would mean the machine is constantly
##    jumping between them for no real benefit. One Air state is simpler to
##    reason about.
## ============================================================================
class_name AirState
extends MovementState


func _init() -> void:
	state_name = &"air"


## ---------------------------------------------------------------------------
##  ENTER — one-time setup
## ---------------------------------------------------------------------------
func enter() -> void:
	# Nothing dramatic to do: the jump velocity was ALREADY applied by
	# player.perform_jump() (for the first jump) or here for a double jump.
	# We just let gravity do its thing from the very first frame.
	pass


## ---------------------------------------------------------------------------
##  PER-FRAME LOGIC
## ---------------------------------------------------------------------------
func physics_process(delta: float) -> void:
	# 1) GRAVITY — pull us down. (Only in Air; grounded states skip this.)
	#    velocity.y -= gravity * delta  (gravity is positive like 24, and +y
	#    is "up" in Godot, so we SUBTRACT it to pull the player DOWN.)
	player.velocity.y -= player.gravity * delta

	# 2) AIR CONTROL — let the player steer left/right in the air.
	#    We use the camera-relative direction the Player already computed
	#    (player.input_direction) so steering always feels "where I'm looking".
	#    We only touch the horizontal part of velocity; we never touch
	#    velocity.y here except for gravity, so the jump arc stays clean.
	if player.input_direction.length() > 0.01:
		# air_control scales how strongly we can steer in the air.
		var target_horizontal: Vector3 = player.input_direction * player.air_control
		# Smoothly approach the target so it feels responsive but not snappy.
		var current: Vector2 = Vector2(player.velocity.x, player.velocity.z)
		var new_horizontal: Vector2 = current.lerp(
			Vector2(target_horizontal.x, target_horizontal.z),
			0.2  # higher = snappier
		)
		player.velocity.x = new_horizontal.x
		player.velocity.z = new_horizontal.y

	# 3) DECIDE WHETHER TO LEAVE ------------------------------------------------
	# a) LANDING: if we're touching the ground now, we've landed.
	if player.is_on_floor():
		# Reset the double-jump budget for the next airtime.
		player.reset_jumps()
		# Where do we land? Still trying to move? -> Walk/Run, else Idle.
		if player.input_direction.length() > 0.01:
			if Input.is_action_pressed("sprint"):
				transition_to(&"run")
			else:
				transition_to(&"walk")
		else:
			transition_to(&"idle")
		return

	# b) DASH: the player can dash while airborne too.
	if Input.is_action_just_pressed("dash"):
		transition_to(&"dash")
		return

	# c) DOUBLE JUMP: if we still have jumps left, let the player use them.
	#    perform_jump() bumps jumps_used, so on the 2nd call in the air
	#    (max_jumps == 2) can_jump() is true and a 3rd would be refused.
	if Input.is_action_just_pressed("jump") and player.can_jump():
		player.perform_jump()
		# Stay in Air — we're still airborne, we just kicked off again.


## ---------------------------------------------------------------------------
##  ALLOWED TRANSITIONS
## ---------------------------------------------------------------------------
func get_allowed_transitions() -> Array[StringName]:
	return [&"idle", &"walk", &"run", &"dash"]
