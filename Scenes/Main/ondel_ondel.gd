extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		animated_sprite_2d.play("nampar")


func _on_tamparan_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.call_deferred("die", global_position)
		_death_by_ondel()

func _death_by_ondel():
	DeadScreen.show_death("ondel")
