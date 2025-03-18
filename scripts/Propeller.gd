extends Node3D
class_name Propeller

@export var THRUST_COEFFICIENT: float = 0.1  # Adjust for stronger lift
@export var AIR_DENSITY: float = 1.225  # kg/m³ (Default air density)
@export var SPEED_CONSTANT: int = 5  # KV rating of motor
@export var DISC_AREA: float = 0.05  # m² (based on propeller size)
@export var DRAG_COEFFICIENT: float = 0.1  # Air resistance
@export var MAX_VOLTAGE:float = 5.0
@export var MAX_VELOCITY:Vector3 = Vector3(100, 100, 100)
@export var VELOCITY_DECAY:float = 0.75

@export var SEA_LEVEL_DENSITY: float = 1.225  # kg/m³ (default at sea level)
@export var DENSITY_DROP_RATE: float = 0.00125  # Approximate per meter

var CURRENT_RPM: int = 0
var CURRENT_VOLTAGE: float = 0.0
var CURRENT_THRUST_FORCE: float = 0.0
var CURRENT_ANGLE = 0
var CURRENT_APPLIED_FORCE = 0

var LOCAL_OFFSET: Vector3 = Vector3.ZERO

var CURRENT_VELOCITY: Vector3 = Vector3.ZERO
var DRONE: DroneController

# Called when the node enters the scene tree for the first time.
func _ready():
	LOCAL_OFFSET = global_transform.origin - owner.global_transform.origin
	DRONE = owner as RigidBody3D

func _process(delta):
	# Build a transform for the local offset
	var offset_transform = Transform3D()
	offset_transform.origin = LOCAL_OFFSET

	# Update total spin angle
	CURRENT_ANGLE += deg_to_rad(CURRENT_RPM) * delta
	CURRENT_ANGLE = wrapf(CURRENT_ANGLE, 0.0, TAU)  # More stable wrapping

	# Create a transform for the local spin
	var spin_transform = Transform3D(Basis(Vector3.UP, CURRENT_ANGLE), Vector3.ZERO)
	
	# Combine them all
	global_transform = DRONE.global_transform * offset_transform * spin_transform
	
	CURRENT_VELOCITY *= VELOCITY_DECAY
	
func _physics_process(delta):
	#print("Voltage: %.2fV, RPM: %d, Force: %.2f" % [CURRENT_VOLTAGE, CURRENT_RPM, CURRENT_THRUST_FORCE])
	
	_rpm()
	_thrust()
	_apply_drag()

	if CURRENT_VOLTAGE == 0:
		return
	var alt = get_altitude()
	var ground = get_ground_effect(alt)
	_apply_lift_force(delta, ground)
	
	var angular_speed = (CURRENT_RPM * 2 * PI) / 60
	rotate_y(angular_speed * delta)
	
func get_air_density(altitude: float) -> float:
	return max(SEA_LEVEL_DENSITY - DENSITY_DROP_RATE * altitude, 0.1)  # Avoid zero density

func get_altitude(max_check_distance: float = 50.0) -> float:
	var space_state = get_world_3d().direct_space_state  # Access physics world
	var origin = global_transform.origin  # Drone's position
	var target = origin - Vector3(0, max_check_distance, 0)  # Raycast downwards

	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.collide_with_areas = true  # Detects ground even if it's an Area3D

	var result = space_state.intersect_ray(query)  # Perform raycast

	if result.has("position"):  # If the ray hits something
		return (origin - result["position"]).length()  # Distance to the ground
	
	return max_check_distance  # Assume max distance if no ground is found

func get_ground_effect(altitude: float) -> float:
	var ground_effect_threshold = DISC_AREA * 2  # Max altitude for ground effect
	var max_boost = 1.3  # Boost factor when very close

	if altitude >= ground_effect_threshold:
		return 1.0  # No boost at higher altitudes

	var boost = max_boost - ((altitude / ground_effect_threshold) * max_boost)
	return boost

func increase_voltage(voltage:float):
	var vol = CURRENT_VOLTAGE + voltage
	
	if vol > MAX_VOLTAGE:
		return
	
	if vol < 0:
		return
	
	CURRENT_VOLTAGE = vol

func set_voltage(voltage: float):
	CURRENT_VOLTAGE = voltage

func _rpm():
	if CURRENT_VOLTAGE == 0:
		CURRENT_RPM = CURRENT_RPM * .95 if CURRENT_RPM > 0 else CURRENT_RPM
		return
		
	CURRENT_RPM = (CURRENT_VOLTAGE * SPEED_CONSTANT) * 60

func _thrust():
	if CURRENT_RPM == 0:
		CURRENT_THRUST_FORCE = 0
		return
		
	var current_air_density = get_air_density(global_position.y)
	
	# Thrust calculation
	CURRENT_THRUST_FORCE = THRUST_COEFFICIENT * current_air_density * AIR_DENSITY * DISC_AREA * pow((CURRENT_RPM / 60), 2)

func _apply_lift_force(delta, ground_effect):
	var y_vel: float = CURRENT_VELOCITY.y + CURRENT_THRUST_FORCE * (1-delta) * ground_effect
	CURRENT_APPLIED_FORCE = y_vel
	CURRENT_VELOCITY = Vector3(CURRENT_VELOCITY.x, y_vel, CURRENT_VELOCITY.z) if y_vel < MAX_VELOCITY.y else CURRENT_VELOCITY
	
	#print(CURRENT_VELOCITY)
	_apply_drone_force(CURRENT_VELOCITY)

func _apply_drag():
	var drag_force = -CURRENT_VELOCITY * DRAG_COEFFICIENT * DRONE.mass # Compute drag force vector
	_apply_drone_force(drag_force)

func _apply_drone_force(force):
	# Compute the propeller's position relative to the drone
	var force_offset = global_transform.origin - DRONE.global_transform.origin

	# Apply the force at the propeller's position relative to the drone's center
	DRONE.apply_force(force, force_offset)

	
