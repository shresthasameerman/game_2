extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -295.0
const DOUBLE_JUMP_VELOCITY = -200.0
var attack_type: String
var current_attack: bool
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
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
	
	Global.Character = self
	current_attack = false

	# Connect the animation finished signal
	animated_sprite.connect("animation_finished", self._on_AnimatedSprite2D_animation_finished)

func _physics_process(delta):
	Global.DealDamageZone= deal_damage_zone
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
			set_damage(attack_type)
			handle_attack_animation(attack_type)

	# gets the movement direction: -1 , 0 , 1
	var direction = Input.get_axis("move_left", "move_right")
	
	# Play running sound when moving horizontally
	if is_on_floor() and direction != 0:
		play_running_sound()
	else:
		stop_running_sound()
	
	# flip the sprite:
	if direction == 1:
		animated_sprite.flip_h = false
		deal_damage_zone.scale.x = 1
	if direction == -1:
		animated_sprite.flip_h = true
		deal_damage_zone.scale.x = -1
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
		toggle_damage_collision(attack_type)
		
		
		
func toggle_damage_collision(attack_type):
	var damage_zone_collision = deal_damage_zone.get_node("CollisionShape2D")
	var wait_time: float
	if attack_type == "single":
		wait_time= 1
	elif attack_type == "double":
		wait_time = 1.3
	damage_zone_collision.disabled = false
	await get_tree().create_timer(wait_time).timeout
	damage_zone_collision.disabled = true

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
func set_damage(attack_type):
	var current_damage_to_deal: int
	if attack_type == "single":
		current_damage_to_deal = 8
	elif attack_type == "double":
		current_damage_to_deal = 16
	Global.PlayerDamageAmount = current_damage_to_deal
