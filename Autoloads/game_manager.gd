extends Node

# --- SIGNALS ---
signal level_completed
signal game_finished
signal game_over_timeout

# --- CONFIGURATION ---
@export_group("Levels")
@export var levels: Array[PackedScene] = [] 

@export_group("Settings")
@export var total_game_time: float = 300.0 
@export var good_ending_threshold: float = 60.0 

# --- ENDING CONFIGURATION (NEW) ---
@export_group("Endings")
@export var ending_cutscene_scene: PackedScene # The scene with CanvasLayer + VideoStreamPlayer
@export var good_ending_video: VideoStream     # The .ogv file for Good Ending
@export var normal_ending_video: VideoStream   # The .ogv file for Normal Ending

# --- STATE ---
var current_level_index: int = 0
var time_remaining: float = 0.0
var is_timer_active: bool = false
var good_ending: bool = false 

func _ready():
	level_completed.connect(_on_level_completed)
	time_remaining = total_game_time

func _process(delta):
	if is_timer_active:
		time_remaining -= delta
		if time_remaining <= 0:
			time_remaining = 0
			is_timer_active = false
			#game_over()

# --- LEVEL LOGIC ---
func complete_level():
	emit_signal("level_completed")

func _on_level_completed():
	var next_index = current_level_index + 1
	if next_index < levels.size():
		current_level_index = next_index
		load_current_level()
	else:
		victory()

func load_current_level():
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_packed.call_deferred(levels[current_level_index])
	
	if not is_timer_active: 
		is_timer_active = true

func start_new_game():
	current_level_index = 0
	time_remaining = total_game_time
	is_timer_active = false 
	good_ending = false
	load_current_level()

# --- VICTORY LOGIC (UPDATED) ---
func victory():
	is_timer_active = false
	check_ending()
	
	emit_signal("game_finished")
	
	# PLAY THE CUTSCENE
	if ending_cutscene_scene:
		TransitionScreen.transition()
		await TransitionScreen.on_transition_finished
		# 1. Instantiate the cutscene scene
		var cutscene_instance = ending_cutscene_scene.instantiate()
		get_tree().root.add_child(cutscene_instance)
		
		# 2. Decide which video to play
		var video_to_play = good_ending_video if good_ending else normal_ending_video
		
		# 3. Tell the scene to start playing
		cutscene_instance.play_ending(video_to_play)
		
		# 4. Remove the game level (Optional, cleanup)
		# get_tree().current_scene.queue_free() 

func check_ending():
	if time_remaining >= good_ending_threshold:
		good_ending = true
	else:
		good_ending = false

#func game_over():
	#is_timer_active = false
	#emit_signal("game_over_timeout")

func get_time_string() -> String:
	var minutes = floor(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	return "%02d:%02d" % [minutes, seconds]
