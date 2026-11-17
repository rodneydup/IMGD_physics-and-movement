## ============================================================================
##  Player  (CharacterBody3D)
## ----------------------------------------------------------------------------
##  The player character. This node does three jobs:
##
##    1) HOLDS THE TUNING VALUES  — all the speeds / gravity / dash numbers
##       live here as @export fields, so we can tweak them live in the
##       inspector without touching code.
##
##    2) OWNS THE STATE MACHINE   — creates the MovementStateMachine node and
##       registers the 5 movement states (Idle, Walk, Run, Air, Dash).
##
##    3) SHARED PHYSICS / HELPERS — gravity-agnostic helpers like can_jump(),
##       perform_jump(), camera direction, and the final move_and_slide().
##
##  IMPORTANT: per-frame movement logic does NOT live here. It lives inside the
##  state .gd files. The Player just ticks the machine and resolves collisions.
##  That separation is the whole point of the FSM architecture.
## ============================================================================
class_name Player
extends CharacterBody3D


## Fired whenever the double-jump budget changes (a jump is used, or the
## budget is reset on landing). The HUD listens to this so it stays in sync
## even for mid-air jumps that do NOT cause a state change (e.g. a double
## jump while already in the Air state).
signal jumps_changed(jumps_left: int)


## ----------------------------------------------------------------------------
##  TUNING VALUES  (edit these in the Inspector to change feel)
## ----------------------------------------------------------------------------

## Horizontal speed while walking (meters / second).
@export var walk_speed: float = 6.0

## Horizontal speed while sprinting / running.
@export var run_speed: float = 12.0

## Upward velocity applied the instant a jump starts.
@export var jump_velocity: float = 8.0

## How hard we pull down each frame while airborne (m/s^2).
@export var gravity: float = 24.0

## How strongly we can steer left/right while in the air.
@export var air_control: float = 4.0

## How many times we can jump in a single "airtime" (1 = normal, 2 = double).
@export_range(1, 3) var max_jumps: int = 2

# --- Dash tuning ---------------------------------------
## Speed applied during the dash (overrides walk/run speed while dashing).
@export var dash_speed: float = 24.0
## How long a dash lasts, in seconds.
@export var dash_duration: float = 0.2



## ----------------------------------------------------------------------------
##  RUNTIME STATE  (not meant to be edited; managed by the code)
## ----------------------------------------------------------------------------

## The state machine that drives all movement. Created in _ready().
@onready var state_machine: MovementStateMachine = $MovementStateMachine as MovementStateMachine

## The camera rig pieces (see scenes/player.tscn).
@onready var _cam: Camera3D = $CameraPivot/CameraArm/Camera3D as Camera3D

## How many jumps we have used in the current airtime. Reset on landing.
var jumps_used: int = 0

## The horizontal direction we dash in (locked at the moment the dash starts).
var dash_direction: Vector3 = Vector3.ZERO

## Counts down from dash_duration to 0 while dashing.
var dash_timer: float = 0.0

## The current movement input vector read this frame (XZ). States use this to steer.
var input_direction: Vector3 = Vector3.ZERO

## True while the player is actively dashing.
var is_dashing: bool = false

## ============================================================================
##  Startup stuff
## ============================================================================

func _ready() -> void:
	# Let the HUD find us cheaply via a group instead of hard-coding a path.
	add_to_group("player")
	# Start the machine in the idle state. We register ALL states first, then
	# tell the machine to go to "idle" to kick things off.
	_register_all_states()
	state_machine.change_state("idle")


# Build every state once and hand it to the machine.

# THIS IS WHERE YOU PLUG IN A NEW MECHANIC.
#   1) Create your new .gd file:  `extends MovementState`
#   2) Add ONE line here:  state_machine.register_state("name", MyState.new())
#   3) Make sure the previous state lists "name" in get_allowed_transitions().
func _register_all_states() -> void:
	# The machine needs to know who its player is before it wires states up.
	state_machine.player_ref = self

	state_machine.register_state(&"idle", IdleState.new())
	state_machine.register_state(&"walk", WalkState.new())
	state_machine.register_state(&"run", RunState.new())
	state_machine.register_state(&"air", AirState.new())
	state_machine.register_state(&"dash", DashState.new())


## ============================================================================
##  PER-FRAME  (called 60x/second by Godot)
## ============================================================================

func _physics_process(delta: float) -> void:
	# --- 1) Read input ---------------------------------------------------
	_update_input_direction()

	# --- 3) Dash bookkeeping (counts down the dash clock) ---------------
	_update_dash(delta)

	# --- 4) Let the current state do its thing ---------------------------
	state_machine.update(delta)

	# --- 5) Resolve collisions against the world -------------------------
	# This is the ONE place we push our velocity into the physics world.
	# Every state above only MODIFIES velocity; this is where it counts.
	move_and_slide()


## ============================================================================
##  INPUT
## ============================================================================

## Turn the WASD/arrows into a world-space direction relative to the camera.
## Called once per physics frame so states can read self.input_direction.
func _update_input_direction() -> void:
	# get_vector returns a Vector2:
	#   .x = -1 (left/A) .. +1 (right/D)
	#   .y = -1 (up/W)   .. +1 (down/S)
	var v: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)

	# We want to move relative to where the CAMERA is looking, not to world
	# axes. -v.y because "up on screen" is camera-forward, which is -Z.
	var forward: float = -v.y
	var strafe: float = v.x

	# If there's no input at all, just zero the direction and bail.
	if forward == 0.0 and strafe == 0.0:
		input_direction = Vector3.ZERO
		return

	# Build the direction from the camera's forward/right, flattened to XZ.
	input_direction = (camera_forward() * forward + camera_right() * strafe)
	# Normalise so walking diagonally isn't faster than walking straight.
	input_direction = input_direction.normalized()



## ============================================================================
##  DASH  (shared helpers used by DashState)
## ============================================================================

## True when the player is allowed to start a dash.
func can_dash() -> bool:
	# Can't dash while already dashing (prevents chaining).
	return not is_dashing


## Begin a dash in the given (horizontal) direction.
## Called by DashState.enter().
func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	# Fall back to "where the camera is looking" if no input direction.
	if input_direction == Vector3.ZERO:
		dash_direction = camera_forward()
	else:
		dash_direction = input_direction
	# Cancel any current horizontal velocity; the dash will drive it.
	velocity.x = 0.0
	velocity.z = 0.0


## Tick the dash clock down. When it hits 0 the dash is over.
func _update_dash(delta: float) -> void:
	if not is_dashing:
		return
	dash_timer -= delta
	if dash_timer <= 0.0:
		is_dashing = false
		dash_timer = 0.0


## True while a dash is actively running.
func is_dash_active() -> bool:
	return is_dashing and dash_timer > 0.0


## ============================================================================
##  JUMP  (shared helpers used by the states)
## ============================================================================

## True when we can still jump (respects the double-jump budget).
func can_jump() -> bool:
	return jumps_used < max_jumps


## Apply the jump: kick us up + count it. Called by whichever state decided
## "yes, we jump now". Keeping it here means ALL the jump math is in ONE place.
func perform_jump() -> void:
	velocity.y = jump_velocity
	jumps_used += 1
	jumps_changed.emit(max_jumps - jumps_used)


## Reset the double-jump budget. Called by AirState the moment we land.
func reset_jumps() -> void:
	jumps_used = 0
	jumps_changed.emit(max_jumps)


## ============================================================================
##  CAMERA MATH  (flattened to the ground plane)
## ============================================================================

## The camera's forward direction, projected onto the XZ plane and normalised.
## This is "straight ahead" from the player's point of view, ignoring pitch.
func camera_forward() -> Vector3:
	var f: Vector3 = -_cam.global_transform.basis.z
	f.y = 0.0
	return f.normalized()


## The camera's right direction, projected onto the XZ plane and normalised.
func camera_right() -> Vector3:
	var r: Vector3 = _cam.global_transform.basis.x
	r.y = 0.0
	return r.normalized()
