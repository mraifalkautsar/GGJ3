extends Node2D

@onready var start_button = $Start
@onready var options_button = $Options
@onready var exit_button = $Exit
@onready var hidden_character = $Babeh
@onready var babeh_sprite = $Babeh/AnimatedSprite2D
@onready var canvas_layer = $CanvasLayer

@export var poster_texture: Texture2D # The graduation poster to show
@export var next_scene: PackedScene

var button_clicked = {}

func _ready() -> void:
	# Initialize clicked state
	button_clicked["Start"] = false
	button_clicked["Options"] = false
	button_clicked["Exit"] = false
	
	# Character is visible from the start (behind billboard)
	# No need to hide
	
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Process clicks for each button
		check_button_click("Start", start_button, mouse_pos, false)
		check_button_click("Options", options_button, mouse_pos, false)
		check_button_click("Exit", exit_button, mouse_pos, true)

func check_button_click(button_key: String, button_node: Node2D, mouse_pos: Vector2, triggers_sequence: bool):
	if not button_clicked[button_key] and is_point_in_button(mouse_pos, button_node):
		button_clicked[button_key] = true
		
		# Tumble the button
		tumble_button(button_node, false)
		
		# Only Exit button triggers the character sequence
		if triggers_sequence:
			reveal_character()

func are_all_buttons_clicked() -> bool:
	for key in button_clicked:
		if button_clicked[key] == false:
			return false
	return true

func is_point_in_button(global_mouse_point: Vector2, button_node: Node2D) -> bool:
	if not button_node: return false
	
	# 1. Get the visual sprite (Icon)
	var icon = button_node.get_node_or_null("Icon")
	if not icon: 
		push_warning(button_node.name + " has no 'Icon' sprite!")
		return false
	
	# 2. Convert the Global Mouse Position to the Icon's Local Space
	# This automatically accounts for the button's Position, Rotation, and Scale!
	var local_mouse_pos = icon.to_local(global_mouse_point)
	
	# 3. Check if that local point is inside the sprite's texture rectangle
	# get_rect() returns the size of the texture centered or offset correctly
	return icon.get_rect().has_point(local_mouse_pos)

func tumble_button(button: Node2D, _unused: bool):
	var start_pos = button.position
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	
	var direction = 1 if randf() > 0.5 else -1
	
	tween.tween_property(button, "rotation", direction * (PI * 2) + randf_range(-0.5, 0.5), 1.2)
	tween.tween_property(button, "position:y", start_pos.y + 1200, 1.2)
	tween.tween_property(button, "position:x", start_pos.x + direction * randf_range(200, 400), 1.2)

func reveal_character():
	if not hidden_character: return
	
	# Disable input during the sequence
	set_process_input(false)
	
	# Phase 1: Wait a bit for comedic timing
	await get_tree().create_timer(0.8).timeout
	
	# Phase 2: Fishing animation (bobbing motion)
	await perform_fishing_sequence()
	
	# Phase 3: Show the caught poster
	await show_graduation_poster()
	
	# Phase 4: Character realizes and falls down
	await character_tumble_and_fall()
	
	# Phase 5: Wait a moment, then start game
	await get_tree().create_timer(2.0).timeout
	start_game()

func perform_fishing_sequence():
	# Bobbing animation to simulate fishing/reeling
	var fishing_tween = create_tween()
	fishing_tween.set_loops(3)
	fishing_tween.tween_property(hidden_character, "position:y", hidden_character.position.y - 15, 0.3)
	fishing_tween.tween_property(hidden_character, "position:y", hidden_character.position.y, 0.3)
	await fishing_tween.finished
	
	# Final pull - character lifts up
	var pull_tween = create_tween()
	pull_tween.tween_property(hidden_character, "position:y", hidden_character.position.y - 30, 0.4)
	await pull_tween.finished

func show_graduation_poster():
	# Create a sprite to show the poster
	var poster = Sprite2D.new()
	poster.texture = poster_texture
	poster.position = Vector2(960, 540) # Center of screen (1920x1080 / 2)
	poster.scale = Vector2(0.7, 0.7)
	poster.z_index = 10
	poster.modulate.a = 0
	
	# Add poster to canvas layer so it appears on top
	canvas_layer.add_child(poster)
	
	# Fade in poster with a slight zoom
	var appear_tween = create_tween()
	appear_tween.set_parallel(true)
	appear_tween.tween_property(poster, "modulate:a", 1.0, 0.5)
	appear_tween.tween_property(poster, "scale", Vector2(0.8, 0.8), 0.5)
	await appear_tween.finished
	
	# Hold for 3 seconds
	await get_tree().create_timer(3.0).timeout
	
	# Fade out poster
	var fade_tween = create_tween()
	fade_tween.tween_property(poster, "modulate:a", 0.0, 0.5)
	await fade_tween.finished
	
	poster.queue_free()

func character_tumble_and_fall():
	# Character realization moment (small bounce)
	var realize_tween = create_tween()
	realize_tween.tween_property(hidden_character, "scale", Vector2(1.1, 0.9), 0.1)
	realize_tween.tween_property(hidden_character, "scale", Vector2(1.0, 1.0), 0.1)
	await realize_tween.finished
	
	await get_tree().create_timer(0.3).timeout
	
	# Simple fall straight down
	var start_pos = hidden_character.position
	var fall_tween = create_tween()
	fall_tween.set_trans(Tween.TRANS_CUBIC)
	fall_tween.set_ease(Tween.EASE_IN)
	
	# Just fall down (no spinning or drifting)
	fall_tween.tween_property(hidden_character, "position:y", start_pos.y + 1500, 1.2)
	
	await fall_tween.finished

func start_game():
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	GameManager.start_new_game()
	get_tree().change_scene_to_packed(next_scene)
