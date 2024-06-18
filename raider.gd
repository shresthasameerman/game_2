extends CharacterBody2D

const Speed = 20
const GRAVITY = 980.0  # Adjust the gravity constant as needed
var dir: Vector2 = Vector2.RIGHT
var is_raider_chase: bool = true
var player: CharacterBody2D
var Health = 50
var health_max = 50
var health_min = 0
var dead = false
var taking_damage = false
var is_roaming: bool = false
var deal_damage_zone: Area2D
var timer: Timer
var hurt_duration = 0.5  # Duration of the hurt animation in seconds

func _ready():
	# Find the DealDamageZone and Timer nodes
	deal_damage_zone = $hitbox
	timer = $Timer

	if timer:
		# Check if the timeout signal is already connected
		if not timer.is_connected("timeout", Callable(self, "_on_timer_timeout")):
			timer.connect("timeout", Callable(self, "_on_timer_timeout"))
		timer.start()
	else:
		print("Timer node not found")

	if deal_damage_zone:
		# Ensure the area_entered signal is connected
		if not deal_damage_zone.is_connected("area_entered", Callable(self, "_on_enemyhitbox_area_entered")):
			deal_damage_zone.connect("area_entered", Callable(self, "_on_enemyhitbox_area_entered"))
	else:
		print("DealDamageZone node not found")

	# Debugging: Print Global.DealDamageZone to verify its value
	print("Global.DealDamageZone: ", Global.DealDamageZone)

func _process(delta):
	move(delta)
	handle_animation()

func move(delta):
	player = Global.Character
	if !dead:
		if Global.Character and Global.Character:
			
			if not is_on_floor():
				velocity.y += GRAVITY * delta
			is_roaming = true
			if not taking_damage and is_raider_chase:
				velocity = position.direction_to(player.position) * Speed
				velocity.y += GRAVITY * delta  # Ensure gravity is applied
				dir.x = sign(velocity.x)
			elif taking_damage:
				var knockback_dir = (position - player.position).normalized()
				velocity.x = knockback_dir.x * Speed
				velocity.y += GRAVITY * delta  # Apply gravity only for vertical movement
			else:
				velocity.x = dir.x * Speed * delta
	elif dead:
		velocity.x = 0
	else:
		print("Global.Character is not valid or missing")
	move_and_slide()
func _on_timer_timeout():
	timer.wait_time = choose([4.0, 20.0])
	if not is_raider_chase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])
		
		velocity.x = 0

func handle_animation():
	var animated_sprite = $AnimatedSprite2D
	if taking_damage:
		animated_sprite.play("hurt")
	else:
		animated_sprite.play("walking")
		if dir.x == -1:
			animated_sprite.flip_h = true
		elif dir.x == 1:
			animated_sprite.flip_h = false

func choose(array: Array) -> Variant:
	array.shuffle()
	return array.front()
func _on_deal_damage_zone_area_entered(area):
	if area == Global.DealDamageZone:
		var damage = Global.PlayerDamageAmount
		take_damage(damage)
func take_damage(damage):
	print("Taking damage: ", damage)  # Debug print
	Health -= damage
	taking_damage = true
	if Health <= 0:
		Health = 0
		dead = true
		print(str(self), "current health is", Health)
		# Play death animation and handle death state
		handle_animation()
		await get_tree().create_timer(hurt_duration).timeout
		queue_free()
	else:
		# Play hurt animation and start knockback
		if Global.Character and Global.Character:
			var knockback_dir = (position - player.position).normalized()
			velocity.x = knockback_dir.x * Speed

		# Knockback and hurt duration
		await get_tree().create_timer(hurt_duration).timeout
		taking_damage = false


