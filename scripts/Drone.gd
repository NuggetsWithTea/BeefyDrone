extends RigidBody3D
class_name DroneController

@export var SPEED = 5.0
@export var LIFT_STRENGTH = 4.5
@export var MAX_VELOCITY:Vector3 = Vector3(100, 100, 100)
@export var Mass:float = 1.0

var propellers:Array[Propeller]

var ground: MeshInstance3D
var Current_WIND_FORCE = Vector3.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func linear_vel():
	return linear_velocity  

func _ready():
	propellers = [$"Propeller 1", $"Propeller 2", $"Propeller 3",$"Propeller 4"]
	
	ground = $"../Ground"
	add_to_group("wind_affected")
	


func _physics_process(delta):
	# Add the gravity.
	if global_position.y > ground.global_position.y + 10:
		linear_velocity.y -= gravity * delta

	if Input.is_action_just_pressed("up"):
		for prop in propellers:
			prop.increase_voltage(1)
			
	if Input.is_action_just_pressed("down"):
		for prop in propellers:
			prop.increase_voltage(-1)
		
	linear_velocity += Current_WIND_FORCE * delta

func set_wind_force(force:Vector3):
	Current_WIND_FORCE = force
