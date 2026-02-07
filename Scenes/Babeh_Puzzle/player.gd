extends CharacterBody2D

@onready var rod = $AnimatedSprite2D/TeleportMechanic
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# --- AUDIO ---
@onready var teleport_sound = $Teleport
@onready var running_sound = $Running
@onready var death_sound = $Death

# --- PHYSICS ---
@export var gravity: float = 980.0
@export var friction: float = 800.0
@export var walk_speed: float = 200.0

func _ready():
	add_to_group("Player")
	rod.teleport_requested.connect(_on_teleport_requested)
	rod.player_swap_requested.connect(swap_position_with)

func _physics_process(delta):
	velocity.y += gravity * delta
	var dir = Input.get_axis("Move_Left", "Move_Right")
	if dir:
		velocity.x = move_toward(velocity.x, dir * walk_speed, 1000 * delta)
		if is_on_floor() and not running_sound.playing:
			running_sound.play()
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		if running_sound.playing:
			running_sound.stop()
	move_and_slide()
	
	update_animations(dir)

func update_animations(input_dir: float):
	# A. FACE MOUSE
	var mouse_pos = get_global_mouse_position()
	animated_sprite_2d.flip_h = (mouse_pos.x >= global_position.x)
	
	# B. ROD ACTIONS (Now includes Charging)
	if rod.current_state == rod.State.CHARGING:
		if animated_sprite_2d.animation != "reel":
			animated_sprite_2d.play("reel")
		return

	if rod.current_state == rod.State.THROWN:
		if animated_sprite_2d.animation != "throw":
			animated_sprite_2d.play("throw")
		return 

	# C. STANDARD MOVEMENT
	if not is_on_floor():
		# animated_sprite_2d.play("jump")
		pass
	elif input_dir != 0:
		animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("default")

func _on_teleport_requested(target_point: Vector2):
	global_position = target_point
	velocity = Vector2.ZERO
	teleport_sound.play()

func swap_position_with(object_to_swap: RigidBody2D):
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

	teleport_sound.play()

func die():
	death_sound.play()
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
