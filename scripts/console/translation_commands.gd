extends Node

# 翻译控制台命令
# 提供用于检查和修复翻译的控制台命令

# 注册翻译命令
static func register_commands(console_manager):
	# 检查翻译
	console_manager.register_command("check_translations", func(args): 
		return check_translations_command(args)
	, "检查翻译文件，用法: check_translations [base_language=en_US]")
	
	# 修复翻译
	console_manager.register_command("fix_translations", func(args): 
		return fix_translations_command(args)
	, "修复翻译文件，用法: fix_translations [base_language=en_US]")
	
	# 生成翻译报告
	console_manager.register_command("translation_report", func(args): 
		return translation_report_command(args)
	, "生成翻译报告，用法: translation_report [base_language=en_US]")
	
	# 列出可用语言
	console_manager.register_command("list_languages", func(args): 
		return list_languages_command()
	, "列出所有可用语言")
	
	# 切换语言
	console_manager.register_command("switch_language", func(args): 
		return switch_language_command(args)
	, "切换当前语言，用法: switch_language [language_code]")

# 检查翻译命令
static func check_translations_command(args):
	var base_language = "en_US"
	if args.size() > 0:
		base_language = args[0]
	
	# 加载翻译检查工具
	var TranslationChecker = load("res://scripts/language/translation_checker.gd")
	
	# 检查翻译
	var result = TranslationChecker.check_translations(base_language)
	
	# 生成报告
	var report = "翻译检查结果:\n"
	report += "基准语言: " + base_language + "\n"
	report += "总键数: " + str(result["total_keys"]) + "\n"
	report += "支持的语言: " + str(result["languages"]) + "\n\n"
	
	# 报告缺失的键
	if result["missing_keys"].is_empty():
		report += "所有语言文件都包含所有必要的键。\n\n"
	else:
		report += "缺失的键:\n"
		for language_code in result["missing_keys"].keys():
			var missing_keys = result["missing_keys"][language_code]
			report += "  " + language_code + ": " + str(missing_keys.size()) + " 个缺失的键\n"
	
	# 报告多余的键
	if not result["extra_keys"].is_empty():
		report += "\n多余的键:\n"
		for language_code in result["extra_keys"].keys():
			var extra_keys = result["extra_keys"][language_code]
			report += "  " + language_code + ": " + str(extra_keys.size()) + " 个多余的键\n"
	
	# 报告空值
	if not result["empty_values"].is_empty():
		report += "\n空值:\n"
		for language_code in result["empty_values"].keys():
			var empty_values = result["empty_values"][language_code]
			report += "  " + language_code + ": " + str(empty_values.size()) + " 个空值\n"
	
	return report

# 修复翻译命令
static func fix_translations_command(args):
	var base_language = "en_US"
	if args.size() > 0:
		base_language = args[0]
	
	# 加载翻译检查工具
	var TranslationChecker = load("res://scripts/language/translation_checker.gd")
	
	# 修复翻译
	var result = TranslationChecker.fix_translations(base_language)
	
	# 生成报告
	var report = "翻译修复结果:\n"
	report += "总修复数: " + str(result["total_fixed"]) + "\n\n"
	
	if result["fixed_languages"].is_empty():
		report += "没有需要修复的翻译。\n"
	else:
		report += "修复的语言:\n"
		for language_code in result["fixed_languages"].keys():
			var fixed_count = result["fixed_languages"][language_code]
			report += "  " + language_code + ": " + str(fixed_count) + " 个键已修复\n"
	
	return report

# 生成翻译报告命令
static func translation_report_command(args):
	var base_language = "en_US"
	if args.size() > 0:
		base_language = args[0]
	
	# 加载翻译检查工具
	var TranslationChecker = load("res://scripts/language/translation_checker.gd")
	
	# 生成报告
	return TranslationChecker.generate_report(base_language)

# 列出可用语言命令
static func list_languages_command():
	# 获取语言管理器
	var language_manager = _get_language_manager()
	if not language_manager:
		return "无法获取语言管理器"
	
	# 获取支持的语言
	var languages = language_manager.get_supported_languages()
	
	# 生成报告
	var report = "可用语言:\n"
	for language_code in languages.keys():
		var language_name = languages[language_code]
		report += "  " + language_code + ": " + language_name
		
		# 标记当前语言
		if language_code == language_manager.current_language:
			report += " (当前)"
		
		report += "\n"
	
	return report

# 切换语言命令
static func switch_language_command(args):
	if args.size() == 0:
		return "用法: switch_language [language_code]"
	
	var language_code = args[0]
	
	# 获取语言管理器
	var language_manager = _get_language_manager()
	if not language_manager:
		return "无法获取语言管理器"
	
	# 检查语言是否支持
	if not language_manager.supported_languages.has(language_code):
		return "不支持的语言: " + language_code
	
	# 切换语言
	if language_manager.switch_language(language_code):
		return "已切换语言为: " + language_manager.get_current_language_name()
	else:
		return "切换语言失败"

# 获取语言管理器
static func _get_language_manager():
	var language_manager = Engine.get_main_loop().root.get_node_or_null("LanguageManager")
	
	if not language_manager:
		# 如果找不到语言管理器，尝试从自动加载脚本获取
		var autoload = Engine.get_main_loop().root.get_node_or_null("LanguageAutoload")
		if autoload and autoload.language_manager:
			language_manager = autoload.language_manager
	
	return language_manager
