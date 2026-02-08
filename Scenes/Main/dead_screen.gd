extends CanvasLayer

# --- CONFIGURATION ---
@export var death_reasons: Dictionary[String, Death] = {} # Fix: Ensure Class Name matches your resource
@export var auto_retry_delay: float = 3.0

# --- NODES ---
@onready var background = $Background
@onready var content = $Content
@onready var photo_rect = $Content/Photo
@onready var caption_label = $Content/Caption

var is_retrying: bool = false # The culprit variable

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_death(reason_id: String):
	# RESET THE FLAG HERE!
	is_retrying = false 
	
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	
	var data = get_death_reason(reason_id)
	if data:
		photo_rect.texture = data.photo
		caption_label.text = data.caption
	else:
		photo_rect.texture = null
		caption_label.text = "YOU DIED"

	visible = true
	get_tree().paused = true
	
	# Start timer (process_always=true to ignore pause)
	await get_tree().create_timer(auto_retry_delay, true, false, true).timeout
	
	_perform_retry()

func get_death_reason(id: String) -> Death:
	return death_reasons.get(id)

func _perform_retry():
	if is_retrying: return # Blocks duplicate calls
	is_retrying = true
	
	# 1. Unpause
	get_tree().paused = false
	
	# 2. Transition
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	
	# 3. Reload
	get_tree().reload_current_scene()

	# 4. Hide screen
	visible = false
	
	# Note: We do NOT reset 'is_retrying' here because the function might finish 
	# before the scene fully reloads. We reset it in show_death() next time.
