class_name Hook
extends RigidBody2D

signal hook_landed(position: Vector2)

const MOVE_SPEED = 300.0

func _ready():
	contact_monitor = true
	max_contacts_reported = 1

func _integrate_forces(state: PhysicsDirectBodyState2D):
	var contacts = state.get_contact_count()
	if contacts > 0:
		hook_landed.emit(global_position)


func launch(direction: Vector2):
	linear_velocity = direction * MOVE_SPEED

func redirect(direction: Vector2):
	linear_velocity = direction * MOVE_SPEED
