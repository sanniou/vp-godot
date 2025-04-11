extends Node

# 翻译验证工具
# 用于检查翻译文件的完整性和正确性

# 检查翻译文件是否包含所有必要的键
static func validate_translations(base_language: String = "en_US") -> Dictionary:
	var result = {
		"missing_keys": {},
		"extra_keys": {},
		"total_keys": 0,
		"languages": []
	}
	
	# 获取语言管理器
	var language_manager = Engine.get_main_loop().root.get_node_or_null("LanguageManager")
	if not language_manager:
		return result
	
	# 获取支持的语言列表
	var supported_languages = language_manager.get_supported_languages()
	result["languages"] = supported_languages.keys()
	
	# 加载基准语言文件
	var base_translations = _load_language_file(base_language)
	if base_translations.is_empty():
		return result
	
	result["total_keys"] = base_translations.size()
	
	# 检查每种语言
	for language_code in supported_languages.keys():
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
	
	return result

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

# 生成缺失翻译的报告
static func generate_missing_translations_report(base_language: String = "en_US") -> String:
	var validation_result = validate_translations(base_language)
	var report = "翻译验证报告\n"
	report += "==================\n\n"
	report += "基准语言: " + base_language + "\n"
	report += "总键数: " + str(validation_result["total_keys"]) + "\n\n"
	
	if validation_result["missing_keys"].is_empty():
		report += "所有语言文件都包含所有必要的键。\n"
	else:
		report += "缺失的键:\n"
		for language_code in validation_result["missing_keys"].keys():
			var missing_keys = validation_result["missing_keys"][language_code]
			report += "  " + language_code + ": " + str(missing_keys.size()) + " 个缺失的键\n"
			for key in missing_keys:
				report += "    - " + key + "\n"
			report += "\n"
	
	if not validation_result["extra_keys"].is_empty():
		report += "多余的键:\n"
		for language_code in validation_result["extra_keys"].keys():
			var extra_keys = validation_result["extra_keys"][language_code]
			report += "  " + language_code + ": " + str(extra_keys.size()) + " 个多余的键\n"
			for key in extra_keys:
				report += "    - " + key + "\n"
			report += "\n"
	
	return report

# 生成缺失翻译的JSON补丁
static func generate_missing_translations_patch(language_code: String, base_language: String = "en_US") -> Dictionary:
	var base_translations = _load_language_file(base_language)
	var current_translations = _load_language_file(language_code)
	
	var patch = {}
	
	for key in base_translations.keys():
		if not current_translations.has(key):
			# 添加缺失的键，使用基准语言的值作为默认值
			patch[key] = base_translations[key]
	
	return patch

# 将补丁应用到语言文件
static func apply_patch_to_language_file(language_code: String, patch: Dictionary) -> bool:
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
