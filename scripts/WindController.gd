extends Node3D

@export var ENABLED: bool = true
@export var WIND_DIRECTION := Vector3(1, 0, 0)  # Default wind direction
@export var BASE_WIND_SPEED := 5.0  # Base wind strength
@export var TURBULENCE_STRENGTH := 2.0  # Wind variability
@export var GUST_FREQUENCY := 0.3  # Controls gustiness

var time := 0.0  # Time tracker for Perlin noise
var noise := FastNoiseLite.new()  # Create noise instance

var drone:DroneController = null

func _ready():
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN  # Use Perlin noise
	noise.frequency = 0.1  # Controls wind smoothness
	drone = $Drone

func _physics_process(delta):
	if not ENABLED:
		return
		
	time += delta  # Increment time

	# Generate smooth Perlin Noise wind variations
	var wind_noise_x = noise.get_noise_1d(time * GUST_FREQUENCY) * TURBULENCE_STRENGTH
	var wind_noise_y = noise.get_noise_1d((time + 100) * GUST_FREQUENCY) * TURBULENCE_STRENGTH
	var wind_noise_z = noise.get_noise_1d((time + 200) * GUST_FREQUENCY) * TURBULENCE_STRENGTH

	var perlin_wind = Vector3(wind_noise_x, wind_noise_y, wind_noise_z)

	# Generate stochastic gusts (random bursts of wind)
	var gusts = Vector3(
		randf_range(-1, 1) * TURBULENCE_STRENGTH if randf() < 0.1 else 0,
		randf_range(-1, 1) * TURBULENCE_STRENGTH if randf() < 0.1 else 0,
		randf_range(-1, 1) * TURBULENCE_STRENGTH if randf() < 0.1 else 0
	)

	# Combine smooth wind (Perlin Noise) and gusts (stochastic)
	var final_wind = WIND_DIRECTION * BASE_WIND_SPEED + perlin_wind + gusts

	# Apply wind force to all RigidBodies in the "wind_affected" group
	apply_wind_to_objects(final_wind)

func apply_wind_to_objects(wind_force: Vector3):
	drone.set_wind_force(wind_force)
	#for body in get_tree().get_nodes_in_group("wind_affected"):
		#if body is CharacterBody3D:
			#body.apply_central_force(wind_force)
			#print(body)
