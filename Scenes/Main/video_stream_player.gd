extends VideoStreamPlayer

func _ready():
	resize_to_viewport()
	get_viewport().size_changed.connect(resize_to_viewport)

func resize_to_viewport():
	size = get_viewport().get_visible_rect().size
