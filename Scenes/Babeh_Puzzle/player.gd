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

# --- MECHANIC SPECS ---
@export var pull_strength: float = 800.0 # Force for pulling light objects
@export var heavy_mass_threshold: float = 5.0 # Objects lighter than this get pulled

@export var ragdoll_scene: PackedScene

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
		if is_on_floor() and not running_sound.playing:
			running_sound.play()
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		if running_sound.playing:
			running_sound.stop()
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
	# Create afterimage at current position before teleporting
	create_afterimage()
	
	global_position = target_point
	velocity = Vector2.ZERO
	
	# Create arrival particles at new position
	create_teleport_particles(target_point)
	
	teleport_sound.play()

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

func die(damage_source_pos: Vector2 = Vector2.ZERO):
	death_sound.play()
	if ragdoll_scene:
		var ragdoll = ragdoll_scene.instantiate()
		get_tree().current_scene.add_child(ragdoll)
		
		# 1. Setup Ragdoll (Your existing code)
		var is_facing_left = animated_sprite_2d.flip_h
		var current_anim = animated_sprite_2d.animation
		var current_frame = animated_sprite_2d.frame
		var current_scale = scale
		ragdoll.setup(global_position, velocity, is_facing_left, current_anim, current_frame, current_scale)
		
		# 2. Knockback (Your existing code)
		if damage_source_pos != Vector2.ZERO:
			var knock_dir = (global_position - damage_source_pos).normalized()
			ragdoll.apply_central_impulse(knock_dir * 1000)

		# --- 3. CAMERA TRANSFER (CRITICAL STEP) ---
		# Check if we have the camera node
		if has_node("CameraSystem"):
			var cam = $CameraSystem
			
			# A. Detach from Player (so it doesn't get deleted)
			remove_child(cam)
			
			# B. Attach to Ragdoll
			ragdoll.add_child(cam)
			
			# C. Tell Camera about the new parent
			cam.switch_target(ragdoll)

	# 4. Goodbye Player
	queue_free()
