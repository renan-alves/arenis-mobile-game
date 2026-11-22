extends RefCounted
const Store = preload("res://scripts/config_store.gd")
var path: String
var completions := 0
var cloud_enabled := false

func _init(file_path := "user://services.cfg") -> void:
	path = file_path
	var loaded := Store.read(path)
	if loaded.error == OK:
		var number: Variant = loaded.config.get_value("ads", "completions", 0)
		if number is int and number >= 0:
			completions = mini(number, 2)
		cloud_enabled = loaded.config.get_value("cloud", "enabled", false) == true

func _save(count: int, enabled: bool) -> Error:
	var config := ConfigFile.new()
	config.set_value("ads", "completions", count)
	config.set_value("cloud", "enabled", enabled)
	var error := Store.write(path, config)
	if error == OK:
		completions = count
		cloud_enabled = enabled
	return error

func completed() -> Error:
	return _save(mini(completions + 1, 2), cloud_enabled)

func consume_ad_break() -> Error:
	# Consume only a displayed ad. A failed/unavailable ad never holds navigation.
	return _save(0, cloud_enabled)

func set_cloud_enabled(enabled: bool) -> Error:
	return _save(completions, enabled)
