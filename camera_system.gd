extends Camera2D

# --- SETTINGS ---
@export_group("Motion")
@export var lerp_speed: float = 5.0
@export var look_ahead_dist: float = 100.0 # How far to pan when moving fast
@export var aim_bias: float = 0.3 # 0.0 = Player Center, 1.0 = Mouse Position

@export_group("Shake")
@export var decay_rate: float = 2.0 # How fast shake stops
@export var max_offset: Vector2 = Vector2(30, 30) # Max shake in pixels
@export var max_roll: float = 0.1 # Max rotation in radians

# --- STATE ---
var target_offset: Vector2 = Vector2.ZERO
var trauma: float = 0.0 # Current shake intensity (0.0 to 1.0)
var is_aiming: bool = false

# Access Player (Camera must be child of Player)
@onready var player = get_parent()

func _ready():
	# Ensure smooth dragging is disabled so we can control it manually via offset
	position_smoothing_enabled = false 

func _process(delta):
	# 1. CALCULATE DESIRED OFFSET
	var desired_offset = Vector2.ZERO
	
	# 2. SMOOTHLY MOVE CAMERA (LERP)
	# We modify the 'offset' property of the Camera2D, not the position
	offset = offset.lerp(desired_offset, lerp_speed * delta)
	
	# 3. APPLY SHAKE
	apply_shake(delta)

# --- SHAKE SYSTEM ---
func add_trauma(amount: float):
	# Add trauma (clamped to 1.0)
	trauma = min(trauma + amount, 1.0)

func apply_shake(delta):
	if trauma > 0:
		# Decrease trauma over time
		trauma = max(trauma - decay_rate * delta, 0)
		
		# Shake calculation (Square the trauma for "juicier" feel)
		# Weak trauma = tiny shake. High trauma = massive shake.
		var shake_power = trauma * trauma
		
		# Generate random noise
		var noise_x = randf_range(-1, 1) * max_offset.x * shake_power
		var noise_y = randf_range(-1, 1) * max_offset.y * shake_power
		var noise_r = randf_range(-1, 1) * max_roll * shake_power
		
		# Apply on top of the smooth offset
		offset += Vector2(noise_x, noise_y)
		rotation = noise_r
	else:
		# Reset rotation when not shaking
		rotation = lerp(rotation, 0.0, 10 * delta)
