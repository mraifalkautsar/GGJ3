extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.call_deferred("die", global_position)
		_death_by_ondel()

func _death_by_ondel():
	DeadScreen.show_death("jantungan")
