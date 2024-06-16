extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -295.0
const DOUBLE_JUMP_VELOCITY = -200.0

var attack_type: String
var current_attack: bool

var gravity: float = 1000.0  # Default gravity value if project setting fails

@onready var animated_sprite = $AnimatedSprite2D
var isAttacking = false

# AudioStreamPlayer nodes
@onready var audio_player_running: AudioStreamPlayer = $AudioStreamPlayerRunning
@onready var audio_player_jumping: AudioStreamPlayer = $AudioStreamPlayerJumping
@onready var deal_damage_zone: Area2D = $DealDamageZone

# Variables for double jump
var can_double_jump = true
var double_jump_used = false

func _ready():
	add_to_group("Character")
	current_attack = false

	# Connect the animation finished signal
	animated_sprite.connect("animation_finished", self._on_AnimatedSprite2D_animation_finished)

	# Get the gravity from the project settings to be synced with RigidBody nodes.
	if ProjectSettings.has_setting("physics/2d/default_gravity"):
		gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	else:
		# Print a warning message to the console
		print_warning("Default gravity setting not found in project settings. Using default value.")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			double_jump_used = false
			play_jump_sound()
		elif can_double_jump and not double_jump_used:
			velocity.y = DOUBLE_JUMP_VELOCITY
			double_jump_used = true
			play_jump_sound()

	if not current_attack:
		if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("attack2"):
			current_attack = true
			if Input.is_action_just_pressed("attack") and is_on_floor():
				attack_type = "single"
			elif Input.is_action_just_pressed("attack2") and is_on_floor():
				attack_type = "double"
			else:
				attack_type = "air"
			handle_attack_animation(attack_type)

	# gets the movement direction: -1 , 0 , 1
	var direction = Input.get_axis("move_left", "move_right")
	
	# Play running sound when moving horizontally
	if is_on_floor() and direction != 0:
		play_running_sound()
	else:
		stop_running_sound()
	
	# flip the sprite:
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# animation play
	if is_on_floor() and not current_attack:
		if direction == 0:
			animated_sprite.play("Idle")
		else:
			animated_sprite.play("run")
	elif not current_attack:
		animated_sprite.play("jump")
	
	# applies the movement 
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func handle_attack_animation(attack_type):
	if current_attack:
		var animation = str(attack_type, "_attack")
		print(animation)
		animated_sprite.play(animation)  # Play the attack animation

func play_running_sound():
	if audio_player_running != null and not audio_player_running.playing:
		audio_player_running.play()

func stop_running_sound():
	if audio_player_running != null and audio_player_running.playing:
		audio_player_running.stop()

func play_jump_sound():
	if audio_player_jumping != null:
		audio_player_jumping.play()

func _on_AnimatedSprite2D_animation_finished():
	# This function will be called when the animation finishes
	current_attack = false

func print_warning(message):
	print("WARNING: " + message)
