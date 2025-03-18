extends Camera3D

var drone: DroneController
var offset: Vector3
# Called when the node enters the scene tree for the first time.
func _ready():
	drone = $".."
	offset = drone.global_position - global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = drone.global_position - offset
