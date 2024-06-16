extends CharacterBody2D

const Speed = 20
const GRAVITY = 98.0  # Adjust the gravity constant as needed
var dir: Vector2
var is_raider_chase: bool
var player: CharacterBody2D
var Health = 50
var health_max = 50
var health_min = 0
var dead = false
var taking_damage = false
var is_roaming: bool

var deal_damage_zone: Area2D
var timer: Timer
var hurt_duration = 0.5  # Duration of the hurt animation in seconds

func _ready():
	is_raider_chase = true
	
	# Find the DealDamageZone and Timer nodes
	deal_damage_zone = $DealDamageZone
	timer = $Timer

	if timer:
		# Check if the timeout signal is already connected
		if not timer.is_connected("timeout", Callable(self, "_on_timer_timeout")):
			timer.connect("timeout", Callable(self, "_on_timer_timeout"))
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
	if Global.Character and Global.Character.is_instance_valid():
		player = Global.Character
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
			velocity.x = dir.x * Speed

		move_and_slide()
	else:
		print("Global.Character is not valid or missing")

func _on_timer_timeout():
	timer.wait_time = choose([4.0, 20.0])
	if not is_raider_chase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])
		print(dir)

func handle_animation():
	var animated_sprite = $AnimatedSprite2D
	if taking_damage:
		animated_sprite.play("hurt")
	else:
		animated_sprite.play("walk")
		if dir.x == -1:
			animated_sprite.flip_h = true
		elif dir.x == 1:
			animated_sprite.flip_h = false

func choose(array: Array) -> Variant:
	array.shuffle()
	return array.front()

func _on_enemyhitbox_area_entered(area):
	print("Entered area: ", area)  # Debug print
	print("Global.DealDamageZone: ", Global.DealDamageZone)  # Debug print

	# Ensure Global.DealDamageZone is properly referenced
	if area == Global.DealDamageZone:
		print("Enemy hitbox area entered by player damage zone")
		if "damage" in Global.DealDamageZone:
			var damage = Global.DealDamageZone.damage  # Assuming DealDamageZone has a damage property
			print("Damage value: ", damage)
			take_damage(damage)
		else:
			print("Global.DealDamageZone does not have a damage property")

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
		if Global.Character and Global.Character.is_instance_valid():
			var knockback_dir = (position - player.position).normalized()
			velocity.x = knockback_dir.x * Speed
		
		# Knockback and hurt duration
		await get_tree().create_timer(hurt_duration).timeout
		taking_damage = false
