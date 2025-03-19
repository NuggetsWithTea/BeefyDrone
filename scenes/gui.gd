extends CanvasLayer

@onready var label_height = $VBoxContainer/Label_Height
@onready var label_yaw = $VBoxContainer/Label_Yaw
@onready var label_speed = $VBoxContainer/Label_Speed
@onready var drone = $"../Drone"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Update the labels with the relevant data
	update_hud()

func update_hud():
	# Update height (altitude)
	label_height.text = "Height: %.2f m" % drone.CURRENT_ALTITUDE
	
	# Update yaw (rotation around the Y-axis, in degrees)
	var yaw = drone.global_rotation.y
	label_yaw.text = "Yaw: %.2f°" % rad_to_deg(yaw)
	
	# Update speed (linear velocity)
	var speed = drone.linear_velocity.length()
	label_speed.text = "Speed: %.2f m/s" % speed
