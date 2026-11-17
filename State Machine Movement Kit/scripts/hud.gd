# ============================================================================
#  HUD
# ----------------------------------------------------------------------------
#  A tiny in-game label that shows the CURRENT movement state and the
#  remaining double-jumps. This lets the player see the state machine working 
#  in real time.
#
#  The script is attached to a Label node (under a CanvasLayer) in the
#  main scene. On _ready it:
#    1. Finds the Player (by group name, so we don't need to hard-code a path)
#    2. Connects to the state machine's `state_changed` signal
#    3. Does an initial update so the label isn't blank on the first frame
# ============================================================================
extends Label


@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var state_machine: MovementStateMachine = player.state_machine


## Called once when the node enters the tree.
func _ready() -> void:
	# Anchor the label to the top-left with a small margin.
	# (We do this here instead of in the .tscn so the anchor logic lives
	#  next to the code that owns the label — easier to follow.)
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 16.0
	offset_top = 16.0
	offset_right = 400.0
	offset_bottom = 60.0
	# Make the text readable over the 3D scene.
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_color", Color.WHITE)

	# Refresh immediately so the label isn't empty before the first signal.
	_update()

	# Whenever the state machine changes state, re-read the label.
	state_machine.state_changed.connect(_on_state_changed)
	# Also refresh when the jump budget changes. A mid-air double-jump fires
	# this even though the state stays "air" (no state_changed is emitted).
	player.jumps_changed.connect(_on_jumps_changed)


# Signal callback: fires whenever the state machine changes state.
func _on_state_changed(_old_name: StringName, _new_name: StringName) -> void:
	_update()


# Signal callback: fires whenever the jump budget changes (a jump is used, or
# the budget resets on landing). A mid-air double-jump only triggers this.
func _on_jumps_changed(_jumps_left: int) -> void:
	_update()


# (Re)build the label text from the player's current state + jump budget.
func _update() -> void:
	var state_name: StringName = state_machine.current_state.state_name
	var jumps_left: int = player.max_jumps - player.jumps_used
	text = "State: %s   |   Jumps left: %d" % [state_name, jumps_left]
