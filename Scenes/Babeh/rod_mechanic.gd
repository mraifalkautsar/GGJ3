class_name RodMechanic extends Node2D

# --- SIGNALS ---
# This tells the player: "Launch towards this point NOW!"
signal launch_requested(target_point: Vector2)

# --- CONFIGURATION ---
@export var hook_scene: PackedScene 
@onready var line_visual: Line2D = $LineVisual

@export var max_charge: float = 1000.0
@export var charge_rate: float = 2000.0

# --- STATES ---
enum State { IDLE, CHARGING, THROWN } # Removed "HOOKED"
var current_state: State = State.IDLE

# --- DATA ---
var current_power: float = 0.0
var active_hook: RigidBody2D = null

func _process(delta):
	look_at(get_global_mouse_position())
	update_line_visual()
	
	match current_state:
		State.IDLE:
			if Input.is_action_just_pressed("Jump"): 
				current_state = State.CHARGING
				current_power = 200.0 
				
		State.CHARGING:
			current_power = move_toward(current_power, max_charge, charge_rate * delta)
			
			if Input.is_action_just_released("Jump"):
				throw_hook()
				
		State.THROWN:
			# If player clicks while hook is flying, cancel it
			if Input.is_action_just_pressed("Jump"):
				reset_rod()

func throw_hook():
	current_state = State.THROWN
	active_hook = hook_scene.instantiate()
	get_tree().current_scene.add_child(active_hook)
	
	active_hook.global_position = global_position
	# Connect the hook's signal to our handler
	active_hook.hooked_landed.connect(_on_hook_landed)
	
	var dir = (get_global_mouse_position() - global_position).normalized()
	active_hook.launch(dir, current_power)

func _on_hook_landed(pos: Vector2):
	# 1. TRIGGER THE LAUNCH
	# We send the position to the PlayerController
	launch_requested.emit(pos)
	
	# 2. DISCONNECT IMMEDIATELY
	reset_rod()

func reset_rod():
	if is_instance_valid(active_hook):
		active_hook.queue_free()
	active_hook = null
	current_state = State.IDLE
	current_power = 0.0

func update_line_visual():
	line_visual.clear_points()
	line_visual.add_point(Vector2.ZERO)
	if is_instance_valid(active_hook):
		line_visual.add_point(to_local(active_hook.global_position))
