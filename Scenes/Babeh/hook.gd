extends RigidBody2D

signal hooked_landed(position: Vector2)

var is_flying: bool = true

func _integrate_forces(state):
	# Only run collision logic if we are currently flying
	if not is_flying: return
	
	# If we touched something
	if state.get_contact_count() > 0:
		# 1. Stop Moving
		is_flying = false
		set_deferred("freeze", true) # Locks the physics body in place
		
		# 2. Get the contact point
		# We use the object's global position to keep it simple and safe
		var landing_point = global_position
		
		# 3. Tell the Rod we hit something
		hooked_landed.emit(landing_point)

func launch(direction: Vector2, force: float):
	is_flying = true
	set_deferred("freeze", false)
	apply_central_impulse(direction * force)
