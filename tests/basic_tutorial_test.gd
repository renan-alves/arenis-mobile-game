extends SceneTree
const Preferences = preload("res://scripts/preferences.gd")
const Progress = preload("res://scripts/progress.gd")
const Practice = preload("res://scripts/basic_tutorial.gd")
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
	var path := OS.get_environment("TEMP").path_join("arenis-onboarding-%d" % Time.get_ticks_usec())
	var app = load("res://scenes/main.tscn").instantiate()
	app.preferences = Preferences.new(path + ".prefs")
	app.preferences.language_mode = "pt_BR"
	app.preferences.theme_mode = "light"
	app.progress = Progress.new(path + ".progress")
	root.add_child(app)
	app._start(0)
	await process_frame
	check(is_instance_valid(app.overlay) and app.overlay.get_meta("basic_tutorial", false), "First campaign play is guided")
	var demos = app.overlay.find_children("*", "VBoxContainer", true, false).filter(func(node): return node.get_script() == Practice)
	var practice = demos[0]
	var before: Dictionary = app.game.snapshot()
	app._on_bottle(0)
	check(app.game.snapshot() == before, "Real board is blocked during practice")
	practice._tap(1)
	check(practice.game.moves == 0 and practice.selected == -1, "Wrong input guides without changing practice")
	practice._tap(0)
	check(practice.selected == 0, "Practice teaches selecting the source")
	practice._tap(1)
	await create_timer(0.8).timeout
	check(practice.game.moves == 1 and practice.game.bottles[1].size() == 3, "Practice teaches pouring the complete top block")
	practice._tap(0)
	practice._tap(2)
	await create_timer(0.8).timeout
	check(practice.completed and practice.game.won(), "Practice teaches full monochrome objective")
	check(app.game.snapshot() == before and app.progress.record(app.levels[0]).is_empty(), "Practice earns no campaign moves or stars")
	var start = app.overlay.find_children("*", "Button", true, false).filter(func(button): return button.text == "Começar fase")[0]
	check(not start.disabled, "Finishing practice enables start")
	app._finish_basic_tutorial(true)
	check(not is_instance_valid(app.overlay) and Preferences.new(path + ".prefs").basic_tutorial_seen, "Acknowledged tutorial persists")
	app._start(0)
	check(not is_instance_valid(app.overlay), "Tutorial does not repeat on continue")
	app._show_basic_tutorial(false)
	check(is_instance_valid(app.overlay), "Tutorial can be opened again from help")
	app._finish_basic_tutorial(false)
	check(app.game.snapshot() == before and not is_instance_valid(app.overlay), "Skip returns to the same real board")
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	for suffix in [".prefs", ".prefs.bak", ".progress", ".progress.bak"]:
		DirAccess.remove_absolute(path + suffix)
	print("BASIC TUTORIAL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
