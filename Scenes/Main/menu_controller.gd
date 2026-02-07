extends Node2D

@onready var start_button = $Start
@onready var options_button = $Options
@onready var exit_button = $Exit
@onready var hidden_character = $HiddenCharacter

var button_clicked = {}

func _ready() -> void:
	# Initialize clicked state
	button_clicked["Start"] = false
	button_clicked["Options"] = false
	button_clicked["Exit"] = false
	
	# Hide the character initially
	if hidden_character:
		hidden_character.modulate.a = 0
	
	# Connect mouse input
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Check Start button
		if not button_clicked["Start"] and is_point_in_button(mouse_pos, start_button):
			button_clicked["Start"] = true
			tumble_button(start_button, false)
		
		# Check Options button
		elif not button_clicked["Options"] and is_point_in_button(mouse_pos, options_button):
			button_clicked["Options"] = true
			tumble_button(options_button, false)
		
		# Check Exit button
		elif not button_clicked["Exit"] and is_point_in_button(mouse_pos, exit_button):
			button_clicked["Exit"] = true
			tumble_button(exit_button, true)
			reveal_character()

func is_point_in_button(point: Vector2, button: Node2D) -> bool:
	if not button:
		return false
	
	var icon = button.get_node_or_null("Icon")
	if not icon:
		return false
	
	# Get the button's bounding box (approximately)
	var button_pos = button.global_position
	var half_width = 352  # 5.5 * 128 / 2 (scaled icon width)
	var half_height = 121  # 1.89 * 128 / 2 (scaled icon height)
	
	return (point.x >= button_pos.x - half_width and point.x <= button_pos.x + half_width and
			point.y >= button_pos.y - half_height and point.y <= button_pos.y + half_height)

func tumble_button(button: Node2D, is_exit: bool):
	# Capture initial position
	var start_pos = button.position
	
	# Create tumbling animation using Tween
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	
	# Random tumble direction (left or right)
	var direction = 1 if randf() > 0.5 else -1
	
	# Rotate and fall WAY off screen (1200px should definitely be enough)
	tween.tween_property(button, "rotation", direction * (PI * 2) + randf_range(-0.5, 0.5), 1.2)
	tween.tween_property(button, "position:y", start_pos.y + 1200, 1.2)
	tween.tween_property(button, "position:x", start_pos.x + direction * randf_range(200, 400), 1.2)
	
	# If Exit button, transition to game after animation
	if is_exit:
		tween.chain().tween_callback(func(): start_game()).set_delay(0.5)

func reveal_character():
	if not hidden_character:
		return
	
	# Fade in the character
	var tween = create_tween()
	tween.tween_property(hidden_character, "modulate:a", 1.0, 1.0).set_delay(0.5)
	
	# Character waves or does a little animation
	tween.tween_property(hidden_character, "position:y", hidden_character.position.y - 20, 0.3)
	tween.tween_property(hidden_character, "position:y", hidden_character.position.y, 0.3)

func start_game():
	# Load the first level
	get_tree().change_scene_to_file("res://Scenes/Main/level_1.tscn")
