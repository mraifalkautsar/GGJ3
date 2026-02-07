extends AnimatableBody2D

@export var move_speed: float = 100.0
var velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("Move_Left", "Move_Right")

	if direction:
		velocity.x = direction * move_speed
	else:
		velocity.x = 0

	var collision = move_and_collide(velocity * delta)
