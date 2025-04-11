extends "res://scripts/relics/abstract_relic.gd"

# 升级增强器遗物
# 增加升级选项数量，增加重新随机次数，并提高选项的数值

func _init():
    super._init(
        "upgrade_enhancer",
        "升级增强器",
        "增加升级选项数量(+1)，增加重新随机次数(+1)，并提高选项的数值(+20%)",
        "🔮",
        "rare"
    )

# 获取此遗物响应的事件类型
func get_event_types() -> Array:
    return [
        EventType.LEVEL_UP,
        EventType.UPGRADE_OPTIONS,
        EventType.REROLL_COUNT,
        EventType.OPTION_REROLL
    ]

# 处理事件
func on_event(event_type: int, event_data: Dictionary) -> Dictionary:
    var modified_data = event_data.duplicate()

    match event_type:
        EventType.LEVEL_UP:
            # 增加升级选项数量
            if modified_data.has("options_count"):
                modified_data.options_count += 1

        EventType.UPGRADE_OPTIONS:
            # 提高选项的数值
            if modified_data.has("base_options"):
                for option in modified_data.base_options:
                    if option.has("amount"):
                        # 增加数值20%
                        option.amount = option.amount * 1.2

                        # 更新名称和描述以反映增强
                        var main = get_tree().get_root().get_node_or_null("Main")
                        var language_manager = null
                        if main and main.has_method("get_language_manager"):
                            language_manager = main.get_language_manager()

                        if option.type == "max_health":
                            var new_amount = int(option.amount)
                            if language_manager:
                                option.name = language_manager.get_translation("player_upgrade_max_health", "Max Health +{0}").format({"0": str(new_amount)})
                                option.description = language_manager.get_translation("player_upgrade_max_health_desc", "Increase maximum health by {0}").format({"0": str(new_amount)})
                            else:
                                option.name = "Max Health +" + str(new_amount)
                                option.description = "Increase maximum health by " + str(new_amount)
                        elif option.type == "move_speed":
                            var new_amount = int(option.amount)
                            if language_manager:
                                option.name = language_manager.get_translation("player_upgrade_move_speed", "Move Speed +{0}").format({"0": str(new_amount)})
                                option.description = language_manager.get_translation("player_upgrade_move_speed_desc", "Increase movement speed by {0}").format({"0": str(new_amount)})
                            else:
                                option.name = "Move Speed +" + str(new_amount)
                                option.description = "Increase movement speed by " + str(new_amount)
                        elif option.type == "weapon_damage":
                            var new_amount = int(option.amount * 100)
                            if language_manager:
                                option.name = language_manager.get_translation("player_upgrade_weapon_damage", "Weapon Damage +{0}%").format({"0": str(new_amount)})
                                option.description = language_manager.get_translation("player_upgrade_weapon_damage_desc", "Increase all weapon damage by {0}%").format({"0": str(new_amount)})
                            else:
                                option.name = "Weapon Damage +" + str(new_amount) + "%"
                                option.description = "Increase all weapon damage by " + str(new_amount) + "%"

        EventType.REROLL_COUNT:
            # 增加重新随机次数
            if modified_data.has("max_rerolls"):
                modified_data.max_rerolls += 1

        EventType.OPTION_REROLL:
            # 提高重新随机选项的数值
            if modified_data.has("available_options"):
                for option in modified_data.available_options:
                    if option.has("amount"):
                        # 增加数值20%
                        option.amount = option.amount * 1.2

                        # 更新名称和描述以反映增强
                        var main = get_tree().get_root().get_node_or_null("Main")
                        var language_manager = null
                        if main and main.has_method("get_language_manager"):
                            language_manager = main.get_language_manager()

                        if option.type == "max_health":
                            var new_amount = int(option.amount)
                            if language_manager:
                                option.name = language_manager.get_translation("player_upgrade_max_health", "Max Health +{0}").format({"0": str(new_amount)})
                                option.description = language_manager.get_translation("player_upgrade_max_health_desc", "Increase maximum health by {0}").format({"0": str(new_amount)})
                            else:
                                option.name = "Max Health +" + str(new_amount)
                                option.description = "Increase maximum health by " + str(new_amount)
                        elif option.type == "move_speed":
                            var new_amount = int(option.amount)
                            if language_manager:
                                option.name = language_manager.get_translation("player_upgrade_move_speed", "Move Speed +{0}").format({"0": str(new_amount)})
                                option.description = language_manager.get_translation("player_upgrade_move_speed_desc", "Increase movement speed by {0}").format({"0": str(new_amount)})
                            else:
                                option.name = "Move Speed +" + str(new_amount)
                                option.description = "Increase movement speed by " + str(new_amount)
                        elif option.type == "weapon_damage":
                            var new_amount = int(option.amount * 100)
                            if language_manager:
                                option.name = language_manager.get_translation("player_upgrade_weapon_damage", "Weapon Damage +{0}%").format({"0": str(new_amount)})
                                option.description = language_manager.get_translation("player_upgrade_weapon_damage_desc", "Increase all weapon damage by {0}%").format({"0": str(new_amount)})
                            else:
                                option.name = "Weapon Damage +" + str(new_amount) + "%"
                                option.description = "Increase all weapon damage by " + str(new_amount) + "%"

    return modified_data
