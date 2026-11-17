## ============================================================================
##  MovementState  (BASE CLASS)
## ----------------------------------------------------------------------------
##  This is the "template" that every single movement state inherits from.
##  Think of it as a skeleton / contract: it tells Godot (and us) exactly what
##  functions every state MUST provide, and gives them all a couple of little
##  helpers for free.
##
##  WHY a base class?
##    The "Finite State Machine" (FSM) pattern means the player is always in
##    exactly ONE state at a time (Idle, Walk, Run, Air, Dash...). Each state
##    is its own little .gd file that extends this class. The machine doesn't
##    need to know the details of each state — it only talks to this shared
##    base. That's what makes adding a NEW mechanic as easy as:
##        1) create a new file that extends MovementState
##        2) register it with the machine (one line)
##
##  WHY RefCounted and not Node?
##    States are pure logic — they don't need to live in the scene tree.
##    RefCounted objects are automatically freed by Godot when nothing
##    references them any more, which keeps things tidy.
## ============================================================================
extends RefCounted
class_name MovementState


## The human-readable name of this state (e.g. "Idle", "Dash").
## Filled in by each concrete state in _init(). Used for logging + the HUD.
var state_name: StringName = &""


## A reference to the Player node that "owns" this state.
## The machine sets this when it registers the state. States use it to read
## player tuning values (speeds, gravity...) and to change velocity.
var player: Player = null


## ---------------------------------------------------------------------------
##  Functions every concrete state MUST override.
##  (They are intentionally empty here — just so the machine can safely call
##   them on any state without knowing which state it actually is.)
## ---------------------------------------------------------------------------

## Called once when the player ENTERS this state.
## Perfect place to do one-time setup, e.g. "lock the dash direction" or
## "reset the double-jump counter".
func enter() -> void:
	pass


## Called once when the player LEAVES this state (right before the next
## state's enter() runs). Good for cleanup.
func exit() -> void:
	pass


## Called EVERY physics frame (60x/second) while the player is in this state.
## This is where the actual per-frame movement logic lives — applying gravity,
## steering, etc.
##
##   delta = how many seconds have passed since the last physics frame.
##           We multiply speeds by delta so motion is frame-rate independent.
func physics_process(delta: float) -> void:
	pass


## Returns the list of state names this state is ALLOWED to go to.
## Example: IdleState returns [Walk, Run, Air, Dash] but NOT other states.
## The machine checks this list before any change_state(), so illegal
## transitions (like "Dash -> Dash") are simply refused.
func get_allowed_transitions() -> Array[StringName]:
	return []


## ---------------------------------------------------------------------------
##  Helpers provided for free to every state.
## ---------------------------------------------------------------------------

## True when the player is touching the ground (standing / walking / running).
func is_grounded() -> bool:
	return player.is_on_floor()


## Convenience: ask the machine to switch to the named state.
## (We route through the machine so it can do enter/exit bookkeeping and fire
##  the state_changed signal that the HUD listens to.)
func transition_to(new_state: StringName) -> void:
	player.state_machine.change_state(new_state)
