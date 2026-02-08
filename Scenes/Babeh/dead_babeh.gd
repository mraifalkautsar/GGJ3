extends RigidBody2D

@onready var sprite = $AnimatedSprite2D

func setup(start_pos: Vector2, start_vel: Vector2, face_direction: bool, anim_name: String, frame_idx: int, scale_factor: Vector2):
	global_position = start_pos
	linear_velocity = start_vel
	
	# --- APPLY SCALE HERE ---
	# We apply it to the whole RigidBody so the hitbox (CollisionShape) grows too.
	scale = scale_factor 
	
	sprite.flip_h = face_direction
	sprite.animation = anim_name
	sprite.frame = frame_idx
	sprite.stop()
	
	sprite.modulate = Color(0.7, 0.7, 0.7) 
	angular_velocity = randf_range(10, 20) * (1 if randf() > 0.5 else -1)
	apply_central_impulse(Vector2(0, -400))
	
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
