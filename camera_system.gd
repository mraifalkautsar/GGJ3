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
@export var fixed_target: Node2D 

@export_group("Shake")
@export var decay_rate: float = 2.0 
@export var max_offset: Vector2 = Vector2(30, 30) 
@export var max_roll: float = 0.1 

# --- STATE ---
var trauma: float = 0.0 
var is_aiming: bool = false

# RENAMED 'player' to 'follow_target' to be more generic
@onready var follow_target: Node2D = get_parent()

func _ready():
	if current_mode == CameraMode.FIXED:
		set_mode(CameraMode.FIXED, true) 
	else:
		set_mode(CameraMode.DYNAMIC)

func _process(delta):
	# SAFETY CHECK: If target is gone, stop processing to avoid crash
	if not is_instance_valid(follow_target) and current_mode == CameraMode.DYNAMIC:
		return

	match current_mode:
		CameraMode.DYNAMIC:
			_process_dynamic(delta)
		CameraMode.FIXED:
			_process_fixed(delta)
	
	apply_shake(delta)

# --- NEW FUNCTION: Call this when switching to Ragdoll ---
func switch_target(new_target: Node2D):
	follow_target = new_target
	
	# 1. IMPORTANT: Turn off top_level so it moves with the parent
	top_level = false 
	
	# 2. Reset the position so it snaps to the center of the Ragdoll
	position = Vector2.ZERO 
	
	# 3. Kill any smoothing momentum so it doesn't "drift" to the new target
	reset_smoothing()

# --- MODE LOGIC ---
func set_mode(new_mode: CameraMode, snap_to_target: bool = false):
	current_mode = new_mode
	
	if current_mode == CameraMode.FIXED:
		top_level = true 
		if fixed_target:
			global_position = fixed_target.global_position
		if snap_to_target:
			reset_smoothing() 
	else:
		top_level = false 
		position = Vector2.ZERO 
		if snap_to_target:
			reset_smoothing()

func _process_fixed(delta):
	if fixed_target:
		global_position = global_position.lerp(fixed_target.global_position, lerp_speed * delta)
	offset = offset.lerp(Vector2.ZERO, lerp_speed * delta)

func _process_dynamic(delta):
	var desired_offset = Vector2.ZERO
	var target_velocity = Vector2.ZERO
	
	# --- HYBRID VELOCITY CHECK ---
	# Player uses .velocity, Ragdoll (RigidBody) uses .linear_velocity
	if "velocity" in follow_target:
		target_velocity = follow_target.velocity
	elif "linear_velocity" in follow_target:
		target_velocity = follow_target.linear_velocity
	
	# Logic uses the detected velocity
	if is_aiming:
		desired_offset = get_local_mouse_position() * aim_bias
	elif target_velocity.length() > 50:
		desired_offset = target_velocity.normalized() * look_ahead_dist
	
	offset = offset.lerp(desired_offset, lerp_speed * delta)

# --- SHAKE SYSTEM ---
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
