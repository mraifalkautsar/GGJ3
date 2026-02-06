extends CharacterBody2D

@onready var rod: RodMechanic = $RodMechanic
@onready var camera: Camera2D = $CameraSystem

# --- PHYSICS ---
@export var gravity: float = 980.0
@export var friction: float = 800.0
@export var walk_speed: float = 200.0

# --- YANK SPECS ---
# The main force pulling you to the hook
@export var pull_power: float = 500.0 

# The "Another Force" (The vertical flick)
# This lifts you up slightly every time you hook, like a fisherman yanking the rod.
@export var lift_power: float = 300.0 

func _ready():
	rod.launch_requested.connect(_on_rod_launch)

func _physics_process(delta):
	# 1. Gravity
	velocity.y += gravity * delta
	
	# 2. Walk
	var dir = Input.get_axis("ui_left", "ui_right")
	if dir:
		velocity.x = move_toward(velocity.x, dir * walk_speed, 1000 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()
	
	camera.is_aiming = (rod.current_state == rod.State.CHARGING)

# --- THE "FISHERMAN YANK" LOGIC ---
func _on_rod_launch(target_point: Vector2):
	# 1. Get the Pull Direction (Straight to hook)
	var pull_dir = (target_point - global_position).normalized()
	
	# 2. Reset Vertical Velocity? (Optional)
	# If falling fast, kill the fall speed so the yank feels crisp
	if velocity.y > 0:
		velocity.y = 0
	
	# 3. APPLY FORCES
	# Force A: Pull towards hook
	var force_a = pull_dir * pull_power
	
	# Force B: The "Another Force" (Vertical Lift)
	# We always add an upward kick, regardless of where you aimed
	var force_b = Vector2.UP * lift_power
	
	# Combine them (Impulse)
	# Using += blends this force with your current movement
	velocity += force_a + force_b
	
	camera.add_trauma(0.6)
	
	# 4. Cap Speed (Prevents game-breaking speed stacking)
	# If the yank makes us too fast, clamp it
	if velocity.length() > 1500:
		velocity = velocity.normalized() * 1500
