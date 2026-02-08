extends Node

@export var next_scene: PackedScene

func _ready():
	$VideoStreamPlayer.finished.connect(_on_video_finished)

func _on_video_finished():
	get_tree().change_scene_to_packed(next_scene)
	print("Video done")
