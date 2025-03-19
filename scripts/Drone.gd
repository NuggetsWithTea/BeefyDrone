extends RigidBody3D
class_name DroneController

@export var DRAG_COEFFICIENT: float = 0.1  # Air resistance
@export var ROTATIONAL_DAMPING: float = .9
@export var ALTITUDE_CHECK_DISTANCE: float = 5000
@export var GRAVITY: float = 0 # set in ready
@export var TORGUE_COEFFICIENT: float = 0.0025  # C_q, adjust based on your propeller specs

var propellers:Array[Propeller]
var ground: MeshInstance3D
var Current_WIND_FORCE = Vector3.ZERO
var CURRENT_DRAG: Vector3 = Vector3.ZERO
var MOMENT_OF_INERTIA: float = 0

var turn_right = true
var turn_left = false

var CURRENT_ALTITUDE: float = 0 #distance between the drone and the nearest obstacle

func _ready():
	propellers = [$"Propeller 1", $"Propeller 2", $"Propeller 3",$"Propeller 4"]
	#this has to be set here, because godot otherwise overwrites this when initializing the propellers
	propellers[0].IS_ROTATION_REVERSED = true
	propellers[2].IS_ROTATION_REVERSED = true
	ground = $"../Ground"
	GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity") as float
	add_to_group("wind_affected")
	
	MOMENT_OF_INERTIA = moment_of_inertia()

func _physics_process(delta):
	effective_lift(delta)
	get_altitude()
	apply_yaw_torque(delta)
	apply_impulse((Current_WIND_FORCE / mass) * delta)
	apply_central_force(Vector3(0, -GRAVITY * delta, 0))
	angular_velocity *= .98
	
func _input(event):
	if Input.is_action_just_pressed("forward"):
		propellers[2].increase_voltage(-.5)
		propellers[3].increase_voltage(-.5)
		
	if Input.is_action_just_pressed("backward"):
		propellers[2].increase_voltage(.5)
		propellers[3].increase_voltage(.5)
		
	if Input.is_action_pressed("left"):
		propellers[1].IS_ROTATION_REVERSED = turn_right
		propellers[3].IS_ROTATION_REVERSED = turn_right
		turn_right = not turn_right
	
	if Input.is_action_pressed("right"):
		propellers[0].IS_ROTATION_REVERSED = turn_left
		propellers[2].IS_ROTATION_REVERSED = turn_left
		turn_left = not turn_left
	
	if Input.is_action_just_pressed("up"):
		for prop in propellers:
			prop.increase_voltage(.5)
			
	if Input.is_action_just_pressed("down"):
		for prop in propellers:
			prop.increase_voltage(-.5)
			
	if Input.is_action_just_pressed("stop"):
		for prop in propellers:
			prop.set_voltage(0)
	
func apply_yaw_torque(delta):
	var net_yaw_torque: float = 0.0
	for prop in propellers:
		var sigma: int = -1 if prop.IS_ROTATION_REVERSED else 1 # +1 or -1, depending on rotor spin
		var rpm: float = prop.CURRENT_RPM
		var n: float = rpm / 60.0  # Convert RPM to revolutions per second (RPS)
		net_yaw_torque += sigma * TORGUE_COEFFICIENT * n * n
	# Apply the net yaw torque about the up axis (or appropriate axis)
	apply_torque(Vector3.UP * net_yaw_torque)

func get_altitude():
	var coll_shape = $CollisionShape3D
	var size = coll_shape.shape.size * coll_shape.scale
	# We'll cast a ray straight down from the drone's position
	var space_state = get_world_3d().direct_space_state
	var origin = global_transform.origin 
	var target = origin - Vector3(0, ALTITUDE_CHECK_DISTANCE, 0)

	var query = PhysicsRayQueryParameters3D.create(origin, target)
	# If your ground is a physics body, these defaults work.
	# Adjust if you need to collide with or exclude certain layers.
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [self]

	# Perform the actual raycast
	var result = space_state.intersect_ray(query)
	
	if result.has("position"):
		# Return how far the drone is from the point where the ray hit
		CURRENT_ALTITUDE = (origin - result["position"]).length()
		return
	
	# If it didn't hit anything, assume max distance
	CURRENT_ALTITUDE = ALTITUDE_CHECK_DISTANCE
	
func moment_of_inertia():
	var drone_arm_mass = mass * 0.25
	var moment_of_inertia = 0
	for prop in propellers:
		var prop_mass = prop.mass
		var dist_from_center = prop.LOCAL_OFFSET.x
		
		var dist_center_squared = pow(dist_from_center, 2)
		var left_shit = (drone_arm_mass * dist_center_squared) / 3
		var right_shit = prop_mass * dist_center_squared
		
		var shit = left_shit + right_shit
		moment_of_inertia += shit
	
	return moment_of_inertia
	
func effective_lift(delta):
	if(propellers.all(func(x): return x.CURRENT_VOLTAGE == 0)):
		return
		
	var total_force = Vector3.ZERO
	var total_torque = Vector3.ZERO

	# Center of mass for force calculations
	var center_of_mass = global_transform.origin

	for prop in propellers:
		var force = prop.CURRENT_APPLIED_FORCE
		var offset = prop.global_transform.origin - center_of_mass

		total_force += force
		total_torque += offset.cross(force)  # Rotational force

	# Get the drone’s local axes
	var up_direction = global_transform.basis.y.normalized()       # Drone's up
	var forward_direction = -global_transform.basis.z.normalized() # Drone's forward
	var right_direction = global_transform.basis.x.normalized()    # Drone's right

	# **Corrected Force Decomposition**
	var world_up = Vector3.UP  # World up direction, always (0,1,0)

	var vertical_force = total_force.project(world_up)  # Lift force in world space
	var forward_force = -total_force.project(forward_direction)  # Forward thrust
	var sideways_force = total_force.project(right_direction)  # Lateral thrust

	# Apply linear acceleration from forces (Newton's Second Law: F = m * a)
	linear_velocity += (vertical_force / mass) * delta  # Move up/down
	linear_velocity += (forward_force / mass) * delta  # Move forward/backward
	linear_velocity += (sideways_force / mass) * delta  # Move sideways

	# **Apply Torque with Moment of Inertia**
	var angular_acceleration = total_torque / MOMENT_OF_INERTIA  # Compute rotational acceleration
	angular_velocity += angular_acceleration * delta  # Update rotation

	# **Apply Rotational Damping** (prevents infinite spinning)
	var damping_torque = -angular_velocity * ROTATIONAL_DAMPING
	apply_torque(damping_torque)

	# **Apply Drag to Stabilize Movement**
	var drag = -DRAG_COEFFICIENT * linear_velocity
	apply_central_force(drag)



func set_wind_force(force:Vector3):
	Current_WIND_FORCE = force
