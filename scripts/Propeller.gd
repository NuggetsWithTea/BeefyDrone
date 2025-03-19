extends Node3D
class_name Propeller

@export var THRUST_COEFFICIENT: float = 0.1  # Adjust for stronger lift
@export var AIR_DENSITY: float = 1.225  # kg/m³ (Default air density)
@export var SPEED_CONSTANT: int = 5  # KV rating of motor
@export var DISC_AREA: float = 0.05  # m² (based on propeller size)
@export var MAX_VOLTAGE:float = 5.0
@export var MAX_VELOCITY:Vector3 = Vector3(100, 100, 100)
@export var VELOCITY_DECAY:float = 0.75

@export var SEA_LEVEL_DENSITY: float = 1.225  # kg/m³
@export var SEA_LEVEL_STANDARD_TEMPERATURE_C: float = 15.0  # °C
@export var TEMPERATURE_DROP_RATE: float = 0.65  # K per meter
@export var MOLAR_MASS: float = 0.02896
@export var UNIVERSAL_GAS_CONSTANT: float = 8.314

var CURRENT_RPM: int = 0
var CURRENT_VOLTAGE: float = 0.0
var CURRENT_THRUST_FORCE: float = 0.0
var CURRENT_ANGLE = 0
var IS_ROTATION_REVERSED: bool = false

#use these values in other scripts 
var CURRENT_APPLIED_FORCE: Vector3 = Vector3.ZERO

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

	if CURRENT_VOLTAGE == 0:
		return
		
	var alt = global_position.y
	var ground = get_ground_effect(alt)
	calc_applied_force(delta, ground)
	
	var angular_speed = (CURRENT_RPM * 2 * PI) / 60
	rotate_y(angular_speed * delta)
	
func air_density() -> float:
	var T0 = SEA_LEVEL_STANDARD_TEMPERATURE_C + 273.15  # convert °C to K
	
	# The exponent from the barometric formula
	var exponent_val = ((DRONE.GRAVITY * MOLAR_MASS) * DRONE.mass) / (UNIVERSAL_GAS_CONSTANT * TEMPERATURE_DROP_RATE)

	# base term: (1 - L*h / T0)
	var base_term = 1-(TEMPERATURE_DROP_RATE * DRONE.CURRENT_ALTITUDE / T0)
	
	# If base_term is <= 0, it means altitude is beyond formula's range.
	if base_term <= 0:
		#hacky lösung. nochmal richtig machen
		return 0.2
	
	# Raise base_term to exponent_val, multiply by sea-level density
	return SEA_LEVEL_DENSITY * pow(base_term, exponent_val)
	
func get_ground_effect(altitude: float) -> float:
	var ground_effect_threshold = DISC_AREA * 2  # Max altitude for ground effect
	var max_boost = 1.3  # Boost factor when very close

	if DRONE.CURRENT_ALTITUDE >= ground_effect_threshold:
		return 1.0  # No boost at higher altitudes

	#linear decay based on altitude
	var t = clamp(altitude / ground_effect_threshold, 0.0, 1.0)
	var boost = lerp(max_boost, 1.0, t)  # Fades from max_boost at 0 altitude to 1.0 at threshold

	#print(boost)
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
		CURRENT_RPM = CURRENT_RPM * .95
		return
		
	CURRENT_RPM = (CURRENT_VOLTAGE * SPEED_CONSTANT) * 60
	if IS_ROTATION_REVERSED:
		CURRENT_RPM = -CURRENT_RPM

func _thrust():
	if CURRENT_RPM == 0:
		CURRENT_THRUST_FORCE = 0
		return
		
	var current_air_density = air_density()
	# Thrust calculation
	CURRENT_THRUST_FORCE = THRUST_COEFFICIENT * current_air_density  * DISC_AREA * pow((CURRENT_RPM / 60), 2)

func calc_applied_force(delta, ground_effect):
	var y_vel: float = CURRENT_VELOCITY.y + CURRENT_THRUST_FORCE * (1-delta) * ground_effect
	var force = Vector3(CURRENT_VELOCITY.x, y_vel, CURRENT_VELOCITY.z)
	CURRENT_APPLIED_FORCE = force 
	
