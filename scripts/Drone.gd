extends RigidBody3D
class_name DroneController

@export var DRAG_COEFFICIENT: float = 0.1  # Air resistance
@export var ROTATIONAL_DAMPING: float = .9
@export var ALTITUDE_CHECK_DISTANCE: float = 500

#########################################
# apply all lift forces from the propellers in this script. this should fix the wiggle problem
var propellers:Array[Propeller]
var ground: MeshInstance3D
var Current_WIND_FORCE = Vector3.ZERO
var CURRENT_DRAG: Vector3 = Vector3.ZERO

var CURRENT_ALTITUDE: float = 0 #distance between the drone and the nearest obstacle

func _ready():
	propellers = [$"Propeller 1", $"Propeller 2", $"Propeller 3",$"Propeller 4"]
	
	ground = $"../Ground"
	add_to_group("wind_affected")
	#for p in propellers:
		#p.set_voltage(4)

func _physics_process(delta):
	effective_lift(delta)
	var drag = -DRAG_COEFFICIENT * linear_velocity
	apply_force(drag)
	get_altitude()
	angular_velocity *= .98
	linear_velocity += (Current_WIND_FORCE / mass) * delta
	#print(global_position)
	
func _input(event):
	if Input.is_action_just_pressed("forward"):
		propellers[2].increase_voltage(-.5)
		propellers[3].increase_voltage(-.5)
		
	if Input.is_action_just_pressed("backward"):
		propellers[2].increase_voltage(.5)
		propellers[3].increase_voltage(.5)
		
	if Input.is_action_just_pressed("up"):
		for prop in propellers:
			prop.increase_voltage(.5)
			
	if Input.is_action_just_pressed("down"):
		for prop in propellers:
			prop.increase_voltage(-.5)
			
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
			
func effective_lift(delta):
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
	var up_direction = global_transform.basis.y.normalized()       # Local "up"
	var forward_direction = -global_transform.basis.z.normalized() # Local "forward"
	var right_direction = global_transform.basis.x.normalized()    # Local "right"

	# Separate total force into vertical and horizontal components
	var vertical_force = total_force.project(up_direction)   # Lift force
	var horizontal_force = total_force - vertical_force      # Horizontal movement force

	# Project linear velocity onto the drone's axes using dot product
	var velocity_forward = forward_direction * linear_velocity.dot(forward_direction)
	var velocity_right = right_direction * linear_velocity.dot(right_direction)
	var velocity_up = up_direction * linear_velocity.dot(up_direction)

	# Reconstruct velocity with respect to drone’s orientation
	linear_velocity = velocity_forward + velocity_right + velocity_up

	# Apply lift and movement forces
	linear_velocity += (vertical_force / mass) * delta  # Maintain altitude
	linear_velocity += (horizontal_force / mass) * delta  # Move in tilt direction

	apply_torque(total_torque)  # Apply rotation torque

	# Apply drag to stabilize movement
	var drag = -DRAG_COEFFICIENT * linear_velocity
	apply_central_force(drag)
	
	var damping_torque = -angular_velocity * ROTATIONAL_DAMPING
	apply_torque(damping_torque)


func set_wind_force(force:Vector3):
	Current_WIND_FORCE = force
