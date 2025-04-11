extends Node

func _init():
	# 确保控制台管理器在暂停时也能工作
	process_mode = Node.PROCESS_MODE_ALWAYS

# 控制台管理器 - 处理游戏内控制台命令

signal command_executed(command, result)

# 命令历史
var command_history = []
var history_index = -1
const MAX_HISTORY = 50

# 注册的命令
var registered_commands = {}

# 初始化
func _ready():
	# 注册基本命令
	register_command("help", func(args): return get_help_text(), "显示帮助信息")
	register_command("clear", func(args): command_executed.emit("clear", ""); return "控制台已清空", "清空控制台")
	register_command("history", func(args): return get_history(), "显示命令历史")
	register_command("echo", func(args): return " ".join(args), "回显文本")
	register_command("version", func(args): return "游戏版本: 1.0.0", "显示游戏版本")

	# 注册游戏测试命令
	register_command("god", func(args): return toggle_god_mode(), "切换无敌模式")
	register_command("kill_all", func(args): return kill_all_enemies(), "杀死所有敌人")
	register_command("spawn", func(args): return spawn_entity(args), "生成实体，用法: spawn [enemy_type] [count=1]")
	register_command("level_up", func(args): return level_up(args), "提升等级，用法: level_up [levels=1]")
	register_command("add_xp", func(args): return add_experience(args), "添加经验，用法: add_xp [amount]")
	register_command("add_weapon", func(args): return add_weapon(args), "添加武器，用法: add_weapon [weapon_id]")
	register_command("list_weapons", func(args): return list_weapons(), "列出所有可用武器")
	register_command("teleport", func(args): return teleport_player(args), "传送玩家，用法: teleport [x] [y]")
	register_command("set_time", func(args): return set_game_time(args), "设置游戏时间，用法: set_time [seconds]")
	register_command("set_difficulty", func(args): return set_difficulty(args), "设置难度，用法: set_difficulty [level]")

# 注册命令
func register_command(name, callback, description = ""):
	registered_commands[name] = {
		"callback": callback,
		"description": description
	}

# 执行命令
func execute_command(command_text):
	# 添加到历史
	add_to_history(command_text)

	# 解析命令
	var parts = command_text.strip_edges().split(" ", false)
	if parts.size() == 0:
		return "请输入命令"

	var command = parts[0].to_lower()
	var args = parts.slice(1)

	# 执行命令
	if registered_commands.has(command):
		return registered_commands[command].callback.call(args)
	else:
		return "未知命令: " + command + "。输入 'help' 获取可用命令列表。"

# 添加到历史
func add_to_history(command):
	command_history.push_front(command)
	if command_history.size() > MAX_HISTORY:
		command_history.pop_back()
	history_index = -1

# 获取历史命令
func get_previous_command():
	if command_history.size() == 0:
		return ""

	history_index = min(history_index + 1, command_history.size() - 1)
	return command_history[history_index]

# 获取下一个历史命令
func get_next_command():
	if command_history.size() == 0 or history_index <= 0:
		history_index = -1
		return ""

	history_index -= 1
	if history_index == -1:
		return ""
	return command_history[history_index]

# 获取帮助文本
func get_help_text():
	var help_text = "可用命令:\n"

	for command in registered_commands.keys():
		help_text += command + " - " + registered_commands[command].description + "\n"

	return help_text

# 获取命令历史
func get_history():
	if command_history.size() == 0:
		return "没有命令历史"

	var history_text = "命令历史:\n"
	for i in range(min(command_history.size(), 10)):
		history_text += str(i + 1) + ": " + command_history[i] + "\n"

	return history_text

# 切换无敌模式
func toggle_god_mode():
	var main = get_tree().get_root().get_node_or_null("Main")
	if not main or not main.player:
		return "无法找到玩家"

	if main.player.has_method("toggle_god_mode"):
		var is_god_mode = main.player.toggle_god_mode()
		return "无敌模式: " + ("开启" if is_god_mode else "关闭")
	else:
		# 尝试添加无敌模式功能
		main.player.set_meta("god_mode", not main.player.get_meta("god_mode", false))
		var is_god_mode = main.player.get_meta("god_mode", false)

		# 修改玩家的take_damage方法
		if is_god_mode:
			main.player.set_meta("original_take_damage", main.player.take_damage)
			main.player.take_damage = func(amount, _knockback_direction = Vector2.ZERO):
				if not main.player.get_meta("god_mode", false):
					main.player.get_meta("original_take_damage").call(amount, _knockback_direction)
				return
		else:
			if main.player.has_meta("original_take_damage"):
				main.player.take_damage = main.player.get_meta("original_take_damage")

		return "无敌模式: " + ("开启" if is_god_mode else "关闭")

# 杀死所有敌人
func kill_all_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = enemies.size()

	for enemy in enemies:
		if enemy.has_method("die"):
			enemy.die()

	return "已杀死 " + str(count) + " 个敌人"

# 生成实体
func spawn_entity(args):
	if args.size() == 0:
		return "用法: spawn [enemy_type] [count=1]"

	var entity_type = args[0]
	var count = 1
	if args.size() > 1:
		count = int(args[1])

	var main = get_tree().get_root().get_node_or_null("Main")
	if not main:
		return "无法找到主场景"

	var spawned = 0
	for i in range(count):
		if main.has_method("spawn_specific_enemy"):
			if main.spawn_specific_enemy(entity_type):
				spawned += 1
		else:
			# 尝试手动生成
			var enemy_factory = main.get_node_or_null("GameWorld/EnemyFactory")
			if enemy_factory and enemy_factory.has_method("create_enemy"):
				var enemy = enemy_factory.create_enemy(entity_type)
				if enemy:
					# 设置位置在玩家附近随机位置
					var player_pos = main.player.global_position
					var spawn_pos = player_pos + Vector2(randf_range(-200, 200), randf_range(-200, 200))
					enemy.global_position = spawn_pos

					# 添加到场景
					main.get_node("GameWorld/Enemies").add_child(enemy)
					spawned += 1

	return "已生成 " + str(spawned) + " 个 " + entity_type

# 提升等级
func level_up(args):
	var levels = 1
	if args.size() > 0:
		levels = int(args[0])

	var main = get_tree().get_root().get_node_or_null("Main")
	if not main:
		return "无法找到主场景"

	for i in range(levels):
		if main.has_method("level_up"):
			main.level_up()

	return "已提升 " + str(levels) + " 级，当前等级: " + str(main.player_level)

# 添加经验
func add_experience(args):
	if args.size() == 0:
		return "用法: add_xp [amount]"

	var amount = int(args[0])
	var main = get_tree().get_root().get_node_or_null("Main")
	if not main:
		return "无法找到主场景"

	if main.has_method("add_experience"):
		main.add_experience(amount)
		return "已添加 " + str(amount) + " 点经验"
	else:
		return "无法添加经验"

# 添加武器
func add_weapon(args):
	if args.size() == 0:
		return "用法: add_weapon [weapon_id]"

	var weapon_id = args[0]
	var main = get_tree().get_root().get_node_or_null("Main")
	if not main or not main.weapon_manager:
		return "无法找到武器管理器"

	if main.weapon_manager.has_method("add_weapon"):
		main.weapon_manager.add_weapon(weapon_id)
		return "已添加武器: " + weapon_id
	else:
		return "无法添加武器"

# 列出所有可用武器
func list_weapons():
	var main = get_tree().get_root().get_node_or_null("Main")
	if not main or not main.weapon_manager:
		return "无法找到武器管理器"

	var weapons = main.weapon_manager.get_available_weapons()
	if weapons.size() == 0:
		return "没有可用武器"

	var weapon_list = "可用武器:\n"
	for weapon in weapons:
		weapon_list += "- " + weapon + "\n"

	return weapon_list

# 传送玩家
func teleport_player(args):
	if args.size() < 2:
		return "用法: teleport [x] [y]"

	var x = float(args[0])
	var y = float(args[1])

	var main = get_tree().get_root().get_node_or_null("Main")
	if not main or not main.player:
		return "无法找到玩家"

	main.player.global_position = Vector2(x, y)
	return "已传送玩家到 (" + str(x) + ", " + str(y) + ")"

# 设置游戏时间
func set_game_time(args):
	if args.size() == 0:
		return "用法: set_time [seconds]"

	var seconds = float(args[0])
	var main = get_tree().get_root().get_node_or_null("Main")
	if not main:
		return "无法找到主场景"

	main.game_time = seconds
	main.update_timer_display()
	return "已设置游戏时间为 " + str(seconds) + " 秒"

# 设置难度
func set_difficulty(args):
	if args.size() == 0:
		return "用法: set_difficulty [level]"

	var level = int(args[0])
	var main = get_tree().get_root().get_node_or_null("Main")
	if not main:
		return "无法找到主场景"

	# 设置难度相关参数
	var enemy_spawn_interval = max(0.2, 1.0 - (level * 0.1))
	var enemy_health_multiplier = 1.0 + (level * 0.2)
	var enemy_damage_multiplier = 1.0 + (level * 0.1)

	# 使用属性访问器或调用方法来设置难度
	if main.has_method("set_difficulty_params"):
		main.set_difficulty_params(enemy_spawn_interval, enemy_health_multiplier, enemy_damage_multiplier)
	elif main.get("enemy_spawner") and main.enemy_spawner.has_method("set_difficulty"):
		main.enemy_spawner.set_difficulty(level, enemy_health_multiplier, enemy_damage_multiplier)
	elif main.has_method("set_enemy_spawn_interval"):
		main.set_enemy_spawn_interval(enemy_spawn_interval)
		# 尝试其他方法
		if main.has_method("set_enemy_health_multiplier"):
			main.set_enemy_health_multiplier(enemy_health_multiplier)
		if main.has_method("set_enemy_damage_multiplier"):
			main.set_enemy_damage_multiplier(enemy_damage_multiplier)
	else:
		# 尝试直接设置属性，但使用 set 方法避免直接访问错误
		if main.get("enemy_spawn_interval") != null:
			main.set("enemy_spawn_interval", enemy_spawn_interval)
		if main.get("enemy_health_multiplier") != null:
			main.set("enemy_health_multiplier", enemy_health_multiplier)
		if main.get("enemy_damage_multiplier") != null:
			main.set("enemy_damage_multiplier", enemy_damage_multiplier)

	return "已设置难度为 " + str(level) + "\n" + \
		   "敌人生成间隔: " + str(enemy_spawn_interval) + "\n" + \
		   "敌人生命值倍率: " + str(enemy_health_multiplier) + "\n" + \
		   "敌人伤害倍率: " + str(enemy_damage_multiplier)
