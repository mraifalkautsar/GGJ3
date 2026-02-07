extends RigidBody2D

signal swap_requested

func _ready():
	pass

func on_hook_hit():
	swap_requested.emit()

func _on_body_entered(body: Node) -> void:
	print(body)
	print("AAAAAAAAAAAAAAAAAAAAAAAAA")
	if body is Hook:
		swap_requested.emit()
