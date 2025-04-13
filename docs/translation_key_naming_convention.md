# 翻译键命名规范

本文档定义了项目中使用的翻译键命名规范，以确保翻译系统的一致性和可维护性。

## 基本规则

1. 所有翻译键使用小写字母和下划线
2. 不使用空格或其他特殊字符
3. 使用有意义的前缀来分类不同类型的文本
4. 保持键名简洁但描述性强

## 前缀规范

以下是不同类型文本的前缀规范：

| 前缀 | 用途 | 示例 |
|------|------|------|
| `ui_` | 用户界面元素 | `ui_start_button`, `ui_options` |
| `menu_` | 菜单项 | `menu_main`, `menu_settings` |
| `weapon_` | 武器相关 | `weapon_knife_name`, `weapon_gun_desc` |
| `enemy_` | 敌人相关 | `enemy_basic_name`, `enemy_boss_desc` |
| `relic_` | 遗物相关 | `relic_crystal_name`, `relic_amulet_desc` |
| `achievement_` | 成就相关 | `achievement_first_blood_name` |
| `stat_` | 统计数据 | `stat_time_survived`, `stat_enemies_defeated` |
| `effect_` | 游戏效果 | `effect_heal`, `effect_level_up` |
| `msg_` | 游戏消息 | `msg_game_over`, `msg_level_up` |
| `help_` | 帮助文本 | `help_controls`, `help_gameplay` |

## 命名模式

### 通用项目

通用UI元素和菜单项使用简单的前缀加名称：

```
ui_start_button
menu_settings
```

### 物品名称和描述

物品（武器、遗物等）的名称和描述使用以下模式：

```
[类型]_[物品ID]_name
[类型]_[物品ID]_desc
```

示例：
```
weapon_knife_name
weapon_knife_desc
relic_crystal_name
relic_crystal_desc
```

### 升级选项

升级选项使用以下模式：

```
[类型]_upgrade_[属性]
[类型]_upgrade_[属性]_desc
```

示例：
```
weapon_upgrade_damage
weapon_upgrade_damage_desc
player_upgrade_max_health
player_upgrade_max_health_desc
```

### 成就

成就使用以下模式：

```
achievement_[成就ID]_name
achievement_[成就ID]_desc
```

示例：
```
achievement_first_blood_name
achievement_first_blood_desc
```

## 参数化文本

对于需要在运行时插入值的文本，使用花括号占位符：

```
player_upgrade_max_health: "最大生命值 +{0}"
effect_heal: "治疗 +{0}"
```

## 注意事项

1. 保持一致性：一旦为某类内容确定了命名模式，就应在整个项目中保持一致
2. 避免硬编码：所有面向用户的文本都应使用翻译系统，避免硬编码
3. 文档化：新增的翻译键应在本文档中更新相应的规范
