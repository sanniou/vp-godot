extends Area2D

var damage = 10
var speed = 400
var target = null
var max_lifetime = 5.0  # Maximum lifetime in seconds
var lifetime = 0

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)

func _process(delta):
	if target == null or !is_instance_valid(target):
		# Target is gone, destroy projectile
		queue_free()
		return
	
	# Move towards target
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta
	
	# Update lifetime
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# Deal damage to enemy
		body.take_damage(damage)
		
		# Destroy projectile
		queue_free()

func _on_screen_exited():
	# Destroy projectile if it goes off screen
	queue_free()
