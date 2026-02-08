extends CharacterBody2D

@onready var rod = $AnimatedSprite2D/TeleportMechanic
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# --- PHYSICS ---
@export var gravity: float = 980.0
@export var friction: float = 800.0
@export var walk_speed: float = 200.0

# --- MECHANIC SPECS ---
@export var pull_strength: float = 800.0 # Force for pulling light objects
@export var heavy_mass_threshold: float = 5.0 # Objects lighter than this get pulled

func _ready():
	add_to_group("Player")
	rod.teleport_requested.connect(_on_teleport_requested)
	
	# UPDATED: Connect to a "Decision Maker" function instead of directly to swap
	rod.player_swap_requested.connect(_decide_object_interaction)

func _physics_process(delta):
	velocity.y += gravity * delta
	var dir = Input.get_axis("Move_Left", "Move_Right")
	if dir:
		velocity.x = move_toward(velocity.x, dir * walk_speed, 1000 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	move_and_slide()
	
	update_animations(dir)

func update_animations(input_dir: float):
	var mouse_pos = get_global_mouse_position()
	animated_sprite_2d.flip_h = (mouse_pos.x >= global_position.x)
	
	if rod.current_state == rod.State.CHARGING:
		if animated_sprite_2d.animation != "reel": animated_sprite_2d.play("reel")
		return
	if rod.current_state == rod.State.THROWN:
		if animated_sprite_2d.animation != "throw": animated_sprite_2d.play("throw")
		return 

	if not is_on_floor():
		pass # Add jump/fall here
	elif input_dir != 0:
		animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("default")

# --- CORE MECHANIC LOGIC ---

func _on_teleport_requested(target_point: Vector2):
	global_position = target_point
	velocity = Vector2.ZERO

# NEW: The Decision Maker
func _decide_object_interaction(target_object: RigidBody2D):
	# DECISION TREE:
	# 1. Is it heavy? -> Swap (Teleport)
	# 2. Is it light? -> Pull (Fishing)
	
	if target_object.mass < heavy_mass_threshold:
		pull_object_to_me(target_object)
	else:
		swap_position_with(target_object)

# OPTION A: PULL (Fishing Style)
func pull_object_to_me(body: RigidBody2D):
	print("Yanking object!")
	var dir_to_me = (global_position - body.global_position).normalized()
	
	body.global_position.y -= 2.0 
	
	body.linear_velocity = dir_to_me * 800.0

# OPTION B: SWAP (Teleport Style)
func swap_position_with(object_to_swap: RigidBody2D):
	print("Object is heavy! Swapping...")
	object_to_swap.linear_velocity = Vector2.ZERO
	object_to_swap.angular_velocity = 0
	
	var player_pos = global_position
	var target_pos = object_to_swap.global_position
	
	global_position = target_pos
	velocity = Vector2.ZERO
	
	var transform = object_to_swap.global_transform
	transform.origin = player_pos + Vector2(0, -5) 
	
	PhysicsServer2D.body_set_state(
		object_to_swap.get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		transform
	)
