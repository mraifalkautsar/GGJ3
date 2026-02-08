extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal on_transition_finished

var current_speed: float = 1.0

func _ready() -> void:
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name) -> void:
	if anim_name == "fade_to_black":
		on_transition_finished.emit()
		animation_player.play("black_to_fade")
	elif anim_name == "black_to_fade":
		color_rect.visible = false

func transition(speed: float = 1.0) -> void:
	color_rect.visible = true
	current_speed = speed # Save it for later
	
	# .play(name, custom_blend, custom_speed, from_end)
	# We pass -1 for blend to use default, and then our custom speed
	animation_player.play("fade_to_black", -1, current_speed)

# How To Use
# TransitionScreen.transition()
# await TransitionScreen.on_transition_finished
