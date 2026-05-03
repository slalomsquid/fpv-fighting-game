extends CharacterBody3D

@export var sensitivity : float = 1.0
@export var base_height : float = 1.0
@export var minPitchDeg : int = -90
@export var maxPitchDeg : int = 90
@export var jumpStrength : int = 5
@export var states : Dictionary[String, Dictionary] = {
	"walk": {"height" : 1.0, "rate" : 10, "max" : 6}, 
	"sprint": {"height" : 1.0, "rate" : 10, "max" : 12}, 
	"crouch": {"height" : 0.5, "rate" : 10, "max" : 2}, 
	"air": {"height" : 1.0, "rate" : 1, "max" : 5}
}


@onready var anim = $Control/AnimatedSprite2D

@onready var mesh = $Pivot/MeshInstance3D
@onready var pitch = $Pivot/Pitch
@onready var pivot = $Pivot
@onready var camera = $Pivot/Pitch/Camera3D
@onready var ray = $Pivot/Pitch/Camera3D/RayCast3D
@onready var cursor = $Cursor

signal click(global_pos: Vector3, body: Node3D)

var _velocity : Vector3 = Vector3.ZERO
var state := "walk"
var current_rate : float = states[state]["rate"]
var current_max_speed : float = states[state]["max"]
var global_col_point := Vector3.ZERO
var show_cursor : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mesh.scale.y = base_height
	anim.play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#cursor.global_position = lerp(cursor.global_position, global_col_point, delta*20)
	#cursor.global_position = global_col_point
	ray.force_raycast_update()
	if ray.is_colliding():
		$Cursor.show()
		global_col_point = ray.get_collision_point()
		cursor.global_position = ray.get_collision_point()
	else:
		$Cursor.hide()
		
	if Input.is_action_pressed("left_click"):
		anim.play("punch")
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		emit_signal("click", ray.get_collision_point(), ray.get_collider())
		# Depending on the need this can also be used, but mostly I just send collision and check if collider exists
		#if ray.is_colliding():
			#emit_signal("click", global_col_point, ray.get_collider())
	if Input.is_action_pressed("right_click"):
		anim.play("elbow")
	if Input.is_action_pressed("sprint"):
		set_state("sprint")
	
func _input(event):
	if event is InputEventMouseMotion:
		#print("Mouse moved by: ", event.relative)
		# This could technically be an issue if the player was rotating in one direction millions of times, but if so, theres bigger problems to worry about
		pivot.rotate_y(deg_to_rad(-event.relative.x * sensitivity/10))
		pitch.rotate_x(deg_to_rad(-event.relative.y * sensitivity/10))
		pitch.rotation.x = clamp(pitch.rotation.x, deg_to_rad(minPitchDeg), deg_to_rad(maxPitchDeg))
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_released("sprint"):
		set_state("walk")
	if event.is_action_pressed("crouch"):
		set_state("crouch")
	if event.is_action_released("crouch"):
		set_state("walk")

func set_state(new_state : String) -> void:
	state = new_state
	current_rate = states[state]["rate"]
	current_max_speed = states[state]["max"]
	#mesh.scale.y = states[state]["height"]

func _physics_process(delta: float) -> void:
	
	mesh.scale.y = move_toward(mesh.scale.y, states[state]["height"]*base_height, 2*delta)
	var target_cam_height = 0.5 if state != "crouch" else -0.5
	camera.position.y = lerp(camera.position.y, target_cam_height, 10 * delta)
	
	# calculate movement direction based on input and look direction
	var moveDirection : Vector3 = Vector3.ZERO
	moveDirection.x = Input.get_axis("left", "right")
	moveDirection.z = Input.get_axis("forward", "back")

	moveDirection = moveDirection.rotated(Vector3.UP, pivot.rotation.y).normalized()

	# apply horizontal movement to velcity
	_velocity.x = lerp(_velocity.x, moveDirection.x * current_max_speed, current_rate*delta)
	_velocity.z = lerp(_velocity.z, moveDirection.z * current_max_speed, current_rate*delta)

	if is_on_floor():
		if state == "air":
			set_state("walk")
		_velocity.y = 0.0
		if Input.is_action_just_pressed("jump"):
			anim.play("idle")
			_velocity.y = jumpStrength
	else:
		set_state("air")
		_velocity.y += get_gravity().y * delta
	
	# apply movement
	set_velocity(_velocity)
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	move_and_slide()
	_velocity = velocity
	
	$Label.text = state + str(velocity.length()) + str(global_position.y)
	
	## rotate player model to face movement direction
	if _velocity.length() > 0.2:
		var lookDir : Vector2 = Vector2(_velocity.z, _velocity.x)
		mesh.rotation.y = lookDir.angle()
		
