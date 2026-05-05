extends AnimatedSprite3D

@export var max_angle : int = 180
@export var min_angle : int = 0
@onready var camera := get_viewport().get_camera_3d()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	var parent = get_parent()
	if not parent: return # Safety check

	# Get the camera's position relative to the parent
	var local_pos = parent.to_local(camera.global_position)

	# Calculate the angle on the horizontal plane
	var angle_rad = atan2(local_pos.x, -local_pos.z)
	var angle_deg = rad_to_deg(angle_rad)

	# show or hide
	if angle_deg < max_angle and angle_deg > min_angle:
		show()
	else:
		hide()
		#
#func _process(delta: float) -> void:
	#var parent = get_parent()
	#if not parent: return 
#
	## Get camera position relative to parent
	#var local_pos = parent.to_local(camera.global_position)
#
	## Get the angle from parent forward to camera
	#var angle_to_camera = atan2(local_pos.x, -local_pos.z)
	#
	## Subtract self's local rotation to make it relative to 'self'
	#var final_angle_rad = angle_to_camera - rotation.y
	#
	## Wrap the angle so it stays between -180 and 180
	#var angle_deg = wrapf(rad_to_deg(final_angle_rad), -180, 180)
#
	## Show or hide
	#if angle_deg < 45 and angle_deg > -45:
		#show()
	#else:
		#hide()
