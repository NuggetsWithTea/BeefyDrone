extends RigidBody3D
class_name Propeller

@export var THRUST_COEFFICIENT: float = 0.1  # Adjust for stronger lift
@export var AIR_DENSITY: float = 1.225  # kg/m³ (Default air density)
@export var SPEED_CONSTANT: int = 1000  # KV rating of motor
@export var DISC_AREA: float = 0.05  # m² (based on propeller size)
@export var DRAG_COEFFICIENT: float = 0.1  # Air resistance
@export var MASS: float = 1.0  # Mass of drone

var CURRENT_VOLTAGE: float = 0.0
var CURRENT_RPM: float = 0.0
var CURRENT_THRUST_FORCE: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	CURRENT_VOLTAGE = 0.0
	CURRENT_RPM = 0.0

# Called every physics frame.
func _physics_process(delta):
	_rpm()
	_thrust(delta)
	_apply_lift_force(delta)
	_apply_drag(delta)
	
	var angular_speed = (CURRENT_RPM * 2 * PI) / 60
	rotate_y(angular_speed * delta)
	
func increase_voltage(voltage:float):
	CURRENT_VOLTAGE += voltage

func set_voltage(voltage: float):
	CURRENT_VOLTAGE = voltage

func _rpm():
	if CURRENT_VOLTAGE == 0:
		CURRENT_RPM = 0
		return
		
	CURRENT_RPM = (CURRENT_VOLTAGE / SPEED_CONSTANT) * 60

func _thrust(delta):
	if CURRENT_RPM == 0:
		CURRENT_THRUST_FORCE = 0
		return
	# Thrust calculation
	CURRENT_THRUST_FORCE = THRUST_COEFFICIENT * AIR_DENSITY * DISC_AREA * pow((CURRENT_RPM / 60), 2)

func _apply_lift_force(delta):
	# Apply force in local upward direction (Y-axis)
	var lift_force = Vector3(0, CURRENT_THRUST_FORCE, 0)
	
	# Apply force at center to lift drone
	apply_central_force(lift_force)

func _apply_drag(delta):
	# Air resistance: opposes the direction of movement
	var velocity = linear_velocity
	var drag_force = -velocity * DRAG_COEFFICIENT  # Opposes motion
	apply_central_force(drag_force)

	# Optional: Ensure drone doesn't rise indefinitely
	if linear_velocity.y > 10:
		linear_velocity.y = 10  
