extends Node
class_name EnemyStateMachine

# 敌人状态
enum EnemyState {
    IDLE,       # 空闲状态
    CHASE,      # 追逐状态
    ATTACK,     # 攻击状态
    RETREAT,    # 撤退状态
    STUNNED,    # 眩晕状态
    DEAD        # 死亡状态
}

# 当前状态
var current_state = EnemyState.IDLE

# 敌人引用
var enemy = null

# 状态持续时间
var state_time = 0.0

# 状态转换条件
var can_attack = false
var can_see_player = false
var is_stunned = false
var is_dead = false

# 初始化
func _init(enemy_ref):
    enemy = enemy_ref

# 处理状态
func process_state(delta):
    # 更新状态时间
    state_time += delta
    
    # 检查状态转换
    check_state_transitions()
    
    # 处理当前状态
    match current_state:
        EnemyState.IDLE:
            process_idle_state(delta)
        EnemyState.CHASE:
            process_chase_state(delta)
        EnemyState.ATTACK:
            process_attack_state(delta)
        EnemyState.RETREAT:
            process_retreat_state(delta)
        EnemyState.STUNNED:
            process_stunned_state(delta)
        EnemyState.DEAD:
            process_dead_state(delta)

# 检查状态转换
func check_state_transitions():
    # 死亡状态优先级最高
    if is_dead and current_state != EnemyState.DEAD:
        change_state(EnemyState.DEAD)
        return
    
    # 眩晕状态优先级次之
    if is_stunned and current_state != EnemyState.STUNNED:
        change_state(EnemyState.STUNNED)
        return
    
    # 其他状态转换
    match current_state:
        EnemyState.IDLE:
            if can_see_player:
                change_state(EnemyState.CHASE)
        
        EnemyState.CHASE:
            if not can_see_player:
                change_state(EnemyState.IDLE)
            elif can_attack:
                change_state(EnemyState.ATTACK)
        
        EnemyState.ATTACK:
            if not can_attack:
                if can_see_player:
                    change_state(EnemyState.CHASE)
                else:
                    change_state(EnemyState.IDLE)
        
        EnemyState.RETREAT:
            if state_time > 2.0:  # 撤退2秒后
                if can_see_player:
                    change_state(EnemyState.CHASE)
                else:
                    change_state(EnemyState.IDLE)
        
        EnemyState.STUNNED:
            if state_time > enemy.stun_duration:
                is_stunned = false
                if can_see_player:
                    change_state(EnemyState.CHASE)
                else:
                    change_state(EnemyState.IDLE)

# 改变状态
func change_state(new_state):
    # 退出当前状态
    exit_state(current_state)
    
    # 记录旧状态
    var old_state = current_state
    
    # 更新状态
    current_state = new_state
    state_time = 0.0
    
    # 进入新状态
    enter_state(new_state, old_state)

# 进入状态
func enter_state(state, old_state):
    match state:
        EnemyState.IDLE:
            enemy.velocity = Vector2.ZERO
        
        EnemyState.CHASE:
            # 开始追逐动画
            pass
        
        EnemyState.ATTACK:
            # 开始攻击动画
            if enemy.attack_system:
                enemy.attack_system.start_attack()
        
        EnemyState.RETREAT:
            # 开始撤退动画
            pass
        
        EnemyState.STUNNED:
            # 开始眩晕动画
            enemy.velocity = Vector2.ZERO
        
        EnemyState.DEAD:
            # 开始死亡动画
            enemy.velocity = Vector2.ZERO

# 退出状态
func exit_state(state):
    match state:
        EnemyState.ATTACK:
            # 结束攻击动画
            if enemy.attack_system:
                enemy.attack_system.end_attack()
        
        # 其他状态退出逻辑
        _:
            pass

# 处理空闲状态
func process_idle_state(delta):
    # 空闲状态逻辑
    enemy.velocity = Vector2.ZERO

# 处理追逐状态
func process_chase_state(delta):
    # 追逐状态逻辑
    if enemy.target:
        var direction = (enemy.target.global_position - enemy.global_position).normalized()
        enemy.velocity = direction * enemy.move_speed

# 处理攻击状态
func process_attack_state(delta):
    # 攻击状态逻辑
    enemy.velocity = Vector2.ZERO
    
    # 攻击系统处理
    if enemy.attack_system:
        enemy.attack_system.process_attack(delta)

# 处理撤退状态
func process_retreat_state(delta):
    # 撤退状态逻辑
    if enemy.target:
        var direction = (enemy.global_position - enemy.target.global_position).normalized()
        enemy.velocity = direction * enemy.move_speed * 0.7

# 处理眩晕状态
func process_stunned_state(delta):
    # 眩晕状态逻辑
    enemy.velocity = Vector2.ZERO

# 处理死亡状态
func process_dead_state(delta):
    # 死亡状态逻辑
    enemy.velocity = Vector2.ZERO

# 更新状态条件
func update_conditions(player_distance, can_attack_player, stunned, dead):
    can_see_player = player_distance < enemy.detection_range
    can_attack = can_attack_player
    is_stunned = stunned
    is_dead = dead
