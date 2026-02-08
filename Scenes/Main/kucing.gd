extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		animated_sprite_2d.play("lompat")
		
		# 2. TWEEN UP (The Jump Effect)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC) # Smooth "Jump" curve
		tween.set_ease(Tween.EASE_OUT)     # Fast start, slow end
		
		# Move the sprite UP by 100 pixels over 0.4 seconds
		tween.tween_property(animated_sprite_2d, "position:y", animated_sprite_2d.position.y - 100, 0.4)
		
		# 3. Kill Player
		body.call_deferred("die", global_position)
		
		# 4. Trigger Death Screen
		_death_by_cat()

func _death_by_cat():
	# Optional: Wait 0.5s so we can see the cat jump before screen fades
	await get_tree().create_timer(0.5).timeout
	DeadScreen.show_death("kucing")
