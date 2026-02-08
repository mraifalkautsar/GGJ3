class_name Exit
extends Area2D


func _on_body_entered(body: Node2D) -> void:
	print("AAAAAAAAAAAAAAA")
	if body.is_in_group("Player"):
		GameManager.complete_level()
