extends Node2D

# --- BUTTON CONFIG ---
@export_group("Buttons")
@export var red_button_node: AreaButton
@export var yellow_button_node: AreaButton

# --- OBJECT CONFIG ---
@export_group("Red Logic (2 Objects)")
@export var red_body_1: AnimatableBody2D
@export var red_body_2: AnimatableBody2D
@export var red_move_offset: Vector2 = Vector2(800, 0)

@export_group("Yellow Logic (1 Object)")
@export var yellow_body: AnimatableBody2D
@export var yellow_move_offset: Vector2 = Vector2(0, 800) # Move Down

# --- STATE ---
# We store the starting position of every object here
var start_positions: Dictionary = {}

func _ready():
	# 1. SETUP RED LOGIC
	if red_button_node:
		red_button_node.button_pressed.connect(_on_red_pressed)
		red_button_node.button_released.connect(_on_red_released)
		
	# Store start positions
	if red_body_1: start_positions[red_body_1] = red_body_1.position
	if red_body_2: start_positions[red_body_2] = red_body_2.position
	
	# 2. SETUP YELLOW LOGIC
	if yellow_button_node:
		yellow_button_node.button_pressed.connect(_on_yellow_pressed)
		yellow_button_node.button_released.connect(_on_yellow_released)
		
	if yellow_body: start_positions[yellow_body] = yellow_body.position

# --- CALLBACKS ---

func _on_red_pressed():
	# Move TO target (Start + Offset)
	move_object(red_body_1, start_positions[red_body_1] + red_move_offset)
	move_object(red_body_2, start_positions[red_body_2] + red_move_offset)

func _on_red_released():
	# Move BACK to start
	move_object(red_body_1, start_positions[red_body_1])
	move_object(red_body_2, start_positions[red_body_2])

func _on_yellow_pressed():
	move_object(yellow_body, start_positions[yellow_body] + yellow_move_offset)

func _on_yellow_released():
	move_object(yellow_body, start_positions[yellow_body])

# --- HELPER ---

func move_object(body: Node2D, target_pos: Vector2):
	if not body: return
	
	# Kill any previous tween so they don't fight
	if body.get_meta("current_tween", null):
		body.get_meta("current_tween").kill()
	
	var tween = create_tween()
	# Store the tween so we can cancel it if the player steps on/off quickly
	body.set_meta("current_tween", tween)
	
	tween.set_trans(Tween.TRANS_EXPO) # "Springy" mechanical feel
	tween.set_ease(Tween.EASE_OUT)
	
	# Move to the specific target position
	tween.tween_property(body, "position", target_pos, 0.25)
