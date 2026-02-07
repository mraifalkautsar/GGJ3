extends RigidBody2D

signal swap_requested

func _ready():
	add_to_group("swappable")

func on_hook_hit():
	swap_requested.emit()
