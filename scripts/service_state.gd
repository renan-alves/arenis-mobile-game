extends RefCounted
const Store = preload("res://scripts/config_store.gd")
const AD_POLICY_VERSION := 2
const INTRO_LEVELS := 10
const COMPLETIONS_PER_AD := 5
const COOLDOWN_SECONDS := 300
var path: String
var completions := 0
var cloud_enabled := false
var cooldown_started_unix := 0
var time_source: Callable

func _init(file_path := "user://services.cfg", clock := Callable()) -> void:
	path = file_path
	time_source = clock
	cooldown_started_unix = _now_unix()
	var loaded := Store.read(path)
	if loaded.error == OK:
		var config: ConfigFile = loaded.config
		cloud_enabled = config.get_value("cloud", "enabled", false) == true
		var policy: Variant = config.get_value("ads", "policy_version", 0)
		var number: Variant = config.get_value("ads", "completions", 0)
		var anchor: Variant = config.get_value("ads", "cooldown_started_unix", -1)
		if policy is int and policy == AD_POLICY_VERSION and number is int and number >= 0 and anchor is int and anchor >= 0:
			completions = mini(number, COMPLETIONS_PER_AD)
			cooldown_started_unix = anchor
			return
	# Old two-completion counters do not carry into the gentler policy.
	# Persist the initial grace period once, preserving the cloud choice.
	_save(0, cloud_enabled, cooldown_started_unix)

func _now_unix() -> int:
	return int(time_source.call()) if time_source.is_valid() else int(Time.get_unix_time_from_system())

func _save(count: int, enabled: bool, anchor: int) -> Error:
	var config := ConfigFile.new()
	config.set_value("ads", "policy_version", AD_POLICY_VERSION)
	config.set_value("ads", "completions", count)
	config.set_value("ads", "cooldown_started_unix", anchor)
	config.set_value("cloud", "enabled", enabled)
	var error := Store.write(path, config)
	if error == OK:
		completions = count
		cloud_enabled = enabled
		cooldown_started_unix = anchor
	return error

func completed(level_number: int) -> Error:
	if level_number <= INTRO_LEVELS:
		return OK
	return _save(mini(completions + 1, COMPLETIONS_PER_AD), cloud_enabled, cooldown_started_unix)

func can_show_interstitial(level_number: int) -> bool:
	return level_number > INTRO_LEVELS and completions >= COMPLETIONS_PER_AD and _now_unix() - cooldown_started_unix >= COOLDOWN_SECONDS

func consume_ad_break() -> Error:
	# Charge only a displayed ad, never a request/failure. Keep the cooldown
	# in memory even if storage fails, so the session cannot immediately retry.
	var anchor := _now_unix()
	var error := _save(0, cloud_enabled, anchor)
	completions = 0
	cooldown_started_unix = anchor
	return error

func set_cloud_enabled(enabled: bool) -> Error:
	return _save(completions, enabled, cooldown_started_unix)
