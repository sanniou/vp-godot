extends Node

# 翻译检查工具
# 用于检查翻译文件的完整性和正确性，并自动修复常见问题

# 检查翻译文件
static func check_translations(base_language: String = "en_US") -> Dictionary:
	var result = {
		"missing_keys": {},
		"extra_keys": {},
		"empty_values": {},
		"total_keys": 0,
		"languages": []
	}
	
	# 加载基准语言文件
	var base_translations = _load_language_file(base_language)
	if base_translations.is_empty():
		return result
	
	result["total_keys"] = base_translations.size()
	
	# 获取所有语言文件
	var languages = _get_available_languages()
	result["languages"] = languages
	
	# 检查每种语言
	for language_code in languages:
		if language_code == base_language:
			continue
		
		# 加载当前语言文件
		var current_translations = _load_language_file(language_code)
		if current_translations.is_empty():
			result["missing_keys"][language_code] = base_translations.keys()
			continue
		
		# 检查缺失的键
		var missing_keys = []
		for key in base_translations.keys():
			if not current_translations.has(key):
				missing_keys.append(key)
		
		if missing_keys.size() > 0:
			result["missing_keys"][language_code] = missing_keys
		
		# 检查多余的键
		var extra_keys = []
		for key in current_translations.keys():
			if not base_translations.has(key):
				extra_keys.append(key)
		
		if extra_keys.size() > 0:
			result["extra_keys"][language_code] = extra_keys
		
		# 检查空值
		var empty_values = []
		for key in current_translations.keys():
			if current_translations[key] is String and current_translations[key].is_empty():
				empty_values.append(key)
		
		if empty_values.size() > 0:
			result["empty_values"][language_code] = empty_values
	
	return result

# 修复翻译文件
static func fix_translations(base_language: String = "en_US") -> Dictionary:
	var result = {
		"fixed_languages": {},
		"total_fixed": 0
	}
	
	# 检查翻译
	var check_result = check_translations(base_language)
	
	# 修复每种语言
	for language_code in check_result["languages"]:
		if language_code == base_language:
			continue
		
		var fixed_count = 0
		
		# 修复缺失的键
		if check_result["missing_keys"].has(language_code):
			var missing_keys = check_result["missing_keys"][language_code]
			if missing_keys.size() > 0:
				var patch = _generate_missing_translations_patch(language_code, base_language)
				if _apply_patch_to_language_file(language_code, patch):
					fixed_count += missing_keys.size()
		
		# 记录修复结果
		if fixed_count > 0:
			result["fixed_languages"][language_code] = fixed_count
			result["total_fixed"] += fixed_count
	
	return result

# 生成翻译报告
static func generate_report(base_language: String = "en_US") -> String:
	var check_result = check_translations(base_language)
	
	var report = "翻译检查报告\n"
	report += "=============\n\n"
	report += "基准语言: " + base_language + "\n"
	report += "总键数: " + str(check_result["total_keys"]) + "\n"
	report += "支持的语言: " + str(check_result["languages"]) + "\n\n"
	
	# 报告缺失的键
	if check_result["missing_keys"].is_empty():
		report += "所有语言文件都包含所有必要的键。\n\n"
	else:
		report += "缺失的键:\n"
		for language_code in check_result["missing_keys"].keys():
			var missing_keys = check_result["missing_keys"][language_code]
			report += "  " + language_code + ": " + str(missing_keys.size()) + " 个缺失的键\n"
			
			# 只显示前10个键，避免报告过长
			var keys_to_show = missing_keys.slice(0, min(10, missing_keys.size()))
			for key in keys_to_show:
				report += "    - " + key + "\n"
			
			if missing_keys.size() > 10:
				report += "    - ... 以及 " + str(missing_keys.size() - 10) + " 个其他键\n"
			
			report += "\n"
	
	# 报告多余的键
	if not check_result["extra_keys"].is_empty():
		report += "多余的键:\n"
		for language_code in check_result["extra_keys"].keys():
			var extra_keys = check_result["extra_keys"][language_code]
			report += "  " + language_code + ": " + str(extra_keys.size()) + " 个多余的键\n"
			
			# 只显示前10个键，避免报告过长
			var keys_to_show = extra_keys.slice(0, min(10, extra_keys.size()))
			for key in keys_to_show:
				report += "    - " + key + "\n"
			
			if extra_keys.size() > 10:
				report += "    - ... 以及 " + str(extra_keys.size() - 10) + " 个其他键\n"
			
			report += "\n"
	
	# 报告空值
	if not check_result["empty_values"].is_empty():
		report += "空值:\n"
		for language_code in check_result["empty_values"].keys():
			var empty_values = check_result["empty_values"][language_code]
			report += "  " + language_code + ": " + str(empty_values.size()) + " 个空值\n"
			
			# 只显示前10个键，避免报告过长
			var keys_to_show = empty_values.slice(0, min(10, empty_values.size()))
			for key in keys_to_show:
				report += "    - " + key + "\n"
			
			if empty_values.size() > 10:
				report += "    - ... 以及 " + str(empty_values.size() - 10) + " 个其他键\n"
			
			report += "\n"
	
	return report

# 获取可用的语言
static func _get_available_languages() -> Array:
	var languages = []
	var dir = DirAccess.open("res://languages")
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var language_code = file_name.get_basename()
				languages.append(language_code)
			
			file_name = dir.get_next()
	
	return languages

# 加载语言文件
static func _load_language_file(language_code: String) -> Dictionary:
	var file_path = "res://languages/" + language_code + ".json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		return {}
	
	# 读取文件内容
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		return {}
	
	# 获取翻译数据
	var data = json.get_data()
	
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	
	return data

# 生成缺失翻译的补丁
static func _generate_missing_translations_patch(language_code: String, base_language: String = "en_US") -> Dictionary:
	var base_translations = _load_language_file(base_language)
	var current_translations = _load_language_file(language_code)
	
	var patch = {}
	
	for key in base_translations.keys():
		if not current_translations.has(key):
			# 添加缺失的键，使用基准语言的值作为默认值
			patch[key] = base_translations[key]
	
	return patch

# 将补丁应用到语言文件
static func _apply_patch_to_language_file(language_code: String, patch: Dictionary) -> bool:
	var file_path = "res://languages/" + language_code + ".json"
	
	# 加载当前语言文件
	var current_translations = _load_language_file(language_code)
	if current_translations.is_empty():
		current_translations = patch
	else:
		# 合并补丁
		for key in patch.keys():
			current_translations[key] = patch[key]
	
	# 将更新后的翻译写回文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	
	# 将字典转换为JSON文本
	var json_text = JSON.stringify(current_translations, "\t")
	
	# 写入文件
	file.store_string(json_text)
	file.close()
	
	return true
