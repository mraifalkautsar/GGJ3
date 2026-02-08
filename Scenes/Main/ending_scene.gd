extends CanvasLayer

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
# Change this path to your Main Menu scene
@export var main_menu_scene: PackedScene 

func _ready():
	# Connect the finished signal so we know when the video ends
	video_player.finished.connect(_on_video_finished)

func play_ending(stream: VideoStream):
	if stream:
		video_player.stream = stream
		video_player.play()
	else:
		push_error("EndingCutscene: No video stream provided!")
		_on_video_finished() # Skip immediately if no video

func _on_video_finished():
	# When video ends, go back to Main Menu
	get_tree().change_scene_to_packed(main_menu_scene)
	queue_free()

#func _input(event):
	## Optional: Allow skipping with Space or Click
	#if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		#_on_video_finished()
