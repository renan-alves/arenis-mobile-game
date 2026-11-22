extends SceneTree
const Preferences = preload("res://scripts/preferences.gd")
const Progress = preload("res://scripts/progress.gd")
const Demo = preload("res://scripts/mechanic_demo.gd")
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
	var path := OS.get_environment("TEMP").path_join("arenis-mechanics-%d" % Time.get_ticks_usec())
	var app = load("res://scenes/main.tscn").instantiate()
	app.preferences = Preferences.new(path + ".prefs")
	app.preferences.theme_mode = "light"
	app.preferences.language_mode = "pt_BR"
	app.preferences.basic_tutorial_seen = true
	app.progress = Progress.new(path + ".progress")
	root.add_child(app)
	await process_frame
	for index in [25, 60, 100]:
		app.preferences.mechanics_seen.clear()
		app.preferences.mechanics_seen["journey.moves"] = true
		app.preferences.mechanics_seen["journey.timed"] = true
		app.progress.records[app.levels[index - 1].id] = {"version": int(app.levels[index - 1].version), "stars": 1, "best_moves": 100}
		app._start(index, true)
		var expected: String = {25: "hidden", 60: "combined", 100: "combined"}[index]
		check(is_instance_valid(app.overlay) and app.overlay.get_meta("mechanic", "") == expected, "First encounter has a specific obstacle card: %d" % index)
		var demos: Array = app.overlay.find_children("*", "VBoxContainer", true, false).filter(func(node): return node.get_script() == Demo)
		check(demos.size() == 1 and demos[0].capacity == app.game.capacity, "Illustration uses the current difficulty capacity")
		var demo = demos[0]
		var before: Dictionary = app.game.snapshot()
		var knowledge: Dictionary = app.game.known.duplicate()
		demo.play()
		await create_timer(1.05).timeout
		if expected == "hidden":
			check(demo.game.known.has("0:0"), "Example reveals its hidden layer after removing the top")
		else:
			check(not demo.game.locks[2] and demo.game.bottles[0].size() == demo.capacity, "Example fills key color and unlocks its tube")
			if expected == "combined":
				check(demo.game.known.has("1:0"), "Combined example also reveals the covered color")
		check(app.game.snapshot() == before and app.game.known == knowledge, "Example never moves or reveals the real board")
		if index == 60:
			app._toggle_theme()
			check(demo.dark_mode and demo.views.all(func(view): return view.dark_mode), "Obstacle illustration follows a live theme change")
		var buttons = app.overlay.find_children("*", "Button", true, false)
		check(buttons.any(func(button): return button.text == "Ver exemplo") and buttons.any(func(button): return button.text == "Entendi, jogar"), "Example has replay and a clear dismiss action")
		app._dismiss_mechanic_intro(expected)
		check(Preferences.new(path + ".prefs").has_seen_mechanic(app.active_difficulty, expected), "Acknowledgement persists for this difficulty")
		if expected == "combined":
			check(app.preferences.has_seen_mechanic(app.active_difficulty, "hidden") and app.preferences.has_seen_mechanic(app.active_difficulty, "locked"), "Combined presentation also covers both individual mechanics")
		app._start(index, true)
		check(not is_instance_valid(app.overlay), "Acknowledged obstacle does not reopen on replay")
	var reloaded := Preferences.new(path + ".prefs")
	check(reloaded.has_seen_mechanic("journey", "hidden") and reloaded.has_seen_mechanic("journey", "locked"), "Single campaign remembers both obstacle explanations")
	check(reloaded.effects_enabled and reloaded.effects_volume == 0.3, "Saving introductions preserves audio preferences")
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(path + ".prefs")
	DirAccess.remove_absolute(path + ".progress")
	print("MECHANIC INTRO: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
