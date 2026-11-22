extends RefCounted
const Store = preload("res://scripts/config_store.gd")
## Small preference store. Does not contain puzzle progress.
var path: String
var symbols_enabled := false
var effects_enabled := true
var effects_volume := 0.3
var theme_mode := "system"
var mechanics_seen: Dictionary = {}
var language_mode := "system"
var basic_tutorial_seen := false

func _init(file_path := "user://preferences.cfg") -> void:
	path = file_path
	var loaded := Store.read(path)
	var config: ConfigFile = loaded.config
	if loaded.error == OK:
		var value: Variant = config.get_value("accessibility", "color_symbols", false)
		symbols_enabled = value if value is bool else false
		for key in ["effects_enabled"]:
			var flag: Variant = config.get_value("audio", key, get(key))
			if flag is bool:
				set(key, flag)
		for key in ["effects_volume"]:
			var volume: Variant = config.get_value("audio", key, get(key))
			if (volume is float or volume is int) and is_finite(float(volume)):
				set(key, clampf(volume, 0, 1))
		var mode: Variant = config.get_value("appearance", "theme", "system")
		if mode is String and mode in ["system", "light", "dark"]:
			theme_mode = mode
		var language: Variant = config.get_value("appearance", "language", "system")
		if language is String and language in ["system", "pt_BR", "en", "es_419"]:
			language_mode = language
		basic_tutorial_seen = config.get_value("onboarding", "journey_rules_v3", false) == true
		for key in config.get_section_keys("tutorials") if config.has_section("tutorials") else []:
			if config.get_value("tutorials", key) == true:
				mechanics_seen[key] = true

func has_seen_mechanic(difficulty: String, mechanic: String) -> bool:
	return mechanics_seen.get(difficulty + "." + mechanic, false)

func mark_mechanic_seen(difficulty: String, mechanic: String) -> Error:
	if difficulty not in ["journey", "easy", "medium", "hard"] or mechanic not in ["hidden", "locked", "combined", "moves", "timed"]:
		return ERR_INVALID_PARAMETER
	var kinds := ["hidden", "locked", "combined"] if mechanic == "combined" else [mechanic]
	var config: ConfigFile = Store.read(path).config
	for kind in kinds:
		config.set_value("tutorials", difficulty + "." + kind, true)
	var error := Store.write(path, config)
	if error == OK:
		for kind in kinds:
			mechanics_seen[difficulty + "." + kind] = true
	return error

func set_symbols_enabled(enabled: bool) -> Error:
	var config: ConfigFile = Store.read(path).config
	config.set_value("accessibility", "color_symbols", enabled)
	var error := Store.write(path, config)
	if error == OK:
		symbols_enabled = enabled
	return error

func set_audio(key: String, value: Variant) -> Error:
	if key not in ["effects_enabled", "effects_volume"]:
		return ERR_INVALID_PARAMETER
	var config: ConfigFile = Store.read(path).config
	for legacy in ["music_enabled", "music_volume"]:
		if config.has_section_key("audio", legacy):
			config.erase_section_key("audio", legacy)
	config.set_value("audio", key, value)
	var error := Store.write(path, config)
	if error == OK:
		set(key, value)
	return error

func set_theme(mode: String) -> Error:
	if mode not in ["system", "light", "dark"]:
		return ERR_INVALID_PARAMETER
	var config: ConfigFile = Store.read(path).config
	config.set_value("appearance", "theme", mode)
	var error := Store.write(path, config)
	if error == OK:
		theme_mode = mode
	return error

func set_language(mode: String) -> Error:
	if mode not in ["system", "pt_BR", "en", "es_419"]:
		return ERR_INVALID_PARAMETER
	var config: ConfigFile = Store.read(path).config
	config.set_value("appearance", "language", mode)
	var error := Store.write(path, config)
	if error == OK:
		language_mode = mode
	return error

func mark_basic_tutorial() -> Error:
	var config: ConfigFile = Store.read(path).config
	config.set_value("onboarding", "journey_rules_v3", true)
	var error := Store.write(path, config)
	if error == OK:
		basic_tutorial_seen = true
	return error
