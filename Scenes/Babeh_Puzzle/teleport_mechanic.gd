extends Node2D

# --- SIGNALS ---
signal teleport_requested(target_point: Vector2)
signal player_swap_requested(object_to_swap: RigidBody2D)

@export var hook_scene: PackedScene
@onready var line_visual: Line2D = $LineVisual

# --- CONFIGURATION (New) ---
@export var max_charge: float = 1200.0 # Adjust for range
@export var charge_rate: float = 2000.0
@export var hook_attachment_offset: Vector2 = Vector2(-10, 0) # Adjust to your sprite

# --- STATES ---
enum State { IDLE, CHARGING, THROWN }
var current_state: State = State.IDLE

# --- DATA ---
var current_power: float = 0.0
var active_hook

func _process(delta):
	# Always look at mouse
	look_at(get_global_mouse_position())
	update_line_visual()
	
	match current_state:
		State.IDLE:
			if Input.is_action_just_pressed("launch_hook"):
				current_state = State.CHARGING
				current_power = 300.0 # Minimum start power
				
		State.CHARGING:
			# Increase power while holding
			current_power = move_toward(current_power, max_charge, charge_rate * delta)
			
			# Throw on release
			if Input.is_action_just_released("launch_hook"):
				throw_hook()
				
		State.THROWN:
			# Optional: Redirect feature (Teleport special)
			if Input.is_action_just_pressed("launch_hook"):
				if is_instance_valid(active_hook):
					redirect_hook()

func redirect_hook():
	var dir = (get_global_mouse_position() - active_hook.global_position).normalized()
	# Redirect uses current speed or fixed speed? Let's use a boost.
	active_hook.redirect(dir, max_charge)

func throw_hook():
	current_state = State.THROWN
	active_hook = hook_scene.instantiate()
	get_tree().current_scene.add_child(active_hook)
	
	active_hook.global_position = global_position
	
	# Connect Signals
	active_hook.hook_landed.connect(_on_hook_landed)
	active_hook.swap_requested.connect(_on_swap_requested)
	
	# Launch with CHARGED POWER
	var dir = (get_global_mouse_position() - global_position).normalized()
	active_hook.launch(dir, current_power)

func _on_hook_landed(pos: Vector2):
	teleport_requested.emit(pos)
	reset_hook()

func _on_swap_requested(target_object: RigidBody2D):
	player_swap_requested.emit(target_object)
	reset_hook()

func reset_hook():
	if is_instance_valid(active_hook):
		active_hook.queue_free()
	active_hook = null
	current_state = State.IDLE

func update_line_visual():
	line_visual.clear_points()
	line_visual.add_point(Vector2.ZERO)
	if is_instance_valid(active_hook):
		# Use the offset logic for better visuals
		var global_attach = active_hook.to_global(hook_attachment_offset)
		line_visual.add_point(to_local(global_attach))
