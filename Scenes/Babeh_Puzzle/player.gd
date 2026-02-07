extends CharacterBody2D

@onready var rod = $TeleportMechanic

@export var gravity: float = 980.0
@export var friction: float = 800.0
@export var walk_speed: float = 200.0
@export var jump_force: float = 400.0

func _ready():
	add_to_group("Player")
	# 1. Connect Teleport (Existing)
	rod.teleport_requested.connect(_on_teleport_requested)
	
	# 2. Connect Swap (FIX ADDED HERE)
	rod.player_swap_requested.connect(swap_position_with)

func _physics_process(delta):
	velocity.y += gravity * delta

	var dir = Input.get_axis("Move_Left", "Move_Right")
	if dir:
		velocity.x = move_toward(velocity.x, dir * walk_speed, 1000 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()

func _on_teleport_requested(target_point: Vector2):
	global_position = target_point
	velocity = Vector2.ZERO

func swap_position_with(object_to_swap: RigidBody2D):
	# 1. Stop the object's previous momentum so it doesn't fly away after swap
	object_to_swap.linear_velocity = Vector2.ZERO
	object_to_swap.angular_velocity = 0
	
	# 2. Capture positions
	var player_pos = global_position
	var target_pos = object_to_swap.global_position
	
	# 3. Move Player
	global_position = target_pos
	velocity = Vector2.ZERO
	
	# 4. Move Object using the Physics Server (The "Golden Way")
	# This prevents the "snapping back" glitch
	var transform = object_to_swap.global_transform
	transform.origin = player_pos + Vector2(0, -5)
	
	PhysicsServer2D.body_set_state(
		object_to_swap.get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		transform
	)
