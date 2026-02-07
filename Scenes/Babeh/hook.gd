extends RigidBody2D

signal hooked_landed(position: Vector2, collider: Object)

var is_flying: bool = true

func _integrate_forces(state):
	if not is_flying: return
	
	if state.get_contact_count() > 0:
		is_flying = false
		set_deferred("freeze", true)
		
		var landing_point = global_position
		
		var collider = state.get_contact_collider_object(0)
		
		hooked_landed.emit(landing_point, collider)

func launch(direction: Vector2, force: float):
	is_flying = true
	set_deferred("freeze", false)
	apply_central_impulse(direction * force)
