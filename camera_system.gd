extends Camera2D

# --- MODES ---
enum CameraMode { DYNAMIC, FIXED }
@export var current_mode: CameraMode = CameraMode.DYNAMIC

# --- SETTINGS ---
@export_group("Motion")
@export var lerp_speed: float = 5.0
@export var look_ahead_dist: float = 100.0
@export var aim_bias: float = 0.3 

@export_group("Fixed Mode")
@export var fixed_target: Node2D # Assign a Marker2D in the scene for the camera to look at

@export_group("Shake")
@export var decay_rate: float = 2.0 
@export var max_offset: Vector2 = Vector2(30, 30) 
@export var max_roll: float = 0.1 

# --- STATE ---
var trauma: float = 0.0 
var is_aiming: bool = false
@onready var player = get_parent()

func _ready():
	# If we start in FIXED mode, SNAP instantly (no lerp)
	if current_mode == CameraMode.FIXED:
		set_mode(CameraMode.FIXED, true) 
	else:
		set_mode(CameraMode.DYNAMIC)

func _process(delta):
	match current_mode:
		CameraMode.DYNAMIC:
			_process_dynamic(delta)
		CameraMode.FIXED:
			_process_fixed(delta)
	
	apply_shake(delta)

# --- MODE LOGIC ---
func set_mode(new_mode: CameraMode, snap_to_target: bool = false):
	current_mode = new_mode
	
	if current_mode == CameraMode.FIXED:
		top_level = true # Detach from player
		
		# If a target node is assigned, use its position
		if fixed_target:
			global_position = fixed_target.global_position
			
		# If SNAP is true, we force the position immediately
		# (Note: top_level = true already disconnects us, 
		# so setting global_position above handles the snap)
		if snap_to_target:
			reset_smoothing() # Built-in Camera2D function to kill momentum

	else:
		top_level = false # Re-attach to player
		position = Vector2.ZERO # Reset local position to center on player
		if snap_to_target:
			reset_smoothing()

func _process_fixed(delta):
	if fixed_target:
		# Smoothly follow the target (in case the target moves)
		global_position = global_position.lerp(fixed_target.global_position, lerp_speed * delta)
	
	# Keep offset at zero for Fixed mode (unless shaking)
	offset = offset.lerp(Vector2.ZERO, lerp_speed * delta)

func _process_dynamic(delta):
	var desired_offset = Vector2.ZERO
	if is_aiming:
		desired_offset = get_local_mouse_position() * aim_bias
	elif player.velocity.length() > 50:
		desired_offset = player.velocity.normalized() * look_ahead_dist
	
	offset = offset.lerp(desired_offset, lerp_speed * delta)

# --- SHAKE SYSTEM (Same as before) ---
func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

func apply_shake(delta):
	if trauma > 0:
		trauma = max(trauma - decay_rate * delta, 0)
		var shake_power = trauma * trauma
		var noise_x = randf_range(-1, 1) * max_offset.x * shake_power
		var noise_y = randf_range(-1, 1) * max_offset.y * shake_power
		var noise_r = randf_range(-1, 1) * max_roll * shake_power
		
		offset += Vector2(noise_x, noise_y)
		rotation = noise_r
	else:
		rotation = lerp(rotation, 0.0, 10 * delta)
