extends SceneTree
const Audio = preload("res://scripts/audio.gd")
const Preferences = preload("res://scripts/preferences.gd")
var checks := 0
var failures := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var path := OS.get_environment("TEMP").path_join("arenis-sand-ending-%d.cfg" % Time.get_ticks_usec())
	var prefs := Preferences.new(path)
	var audio := Audio.new()
	audio.preferences = prefs
	root.add_child(audio)
	audio.begin_sand()
	audio.update_sand_flow(0.4)
	var full := audio.sand_gain
	audio.update_sand_flow(0.7)
	var tapering := audio.sand_gain
	audio.update_sand_flow(1.0)
	check(full > tapering and tapering > audio.sand_gain and audio.sand_gain > 0, "Flow audibly diminishes before animation ends")
	check(is_equal_approx(db_to_linear(audio.sand.volume_db), prefs.effects_volume * audio.sand_gain), "Flow envelope preserves configured volume")
	var before := audio.sand_gain
	audio.end_sand()
	check(audio.sand.playing and audio.sand_gain == before, "Ending does not stop or drop gain immediately")
	await create_timer(0.15).timeout
	check(audio.sand.playing and audio.sand_gain > before * 0.7 and audio.sand_gain < before, "Tail remains audible while tapering gradually")
	audio.update_sand_flow(0.0)
	check(audio.sand_gain < before, "Animation updates cannot restore a releasing flow")
	audio.begin_sand()
	check(not audio.sand_releasing and audio.sand_gain == 1 and audio.sand.playing, "New transfer cancels previous release and starts fresh")
	await create_timer(0.4).timeout
	check(audio.sand.playing and audio.sand_gain == 1, "Cancelled release cannot stop the next pour")
	audio.end_sand()
	await create_timer(Audio.SAND_RELEASE_SECONDS + 0.08).timeout
	check(not audio.sand.playing and audio.sand_gain == 0, "Tail stops after amplitude reaches zero")
	audio.begin_sand()
	audio.end_sand()
	prefs.effects_enabled = false
	audio.apply_preferences()
	check(not audio.sand.playing and not audio.sand_releasing, "Explicit mute still stops playback immediately")
	prefs.effects_enabled = true
	audio.queue_free()
	await process_frame
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.level_pack_path = "res://data/prototype_levels.json"
	scene.preferences = prefs
	root.add_child(scene)
	scene._start(2)
	scene._close_modal(false)
	await process_frame
	scene.game.pour(1, 0)
	scene._refresh()
	scene._on_bottle(1)
	scene._on_bottle(2)
	await scene.transfer_finished
	await process_frame
	check(scene.game.won() and is_instance_valid(scene.overlay), "Victory still waits for animation")
	check(scene.audio.sand.playing and scene.audio.sand_releasing and scene.audio.sand_gain > 0, "Last grains continue after animation and over result")
	await create_timer(Audio.SAND_RELEASE_SECONDS).timeout
	check(not scene.audio.sand.playing, "Result does not leave a sound playing indefinitely")
	check(scene.audio.sand.stream.get_length() >= 1.9 * 0.82 + Audio.SAND_RELEASE_SECONDS, "Recording covers longest pour and its complete tail")
	scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	DirAccess.remove_absolute(path)
	print("SAND ENDING: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
