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
	
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Process clicks for each button
		check_button_click("Start", start_button, mouse_pos)
		check_button_click("Options", options_button, mouse_pos)
		check_button_click("Exit", exit_button, mouse_pos)

func check_button_click(button_key: String, button_node: Node2D, mouse_pos: Vector2):
	if not button_clicked[button_key] and is_point_in_button(mouse_pos, button_node):
		button_clicked[button_key] = true
		
		# Check if this was the last button needed
		var is_all_done = are_all_buttons_clicked()
		tumble_button(button_node, is_all_done)
		
		if is_all_done:
			reveal_character()

func are_all_buttons_clicked() -> bool:
	for key in button_clicked:
		if button_clicked[key] == false:
			return false
	return true

func is_point_in_button(point: Vector2, button: Node2D) -> bool:
	if not button: return false
	var icon = button.get_node_or_null("Icon")
	if not icon: return false
	
	var button_pos = button.global_position
	var half_width = 352 
	var half_height = 121
	
	return (point.x >= button_pos.x - half_width and point.x <= button_pos.x + half_width and
			point.y >= button_pos.y - half_height and point.y <= button_pos.y + half_height)

func tumble_button(button: Node2D, should_trigger_start: bool):
	var start_pos = button.position
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	
	var direction = 1 if randf() > 0.5 else -1
	
	tween.tween_property(button, "rotation", direction * (PI * 2) + randf_range(-0.5, 0.5), 1.2)
	tween.tween_property(button, "position:y", start_pos.y + 1200, 1.2)
	tween.tween_property(button, "position:x", start_pos.x + direction * randf_range(200, 400), 1.2)
	
	# Only start the game if this was the final button
	if should_trigger_start:
		tween.chain().tween_callback(func(): start_game()).set_delay(0.5)

func reveal_character():
	if not hidden_character: return
	var tween = create_tween()
	tween.tween_property(hidden_character, "modulate:a", 1.0, 1.0).set_delay(0.5)
	tween.tween_property(hidden_character, "position:y", hidden_character.position.y - 20, 0.3)
	tween.tween_property(hidden_character, "position:y", hidden_character.position.y, 0.3)

func start_game():
	get_tree().change_scene_to_file("res://Scenes/Main/level_1.tscn")
