## ============================================================================
##  MovementStateMachine  (Node)
## ----------------------------------------------------------------------------
##  The "brain" that orchestrates every movement state. It is a proper Node so
##  it can live in the scene tree next to the Player, and so it can emit a
##  signal (the HUD listens to this to update the "Current State" label).
##
##  WHAT IT DOES
##    * Keeps a dictionary of all registered states:  { "idle": IdleState, ... }
##    * Tracks which state is CURRENTLY active.
##    * change_state(name):
##          1. refuses illegal transitions (not in get_allowed_transitions)
##          2. calls current_state.exit()
##          3. sets current_state to the new state
##          4. calls new_state.enter()
##          5. emits state_changed(old, new)
##    * update(delta): simply forwards to current_state.physics_process(delta).
##
##  HOW TO ADD A NEW STATE
##      var my_new_state := MyNewState.new()
##      my_new_state.player = player
##      register_state("my_new", my_new_state)
## ============================================================================
extends Node
class_name MovementStateMachine


## Emitted whenever the machine finishes switching to a new state.
##   old_state = the state we were just in ("" on the very first switch)
##   new_state = the state we are now in
signal state_changed(old_state: StringName, new_state: StringName)


## The state the player is currently in. Starts as null until register_state
## + change_state are called from the Player's _ready().
var current_state: MovementState = null


## Dictionary of every registered state, keyed by its StringName.
## e.g. { "idle": <IdleState instance>, "walk": <WalkState instance>, ... }
var _states: Dictionary = {}


## ---------------------------------------------------------------------------
##  PUBLIC API
## ---------------------------------------------------------------------------

## Register a state so the machine knows it exists.
##   name  = the key we'll use to look the state up ("idle", "dash", ...)
##   state = a MovementState instance (any class extending MovementState)
##
## NOTE: registering a state does NOT activate it. You still need to call
##       change_state(name) to actually enter it.
func register_state(name: StringName, state: MovementState) -> void:
	# Store it AND tell the state who its player is, so the state can read
	# tuning values and mutate velocity without us passing them around.
	_states[name] = state
	state.player = player_ref


## A back-reference the machine uses to wire up each state's player pointer.
## Set by the Player before it starts registering states.
var player_ref: Player = null


## Switch to the named state, if the CURRENT state allows it.
##
##   Returns true on success, false if the transition was illegal or the
##   state name is unknown.
func change_state(new_name: StringName) -> bool:
	# --- Sanity checks -----------------------------------------------------
	if not _states.has(new_name):
		push_warning("StateMachine: unknown state '%s'" % str(new_name))
		return false

	var target: MovementState = _states[new_name]

	# If we already have a current state, check whether it allows this jump.
	if current_state != null:
		# Already there? No-op.
		if current_state == target:
			return true
		# Ask the current state for its allowed list.
		var allowed: Array[StringName] = current_state.get_allowed_transitions()
		if not allowed.has(new_name):
			push_warning(
				"StateMachine: illegal transition %s -> %s" %
				[str(current_state.state_name), str(new_name)]
			)
			return false

	# --- Do the switch -----------------------------------------------------
	var old_name: StringName = current_state.state_name if current_state != null else &""

	if current_state != null:
		current_state.exit()

	current_state = target
	current_state.enter()

	state_changed.emit(old_name, current_state.state_name)
	return true


## Forward a physics frame to the current state.
## Called every frame from Player._physics_process.
func update(delta: float) -> void:
	if current_state != null:
		current_state.physics_process(delta)


## ---------------------------------------------------------------------------
##  Small conveniences
## ---------------------------------------------------------------------------

## True when the machine has a valid current state (i.e. at least one change
## has succeeded). Handy for the HUD to avoid showing "???" on frame 1.
func has_state() -> bool:
	return current_state != null


## The human-readable name of the current state, or "" if none yet.
func current_state_name() -> StringName:
	return current_state.state_name if current_state != null else &""
