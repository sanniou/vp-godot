extends Node2D

var player_speed = 300

func _ready():
	pass

func _process(delta):
	# 处理玩家移动
	var player = $Player
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	
	direction = direction.normalized()
	player.velocity = direction * player_speed
	player.move_and_slide()
	
	# 简单的敌人AI
	var enemy = $Enemy
	var to_player = player.global_position - enemy.global_position
	if to_player.length() > 10:
		enemy.velocity = to_player.normalized() * 100
		enemy.move_and_slide()
