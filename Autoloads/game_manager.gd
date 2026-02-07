extends Node

# --- SIGNALS ---
signal level_completed
signal game_finished
signal game_over_timeout

# --- CONFIGURATION ---
@export_group("Levels")
@export var levels: Array[PackedScene] = [preload("uid://8r08chl8ges4"), preload("uid://d2noufo7l0dip"), preload("uid://cddxpioyovqgn")] # Drag your Level1.tscn, Level2.tscn here

@export_group("Settings")
@export var total_game_time: float = 300.0 # 5 Minutes (in seconds)

# --- STATE ---
var current_level_index: int = 0
var time_remaining: float = 0.0
var is_timer_active: bool = false
var save_path: String = "user://savegame.cfg"
var good_ending: bool = true

func _ready():
	# Connect signals
	level_completed.connect(_on_level_completed)
	
	# Try to load save data
	load_game()
	
	# Initialize Timer (Only starts when you enter the first level)
	time_remaining = total_game_time
	# process_mode = Node.PROCESS_MODE_ALWAYS # Ensures it runs even if scene pauses (optional)

func _process(delta):
	if is_timer_active:
		time_remaining -= delta
		
		# CHECK FOR TIME OUT
		if time_remaining <= 0:
			time_remaining = 0
			is_timer_active = false
			game_over()

# --- LEVEL LOGIC ---

# Call this from your "Goal" object: GameManager.complete_level()
func complete_level():
	emit_signal("level_completed")

func _on_level_completed():
	print("Level ", current_level_index, " Complete!")
	
	# Calculate next level
	var next_index = current_level_index + 1
	
	if next_index < levels.size():
		current_level_index = next_index
		save_game() # Auto-save progress
		load_current_level()
	else:
		victory()

func load_current_level():
	if levels.is_empty():
		push_error("GameManager: No levels assigned!")
		return
		
	# Defer the call to avoid physics glitches during transition
	get_tree().change_scene_to_packed.call_deferred(levels[current_level_index])
	
	# Start timer if not already running
	if not is_timer_active and current_level_index == 0:
		is_timer_active = true

# --- GAME FLOW ---

func start_new_game():
	current_level_index = 0
	time_remaining = total_game_time
	is_timer_active = true
	load_current_level()

func victory():
	print("YOU WIN! Time Left: ", time_remaining)
	is_timer_active = false
	emit_signal("game_finished")
	# Connect signal ke game ending

func game_over():
	print("GAME OVER - TIME UP")
	is_timer_active = false
	emit_signal("game_over_timeout")
	# Load Game Over Scene or restart
	# get_tree().reload_current_scene()

# --- SAVE SYSTEM ---

func save_game():
	var config = ConfigFile.new()
	config.set_value("Progress", "level_index", current_level_index)
	# Optional: Save time remaining if you want time to persist across sessions
	# config.set_value("Progress", "time_left", time_remaining)
	config.save(save_path)

func load_game():
	var config = ConfigFile.new()
	var err = config.load(save_path)
	
	if err == OK:
		current_level_index = config.get_value("Progress", "level_index", 0)
	else:
		current_level_index = 0

# --- HELPER FOR UI ---
# Call this in your UI script: GameManager.get_time_string()
func get_time_string() -> String:
	var minutes = floor(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	return "%02d:%02d" % [minutes, seconds]
