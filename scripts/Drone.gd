extends RigidBody3D
class_name DroneController

@export var SPEED = 5.0
@export var LIFT_STRENGTH = 4.5
@export var MAX_VELOCITY:Vector3 = Vector3(100, 100, 100)
@export var Mass:float = 1.0

var propellers:Array[Propeller]

var ground: MeshInstance3D
var Current_WIND_FORCE = Vector3.ZERO

var grav_pull_default: float = 0.2
var current_grav_pull: float = grav_pull_default  # Base gravity strength
var grav_increase: float = 1.05  # Increases over time
var max_grav_force: float = 9.81  # Limit maximum gravity effect

func linear_vel():
	return linear_velocity  

func _ready():
	propellers = [$"Propeller 1", $"Propeller 2", $"Propeller 3",$"Propeller 4"]
	
	ground = $"../Ground"
	add_to_group("wind_affected")
	

func _input(event):
	if Input.is_action_just_pressed("forward"):
		propellers[2].increase_voltage(-.5)
		propellers[3].increase_voltage(-.5)
		
	if Input.is_action_just_pressed("backward"):
		propellers[2].increase_voltage(.5)
		propellers[3].increase_voltage(.5)
		
	if Input.is_action_just_pressed("up"):
		for prop in propellers:
			prop.increase_voltage(1)
			
	if Input.is_action_just_pressed("down"):
		for prop in propellers:
			prop.increase_voltage(-1)
 
func _physics_process(delta):
	linear_velocity += Current_WIND_FORCE * delta
	
	# Gradually increase gravity over time
	if global_position.y < ground.global_position.y + 1:
		current_grav_pull = grav_pull_default
		return
		
	current_grav_pull *= grav_increase
	if current_grav_pull >= max_grav_force:
		current_grav_pull = max_grav_force
	
	# Apply nonlinear gravity
	var gravity_force = Vector3(0, -current_grav_pull, 0)
	linear_velocity += gravity_force

func set_wind_force(force:Vector3):
	Current_WIND_FORCE = force
