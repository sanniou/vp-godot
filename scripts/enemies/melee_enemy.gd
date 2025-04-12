extends "res://scripts/enemies/abstract_enemy.gd"

func _init():
    super._init("melee_enemy", "近战敌人", AbstractEnemy.EnemyType.MELEE)

# 重写视觉效果设置
func setup_visuals():
    # 创建敌人视觉节点
    var visual_node = Node2D.new()
    visual_node.name = "EnemyVisual"
    add_child(visual_node)

    # 创建敌人身体 - 使用六边形代替方块
    var body = Polygon2D.new()
    body.name = "Body"
    body.color = Color(0.8, 0.2, 0.2, 1.0)  # 红色
    body.polygon = PackedVector2Array([
        Vector2(-15, -15),
        Vector2(15, -15),
        Vector2(22, 0),
        Vector2(15, 15),
        Vector2(-15, 15),
        Vector2(-22, 0)
    ])
    visual_node.add_child(body)

    # 创建眼睛节点
    var eyes = Node2D.new()
    eyes.name = "Eyes"
    visual_node.add_child(eyes)

    # 创建左眼
    var left_eye = Polygon2D.new()
    left_eye.name = "LeftEye"
    left_eye.position = Vector2(-8, -5)
    left_eye.color = Color(1, 1, 1, 1)
    left_eye.polygon = PackedVector2Array([
        Vector2(-3, -3),
        Vector2(3, -3),
        Vector2(3, 3),
        Vector2(-3, 3)
    ])
    eyes.add_child(left_eye)

    # 创建左眼瞳孔
    var left_pupil = Polygon2D.new()
    left_pupil.name = "LeftPupil"
    left_pupil.color = Color(0, 0, 0, 1)
    left_pupil.polygon = PackedVector2Array([
        Vector2(-1, -1),
        Vector2(1, -1),
        Vector2(1, 1),
        Vector2(-1, 1)
    ])
    left_eye.add_child(left_pupil)

    # 创建右眼
    var right_eye = Polygon2D.new()
    right_eye.name = "RightEye"
    right_eye.position = Vector2(8, -5)
    right_eye.color = Color(1, 1, 1, 1)
    right_eye.polygon = PackedVector2Array([
        Vector2(-3, -3),
        Vector2(3, -3),
        Vector2(3, 3),
        Vector2(-3, 3)
    ])
    eyes.add_child(right_eye)

    # 创建右眼瞳孔
    var right_pupil = Polygon2D.new()
    right_pupil.name = "RightPupil"
    right_pupil.color = Color(0, 0, 0, 1)
    right_pupil.polygon = PackedVector2Array([
        Vector2(-1, -1),
        Vector2(1, -1),
        Vector2(1, 1),
        Vector2(-1, 1)
    ])
    right_eye.add_child(right_pupil)

    # 创建嘴巴
    var mouth = Polygon2D.new()
    mouth.name = "Mouth"
    mouth.position = Vector2(0, 5)
    mouth.color = Color(0.5, 0, 0, 1)
    mouth.polygon = PackedVector2Array([
        Vector2(-8, 0),
        Vector2(8, 0),
        Vector2(5, 5),
        Vector2(-5, 5)
    ])
    visual_node.add_child(mouth)

    # 注意：血条已经在基本敌人中设置，不需要在这里创建

# 重写攻击系统设置
func setup_attack_system():
    attack_system = load("res://scripts/enemies/attacks/melee_attack.gd").new()
    attack_system.setup(self, attack_damage, attack_range)
    add_child(attack_system)
