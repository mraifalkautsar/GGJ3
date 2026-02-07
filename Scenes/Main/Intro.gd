extends Node

func _ready():
	$VideoStreamPlayer.finished.connect(_on_video_finished)

func _on_video_finished():
	print("Video done")
