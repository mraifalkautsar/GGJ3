extends Area2D

@export var expansion_rate: float = 0.1

func _process(delta: float) -> void:
	scale += Vector2(expansion_rate, expansion_rate) * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		body.die()
