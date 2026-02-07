extends Node2D

# --- SIGNALS ---
signal teleport_requested(target_point: Vector2)
signal player_swap_requested(object_to_swap: RigidBody2D)

@export var hook_scene: PackedScene
@onready var line_visual: Line2D = $LineVisual

enum State { IDLE, THROWN }
var current_state: State = State.IDLE
var active_hook

func _process(delta):
	look_at(get_global_mouse_position())
	update_line_visual()
	
	match current_state:
		State.IDLE:
			if Input.is_action_just_pressed("launch_hook"):
				throw_hook()
				
		State.THROWN:
			if Input.is_action_just_pressed("launch_hook"):
				if is_instance_valid(active_hook):
					redirect_hook()

func redirect_hook():
	var dir = (get_global_mouse_position() - active_hook.global_position).normalized()
	active_hook.redirect(dir)

func throw_hook():
	current_state = State.THROWN
	active_hook = hook_scene.instantiate()
	get_tree().current_scene.add_child(active_hook)
	
	active_hook.global_position = global_position
	
	# --- FIX 1: Match the signal name correctly ('hook_landed') ---
	active_hook.hook_landed.connect(_on_hook_landed)
	
	# --- FIX 2: Connect the Swap Signal ---
	active_hook.swap_requested.connect(_on_swap_requested)
	
	var dir = (get_global_mouse_position() - global_position).normalized()
	active_hook.launch(dir)

func _on_hook_landed(pos: Vector2):
	teleport_requested.emit(pos)
	reset_hook()

# --- NEW FUNCTION: Forward the swap request to the Player ---
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
		line_visual.add_point(to_local(active_hook.global_position))
