extends AudioStreamPlayer2D

# Jump sound variables
@export var jump_sound_path : String = "res://SFX/Jump_sound.mp3"  # Path to jump sound
var jump_sound : AudioStream = load(jump_sound_path)  # Load the jump sound

var is_jumping = false

func _ready():
	if jump_sound == null:
		print("Jump sound not assigned or failed to load!")
	else:
		print("Jump sound loaded!")

func _physics_process(delta):
	if !is_on_floor() and !is_jumping:
		is_jumping = true
		play_jump_sound()
	elif is_on_floor():
		is_jumping = false

func play_jump_sound():
	if jump_sound != null:
		stop()  # Stop any currently playing sound
		stream = jump_sound
		play()
