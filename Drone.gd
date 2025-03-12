extends CharacterBody3D
class_name DroneController

@export var SPEED = 5.0
@export var LIFT_STRENGTH = 4.5

var current_wind_force = Vector3.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("wind_affected")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_pressed("up"):
		velocity.y = LIFT_STRENGTH
	
	if Input.is_action_pressed("down"):
		velocity.y = -LIFT_STRENGTH

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("forward", "backward", "right", "left")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	velocity += current_wind_force * delta
	
	move_and_slide()

func set_wind_force(force:Vector3):
	current_wind_force = force
