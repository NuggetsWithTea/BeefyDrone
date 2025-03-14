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

var CURRENT_RPM: int = 0
var CURRENT_VOLTAGE: float = 0.0
var CURRENT_THRUST_FORCE: float = 0.0
var CURRENT_ANGLE = 0

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
	
	CURRENT_VELOCITY *= VELOCITY_DECAY * delta
	
func _physics_process(delta):
	print("Voltage: %.2fV, RPM: %d, Force: %.2f" % [CURRENT_VOLTAGE, CURRENT_RPM, CURRENT_THRUST_FORCE])
	
	_rpm()
	_thrust()

	if CURRENT_VOLTAGE == 0:
		return
		
	_apply_lift_force(delta)
	_apply_drag()
	
	var angular_speed = (CURRENT_RPM * 2 * PI) / 60
	rotate_y(angular_speed * delta)
	
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
	# Thrust calculation
	CURRENT_THRUST_FORCE = THRUST_COEFFICIENT * AIR_DENSITY * DISC_AREA * pow((CURRENT_RPM / 60), 2)

func _apply_lift_force(delta):
	var y_vel = CURRENT_VELOCITY.y + CURRENT_THRUST_FORCE * (1-delta)
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

	
