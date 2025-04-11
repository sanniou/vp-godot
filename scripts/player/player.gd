extends CharacterBody2D

signal health_changed(new_health)
signal died

# 预加载抽象遗物类
const AbstractRelic = preload("res://scripts/relics/abstract_relic.gd")

# Player stats
var max_health = 100
var current_health = max_health
var move_speed = 300
var is_invincible = false

# References
@onready var invincibility_timer = $InvincibilityTimer
@onready var weapon_container = $WeaponContainer
@onready var hit_box = $HitBox

func _ready():
	# Add to player group
	add_to_group("player")

	# Connect signals
	hit_box.body_entered.connect(_on_hit_box_body_entered)
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)

func _physics_process(_delta):
	# Get input direction
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Set velocity
	if direction.length() > 0.1:
		velocity = direction * move_speed
	else:
		# Immediately stop when no input
		velocity = Vector2.ZERO

	# Move the player
	move_and_slide()

# Take damage
func take_damage(amount):
	if is_invincible:
		return

	# 获取遗物管理器
	var main = get_tree().current_scene
	var relic_manager = main.get_node_or_null("RelicManager") if main else null

	# 触发伤害事件，应用遗物效果
	if relic_manager:
		var attacker = null

		# 尝试找到最近的敵人作为攻击者
		var enemies = get_tree().get_nodes_in_group("enemies")
		var closest_distance = 100  # 只考虑100像素范围内的敵人
		for enemy in enemies:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				attacker = enemy

		# 准备事件数据
		var event_data = {
			"player": self,
			"damage": amount,
			"attacker": attacker,
			"dodged": false
		}

		# 触发伤害事件
		var modified_data = relic_manager.trigger_event(3, event_data)  # 3 = DAMAGE_TAKEN

		# 获取修改后的伤害值
		amount = modified_data["damage"]

		# 检查是否闪避
		if modified_data["dodged"]:
			return

	# Check if player has a shield weapon that can absorb damage
	var actual_damage = amount
	for weapon in weapon_container.get_children():
		if weapon.name == "Shield" and weapon.has_method("player_hit"):
			actual_damage = weapon.player_hit(actual_damage)
			break

	current_health -= actual_damage
	health_changed.emit(current_health)

	# Enhanced visual feedback for damage
	# 1. Flash the player red
	modulate = Color(1, 0, 0, 1)

	# 2. Create a screen shake effect
	var camera = $Camera2D
	if camera:
		var shake_strength = 5.0
		var shake_duration = 0.2
		var shake_tween = create_tween()
		shake_tween.tween_method(func(s): camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s)),
							shake_strength, 0, shake_duration)

	# 3. Create a damage animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.5), 0.1)
	tween.tween_property(self, "modulate", Color(1, 0, 0, 1), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.5), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)

	# Start invincibility
	is_invincible = true
	invincibility_timer.start()

	# Check for death
	if current_health <= 0:
		die()

# Heal the player
func heal(amount):
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health)

	# Show healing effect
	var heal_label = Label.new()
	heal_label.text = "+" + str(amount)
	heal_label.position = Vector2(-20, -50)
	heal_label.modulate = Color(0.0, 1.0, 0.0, 1.0)
	add_child(heal_label)

	# Animate and remove
	var tween = create_tween()
	tween.tween_property(heal_label, "position:y", -70, 0.5)
	tween.parallel().tween_property(heal_label, "modulate:a", 0, 0.5)
	await tween.finished
	heal_label.queue_free()

# Player death
func die():
	# Emit died signal
	died.emit()
	# We don't queue_free the player, as the main scene will handle game over

# Add a weapon to the player
func add_weapon(weapon_scene, level = 1):
	# Check if we already have this weapon
	for weapon in weapon_container.get_children():
		if weapon.name == weapon_scene.instance().name:
			# Upgrade existing weapon
			weapon.upgrade(level)
			return

	# Add new weapon
	var weapon_instance = weapon_scene.instance()
	weapon_instance.level = level
	weapon_container.add_child(weapon_instance)

# Upgrade a specific stat
func upgrade_stat(stat_name, amount):
	match stat_name:
		"max_health":
			max_health += amount
			heal(amount)  # Heal by the amount of max health increase
		"move_speed":
			move_speed += amount

# Signal handlers
func _on_hit_box_body_entered(body):
	# 使用 call_deferred 延迟处理碰撞，避免在物理查询刷新时修改状态
	call_deferred("_process_collision", body)

# 处理碰撞
func _process_collision(body):
	if body.is_in_group("enemies"):
		# 使用默认伤害值，因为新的敌人类使用不同的属性名
		var damage_amount = 10
		if body.has_method("get_attack_damage"):
			damage_amount = body.get_attack_damage()
		elif "attack_damage" in body:
			damage_amount = body.attack_damage
		elif "damage" in body:
			damage_amount = body.damage

		take_damage(damage_amount)

func _on_invincibility_timer_timeout():
	is_invincible = false
	modulate = Color(1, 1, 1, 1)  # Reset color
