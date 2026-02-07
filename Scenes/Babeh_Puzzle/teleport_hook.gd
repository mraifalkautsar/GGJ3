extends RigidBody2D

signal hook_landed(position: Vector2)
signal swap_requested(object_to_swap: Node2D)

func _integrate_forces(state):
	# If we touched something
	if state.get_contact_count() > 0:
		var collider = state.get_contact_collider_object(0)
		if collider.is_in_group("walls") or collider is TileMap:
			# 1. Stop Moving
			set_deferred("freeze", true) # Locks the physics body in place

			# 2. Get the contact point
			var landing_point = global_position

			# 3. Tell the Mechanic we hit something
			hook_landed.emit(landing_point)
		elif collider.is_in_group("swappable"):
			print("Hook hit a swappable object: ", collider.name)
			swap_requested.emit(collider)
			queue_free()

func launch(direction: Vector2):
	gravity_scale = 0
	apply_central_impulse(direction * 300)

func redirect(direction: Vector2):
	linear_velocity = Vector2.ZERO
	apply_central_impulse(direction * 300)
