extends MeshInstance3D

@onready var drone = $"../.."

func _process(delta):
	if !drone:
		return

	var mesh = ImmediateMesh.new()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Log the force values to debug
	print("Current Drag: ", drone.CURRENT_DRAG)
	print("Current Wind Force: ", drone.Current_WIND_FORCE)
	
	# Draw drag force (Red)
	draw_arrow(mesh, Vector3.ZERO, drone.CURRENT_DRAG * 100, Color.RED)

	# Draw wind force (Blue)
	draw_arrow(mesh, Vector3.ZERO, drone.Current_WIND_FORCE * 100, Color.BLUE)

	# Draw lift force from propellers (Green)
	
	var total_lift = Vector3.ZERO
	for prop in drone.propellers:
		total_lift += prop.CURRENT_APPLIED_FORCE

	print("Total Lift: ", total_lift)  # Debug lift force

	draw_arrow(mesh, Vector3.ZERO, total_lift * 100, Color.GREEN)

	mesh.surface_end()

	# Use set_mesh() instead of mesh_override
	set_mesh(mesh)

func draw_arrow(mesh, start: Vector3, end: Vector3, color: Color):
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
