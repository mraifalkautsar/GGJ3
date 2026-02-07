extends RigidBody2D

signal hook_landed(position: Vector2)
signal swap_requested(object_to_swap: Node2D)

func _ready():
	contact_monitor = true
	max_contacts_reported = 1

func _integrate_forces(state):
	# Rotation Logic (Face direction of travel)
	if linear_velocity.length() > 10.0:
		rotation = linear_velocity.angle()

	# Collision Logic
	if state.get_contact_count() > 0:
		var collider = state.get_contact_collider_object(0)
		
		if collider.is_in_group("walls") or collider is TileMap:
			set_deferred("freeze", true)
			hook_landed.emit(global_position)
			
		elif collider.is_in_group("swappable"):
			# Wake up if sleeping
			if collider is RigidBody2D: collider.sleeping = false
			
			swap_requested.emit(collider)
			queue_free()

func launch(direction: Vector2, force: float):
	# ENABLE GRAVITY for the arc (Standard Fishing Rod Feel)
	gravity_scale = 1.0 
	apply_central_impulse(direction * force)

func redirect(direction: Vector2, force: float):
	# Zero out velocity for a sharp turn
	linear_velocity = Vector2.ZERO
	apply_central_impulse(direction * force)
