extends Node
class_name UIComponentPool

# UI组件池 - 用于减少UI组件的实例化和销毁开销

# 组件池
var pools = {}

# 组件场景路径
var scene_paths = {}

# 初始化组件池
func initialize_pool(component_type: String, scene_path: String, initial_size: int = 5):
	# 如果池已经存在，不重复初始化
	if pools.has(component_type):
		return
	
	# 创建新的池
	pools[component_type] = []
	scene_paths[component_type] = scene_path
	
	# 预创建组件
	for i in range(initial_size):
		var component = _create_component(component_type)
		if component:
			_return_to_pool(component_type, component)
	
	print("UI组件池: 初始化 %s 池，大小: %d" % [component_type, initial_size])

# 从池中获取组件
func get_component(component_type: String) -> Node:
	# 如果池不存在，初始化它
	if not pools.has(component_type):
		if not scene_paths.has(component_type):
			push_error("UI组件池: 未知的组件类型: " + component_type)
			return null
		initialize_pool(component_type, scene_paths[component_type])
	
	# 如果池中有可用组件，返回它
	if pools[component_type].size() > 0:
		var component = pools[component_type].pop_back()
		return component
	
	# 如果池为空，创建新组件
	return _create_component(component_type)

# 将组件返回到池中
func return_component(component_type: String, component: Node):
	# 如果池不存在，初始化它
	if not pools.has(component_type):
		if not scene_paths.has(component_type):
			push_error("UI组件池: 未知的组件类型: " + component_type)
			return
		initialize_pool(component_type, scene_paths[component_type])
	
	# 重置组件状态
	_reset_component(component)
	
	# 将组件返回到池中
	_return_to_pool(component_type, component)

# 清空池
func clear_pool(component_type: String = ""):
	if component_type.is_empty():
		# 清空所有池
		for type in pools.keys():
			_clear_pool_by_type(type)
		pools.clear()
		scene_paths.clear()
	else:
		# 清空指定类型的池
		if pools.has(component_type):
			_clear_pool_by_type(component_type)
			pools.erase(component_type)
			scene_paths.erase(component_type)

# 获取池大小
func get_pool_size(component_type: String) -> int:
	if pools.has(component_type):
		return pools[component_type].size()
	return 0

# 获取所有池的信息
func get_pools_info() -> Dictionary:
	var info = {}
	for type in pools.keys():
		info[type] = {
			"size": pools[type].size(),
			"scene_path": scene_paths[type]
		}
	return info

# 创建组件
func _create_component(component_type: String) -> Node:
	if not scene_paths.has(component_type):
		push_error("UI组件池: 未知的组件类型: " + component_type)
		return null
	
	var scene_path = scene_paths[component_type]
	var scene = load(scene_path)
	if not scene:
		push_error("UI组件池: 无法加载场景: " + scene_path)
		return null
	
	var component = scene.instantiate()
	component.set_meta("pool_type", component_type)
	
	return component

# 重置组件状态
func _reset_component(component: Node):
	# 从父节点中移除
	if component.get_parent():
		component.get_parent().remove_child(component)
	
	# 重置可见性
	component.visible = false
	
	# 重置位置和缩放
	if component is Control:
		component.position = Vector2.ZERO
		component.scale = Vector2.ONE
	elif component is Node2D:
		component.position = Vector2.ZERO
		component.scale = Vector2.ONE
	
	# 重置其他属性
	# 这里可以添加特定组件类型的重置逻辑
	
	# 调用组件的reset方法（如果存在）
	if component.has_method("reset"):
		component.reset()

# 将组件返回到池中
func _return_to_pool(component_type: String, component: Node):
	# 添加到池中
	pools[component_type].append(component)
	
	# 添加到节点树中但不显示
	if not component.is_inside_tree():
		add_child(component)
	
	# 确保不可见
	component.visible = false

# 清空指定类型的池
func _clear_pool_by_type(component_type: String):
	if not pools.has(component_type):
		return
	
	# 销毁池中的所有组件
	for component in pools[component_type]:
		if is_instance_valid(component):
			component.queue_free()
	
	# 清空池
	pools[component_type].clear()
