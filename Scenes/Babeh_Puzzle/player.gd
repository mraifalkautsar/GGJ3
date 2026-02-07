extends CharacterBody2D

@onready var rod: TeleportMechanic = $TeleportMechanic

# --- PHYSICS ---
@export var gravity: float = 980.0
@export var friction: float = 800.0
@export var walk_speed: float = 200.0
@export var jump_force: float = 400.0

func _ready():
	add_to_group("Player")
	rod.teleport_requested.connect(_on_teleport_requested)
	rod.player_swap_requested.connect(swap_position_with)

func _physics_process(delta):
	# 1. Gravity
	velocity.y += gravity * delta

	# 2. Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = -jump_force

	# 3. Walk
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
	print("Player received swap request for: ", object_to_swap.name)
	var my_pos = global_transform
	var other_pos = object_to_swap.global_transform
	print("Swapping player at ", my_pos.origin, " with ", other_pos.origin)
	global_transform = other_pos
	object_to_swap.global_transform = my_pos
	print("New player position: ", global_transform.origin)
	print("New object position: ", object_to_swap.global_transform.origin)
