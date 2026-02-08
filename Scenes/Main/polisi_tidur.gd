extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_death_by_police()

func _death_by_police():
	DeadScreen.show_death("polisi")
