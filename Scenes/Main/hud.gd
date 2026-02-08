extends CanvasLayer

@onready var timer_label: Label = $TimerContainer/TimerLabel

func _process(delta):
	timer_label.text = GameManager.get_time_string()
	
	if GameManager.time_remaining < 30.0:
		timer_label.modulate = Color(1, 0, 0)
	else:
		timer_label.modulate = Color(1, 1, 1)
