extends Area2D

@export var target_node: TileMap

func _ready():
	print("Pressure plate ready")
	
	if not target_node:
		print("Target node path not set")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	print("Body entered: ", body.name)
	# Only process physics bodies (CharacterBody2D, RigidBody2D)
	if not (body is CharacterBody2D or body is RigidBody2D):
		return
	
	if body.is_in_group("Player"):
		print("Player entered pressure plate")
		if target_node:
			target_node.visible = false
			target_node.tile_set.set_physics_layer_collision_layer(0, 0)
			target_node.tile_set.set_physics_layer_collision_mask(0, 0)
			print("Target node hidden and collision disabled")
	else:
		print("Body is not the player")

func _on_body_exited(body):
	print("Body exited: ", body.name)
	# Only process physics bodies (CharacterBody2D, RigidBody2D)
	if not (body is CharacterBody2D or body is RigidBody2D):
		return
	
	if body.is_in_group("Player"):
		print("Player exited pressure plate")
		if target_node:
			target_node.show()
			target_node.tile_set.set_physics_layer_collision_layer(0, 2)
			target_node.tile_set.set_physics_layer_collision_mask(0, 1)
			print("Target node shown and collision enabled")
	else:
		print("Body is not the player")
