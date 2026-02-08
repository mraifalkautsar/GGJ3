extends Node2D

# --- BUTTON CONFIG ---
@export_group("Buttons")
@export var red_button_node: AreaButton
@export var yellow_button_node: AreaButton
@export var blue_button_node: AreaButton # The Kill Button

# --- OBJECT CONFIG ---
@export_group("Red Logic")
@export var red_body_1: AnimatableBody2D
@export var red_body_2: AnimatableBody2D
@export var red_move_offset: Vector2 = Vector2(800, 0)

@export_group("Yellow Logic")
@export var yellow_body: AnimatableBody2D
@export var yellow_move_offset: Vector2 = Vector2(0, 800)

# (Blue doesn't need a body to move anymore)

# --- STATE ---
var start_positions: Dictionary = {}

func _ready():
	# 1. SETUP RED
	if red_button_node:
		red_button_node.button_pressed.connect(_on_red_pressed)
		red_button_node.button_released.connect(_on_red_released)
	
	if red_body_1: start_positions[red_body_1] = red_body_1.position
	if red_body_2: start_positions[red_body_2] = red_body_2.position
	
	# 2. SETUP YELLOW
	if yellow_button_node:
		yellow_button_node.button_pressed.connect(_on_yellow_pressed)
		yellow_button_node.button_released.connect(_on_yellow_released)
		
	if yellow_body: start_positions[yellow_body] = yellow_body.position

	# 3. SETUP BLUE (DEATH)
	if blue_button_node:
		blue_button_node.button_pressed.connect(_on_blue_pressed)
		# No release needed, player is already dead

# --- MOVEMENT CALLBACKS ---

func _on_red_pressed():
	move_object(red_body_1, start_positions.get(red_body_1, Vector2.ZERO) + red_move_offset)
	move_object(red_body_2, start_positions.get(red_body_2, Vector2.ZERO) + red_move_offset)

func _on_red_released():
	move_object(red_body_1, start_positions.get(red_body_1, Vector2.ZERO))
	move_object(red_body_2, start_positions.get(red_body_2, Vector2.ZERO))

func _on_yellow_pressed():
	move_object(yellow_body, start_positions.get(yellow_body, Vector2.ZERO) + yellow_move_offset)

func _on_yellow_released():
	move_object(yellow_body, start_positions.get(yellow_body, Vector2.ZERO))

# --- DEATH CALLBACK ---

func _on_blue_pressed():
	# 1. Find the Player
	var player = get_tree().get_first_node_in_group("Player")
	
	# 2. Kill them
	if player and player.has_method("die"):
		print("Blue button pressed! Killing player...")
		# Pass the button's position so the ragdoll flies AWAY from the button
		player.call_deferred("die", blue_button_node.global_position)
		
		# Optional: Trigger a specific death screen message
		DeadScreen.show_death("api")

# --- HELPER ---

func move_object(body: Node2D, target_pos: Vector2):
	if not body: return
	
	if body.has_meta("current_tween"):
		var existing_tween = body.get_meta("current_tween")
		if existing_tween.is_valid(): existing_tween.kill()
	
	var tween = create_tween()
	body.set_meta("current_tween", tween)
	
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(body, "position", target_pos, 0.25)
