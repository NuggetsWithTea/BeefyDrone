extends CanvasLayer

@onready var label_height = $VBoxContainer/Label_Height
@onready var label_yaw = $VBoxContainer/Label_Yaw
@onready var label_speed = $VBoxContainer/Label_Speed
@onready var label_volt = $VBoxContainer/Label_Volt
@onready var label_p1 = $VBoxContainer/Label_P1
@onready var label_p2 = $VBoxContainer/Label_P2
@onready var label_p3 = $VBoxContainer/Label_P3
@onready var label_p4 = $VBoxContainer/Label_P4
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
	
	# Update voltage
	for prop in drone.propellers:
		var volt = prop.CURRENT_VOLTAGE
		label_volt.text = "Voltage: %.2f V" % volt
		
	# Update labels for each propeller
	if drone.propellers.size() >= 4:
		label_p1.text = "P1 Voltage: %.2f V" % drone.propellers[0].CURRENT_VOLTAGE
		label_p2.text = "P2 Voltage: %.2f V" % drone.propellers[1].CURRENT_VOLTAGE
		label_p3.text = "P3 Voltage: %.2f V" % drone.propellers[2].CURRENT_VOLTAGE
		label_p4.text = "P4 Voltage: %.2f V" % drone.propellers[3].CURRENT_VOLTAGE
