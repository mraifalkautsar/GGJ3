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
	# Create afterimage at current position before teleporting
	create_afterimage()
	
	global_position = target_point
	velocity = Vector2.ZERO
	
	# Create arrival particles at new position
	create_teleport_particles(target_point)
	
	teleport_sound.play()

func swap_position_with(object_to_swap: RigidBody2D):
	object_to_swap.linear_velocity = Vector2.ZERO
	object_to_swap.angular_velocity = 0
	
	var player_pos = global_position
	var target_pos = object_to_swap.global_position
	
	# Create afterimage at current position before swapping
	create_afterimage()
	
	global_position = target_pos
	velocity = Vector2.ZERO
	
	var transform = object_to_swap.global_transform
	transform.origin = player_pos + Vector2(0, -5) 
	
	PhysicsServer2D.body_set_state(
		object_to_swap.get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		transform
	)

	# Create arrival particles at new position
	create_teleport_particles(target_pos)

	teleport_sound.play()

func create_afterimage():
	# Create a ghost sprite at current position
	var ghost = Sprite2D.new()
	ghost.texture = animated_sprite_2d.sprite_frames.get_frame_texture(animated_sprite_2d.animation, animated_sprite_2d.frame)
	ghost.global_position = global_position
	ghost.scale = scale
	ghost.flip_h = animated_sprite_2d.flip_h
	ghost.modulate = Color(0.5, 0.8, 1.0, 0.6)  # Blue tint
	ghost.z_index = z_index - 1
	
	get_tree().current_scene.add_child(ghost)
	
	# Fade out and delete
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.5)
	tween.tween_callback(ghost.queue_free)
	
	# Add particle burst effect
	create_teleport_particles(global_position)

func create_teleport_particles(pos: Vector2):
	var particles = CPUParticles2D.new()
	particles.global_position = pos
	particles.amount = 20
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 50.0
	particles.direction = Vector2(0, 0)
	particles.spread = 180
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.gravity = Vector2(0, 0)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.5, 0.8, 1.0, 0.8)
	
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	
	# Clean up after emission
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()

func die():
	death_sound.play()
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
