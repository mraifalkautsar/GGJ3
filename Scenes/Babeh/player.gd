extends CharacterBody2D

@onready var rod_mechanic: RodMechanic = $RodMechanic
@onready var camera_system: Camera2D = $CameraSystem

# --- PHYSICS ---
@export var gravity: float = 980.0
@export var friction: float = 800.0
@export var walk_speed: float = 200.0

# --- SPECS ---
@export var max_pull_power: float = 1200.0 
@export var max_lift_power: float = 600.0 

func _ready():
	rod_mechanic.launch_requested.connect(_on_rod_launch)

func _physics_process(delta):
	# ... (Keep gravity and walking logic exactly the same) ...
	velocity.y += gravity * delta
	var dir = Input.get_axis("ui_left", "ui_right")
	if dir:
		velocity.x = move_toward(velocity.x, dir * walk_speed, 1000 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	move_and_slide()
	camera_system.is_aiming = (rod_mechanic.current_state == rod_mechanic.State.CHARGING)

# --- THE CORE BRAIN ---
func _on_rod_launch(target_point: Vector2, charge_ratio: float, target_body: Node):
	
	# APPROACH 3: WRONG TOOL FOR THE JOB (Interactions)
	# If the object has a function "on_hooked", run it and STOP movement.
	if target_body.has_method("on_hooked"):
		target_body.on_hooked()
		return # Do not move the player
		
	# APPROACH 2: ENVIRONMENTAL PRANKSTER (Traps)
	# Check for specific Groups
	if target_body.is_in_group("bouncy"):
		apply_repel_force(target_point, charge_ratio)
		return
	
	# APPROACH 1: PHYSICS BETRAYAL (Mass Check)
	# If it's a RigidBody (Physics Object) and it's light...
	if target_body is RigidBody2D:
		# Assume objects < 5kg are "Light"
		if target_body.mass < 5.0:
			pull_object_to_me(target_body, charge_ratio)
			return

	# DEFAULT BEHAVIOR: Pull Player to Target
	pull_player_to_target(target_point, charge_ratio)

# --- HELPER FUNCTIONS ---

func pull_player_to_target(target_point: Vector2, charge_ratio: float):
	var pull_dir = (target_point - global_position).normalized()
	if velocity.y > 0: velocity.y = 0 # Crisp catch
	
	var power = max_pull_power * clamp(charge_ratio, 0.4, 1.0)
	var lift = max_lift_power * clamp(charge_ratio, 0.4, 1.0)
	
	# Floor Vault Optimization
	if pull_dir.y > 0: 
		pull_dir.y = 0
		lift *= 1.5
		
	velocity += (pull_dir * power) + (Vector2.UP * lift)
	
	camera_system.add_trauma(0.5 * charge_ratio)
	limit_speed()

func pull_object_to_me(body: RigidBody2D, charge_ratio: float):
	var dir_to_me = (global_position - body.global_position).normalized()
	var strength = max_pull_power * charge_ratio * 1.5
	
	# Yank the object towards us
	body.apply_central_impulse(dir_to_me * strength)
	
	# Tiny recoil for player
	velocity -= dir_to_me * 200

func apply_repel_force(target_point: Vector2, charge_ratio: float):
	# Used for "Bouncy" walls - Fling player BACKWARDS
	var dir_away = (global_position - target_point).normalized()
	velocity = dir_away * max_pull_power * 1.5 # Super bounce
	camera_system.add_trauma(0.8)

func limit_speed():
	if velocity.length() > 1500:
		velocity = velocity.normalized() * 1500
