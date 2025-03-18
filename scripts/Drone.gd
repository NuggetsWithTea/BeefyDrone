extends RigidBody3D
class_name DroneController

var propellers:Array[Propeller]
var ground: MeshInstance3D
var Current_WIND_FORCE = Vector3.ZERO

func _ready():
	propellers = [$"Propeller 1", $"Propeller 2", $"Propeller 3",$"Propeller 4"]
	
	ground = $"../Ground"
	add_to_group("wind_affected")
	for p in propellers:
		p.set_voltage(4)

func _process(delta):
	var tilt = global_transform.basis.y.normalized()
	tilt.y = 0
	
	apply_central_force(tilt)
	
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
	
	
func set_wind_force(force:Vector3):
	Current_WIND_FORCE = force
