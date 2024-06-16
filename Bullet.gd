extends RigidBody2D

var velocity = Vector2.ZERO

func _ready():
	# Set initial velocity
	velocity = Vector2(100, 0)

func _physics_process(delta):
	# Move the projectile
	move_and_collide(velocity * delta)

func _on_area_entered(area):
	# Handle collision with other objects
	if area.is_in_group("character"):
		area.queue_free()  # Destroy the enemy
		queue_free()       # Destroy the projectile
