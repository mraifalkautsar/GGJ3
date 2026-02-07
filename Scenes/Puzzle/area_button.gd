class_name AreaButton
extends Area2D

# --- SIGNALS ---
# Connect these to your Doors, Traps, or Level Script
signal button_pressed
signal button_released

# --- CONFIGURATION ---
@export_enum("Blue", "Red", "Yellow") var button_color: int = 0
@export var is_one_shot: bool = false

# --- NODES ---
@onready var sprite = $Sprite2D 
@onready var sprite_texture = sprite.texture
@export var pressed_sprite: Texture2D

# --- STATE ---
var is_pressed: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(_body):
	if is_pressed and is_one_shot: return
	
	if not is_pressed:
		press_button()

func _on_body_exited(_body):
	if is_one_shot: return
	
	if not has_overlapping_bodies():
		release_button()

# --- LOGIC ---

func press_button():
	is_pressed = true
	button_pressed.emit()
	
	if sprite:
		sprite.texture = pressed_sprite

func release_button():
	is_pressed = false
	button_released.emit()
	
	if sprite:
		sprite.texture = sprite_texture
