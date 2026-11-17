extends Node3D

@export var camera_sensitivity = 0.01
@export var tilt_limit = deg_to_rad(75)

func _unhandled_input(event: InputEvent) -> void:
	# Mouselook implemented using `screen_relative` for resolution-independent 
	# sensitivity.
	if event is InputEventMouseMotion:
		rotation.x -= event.screen_relative.y * camera_sensitivity
		# Prevent the camera from rotating too far up or down.
		rotation.x = clampf(rotation.x, -tilt_limit, tilt_limit)
		rotation.y += -event.screen_relative.x * camera_sensitivity
	# Allows us to Left-click to capture the mouse and press Escape to get our 
	# cursor back
	if Input.is_action_just_pressed("escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Input.is_action_just_pressed("left_click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
