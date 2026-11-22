extends SceneTree
const Progress = preload("res://scripts/progress.gd")
const Preferences = preload("res://scripts/preferences.gd")
const Rules = preload("res://scripts/rules.gd")
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
	var path := OS.get_environment("TEMP").path_join("arenis-session-%d" % Time.get_ticks_usec())
	var levels: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/prototype_levels.json")).levels
	var progress := Progress.new(path + ".cfg")
	var hidden := Rules.new(levels[3])
	hidden.pour(0, 2)
	hidden.undo()
	check(progress.save_attempt(levels[3], hidden) == OK, "Hidden attempt saved")
	var loaded := Progress.new(path + ".cfg")
	var restored = loaded.restore_attempt(levels[3])
	check(restored != null and restored.snapshot() == hidden.snapshot(), "Moves and board restore exactly")
	check(restored.known == hidden.known and restored.history == hidden.history, "Discoveries and complete undo history restore")
	check(restored.actions == hidden.actions and restored.moves == 2, "Undo remains counted in restored journal")
	restored.pour(0, 2)
	check(restored.undo() and restored.moves == 4, "Restored history remains usable")
	var locked := Rules.new(levels[4])
	locked.pour(1, 0)
	check(progress.save_attempt(levels[4], locked) == OK, "Latched unlock saved")
	restored = Progress.new(path + ".cfg").restore_attempt(levels[4])
	check(restored != null and restored.locks == locked.locks and restored.known == locked.known, "Lock state is reproduced with its knowledge")
	check(progress.restore_attempt(levels[3]) == null, "Only one attempt is kept per difficulty")
	var easy := Rules.new(levels[0])
	easy.pour(0, 2)
	check(progress.save_attempt(levels[0], easy) == OK and progress.attempts.size() == 2, "Different difficulties keep independent attempts")
	check(progress.latest_attempt(levels) == 0 and progress.latest_attempt(levels, "medium") == 4, "Continue selects most recent attempt")
	var changed: Dictionary = levels[0].duplicate(true)
	changed.version = 99
	check(progress.restore_attempt(changed) == null, "Different board revision cannot resume old attempt")
	var original: Dictionary = progress.attempts.easy.duplicate(true)
	progress.attempts.easy.actions = [["pour", -1, 1]]
	check(progress.restore_attempt(levels[0]) == null, "Illegal or damaged journal is rejected")
	progress.attempts.easy = original
	check(FileAccess.file_exists(path + ".cfg.bak"), "Atomic save keeps last-good backup")
	DirAccess.remove_absolute(path + ".cfg")
	var recovered := Progress.new(path + ".cfg")
	check(recovered.recovered and recovered.restore_attempt(levels[4]) != null, "Backup recovers a missing primary save")
	var profile := Progress.new(path + ".ui")
	var app = load("res://scenes/main.tscn").instantiate()
	app.progress = profile
	app.preferences = Preferences.new(path + ".prefs")
	app.preferences.theme_mode = "light"
	app.preferences.language_mode = "pt_BR"
	root.add_child(app)
	app._start(0)
	app._close_modal(false)
	await process_frame
	var proofs: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/relatorios/jornada-v3-provas.json")).results
	var first_move: Array = proofs[0].solution[0]
	app._on_bottle(first_move[0])
	app._on_bottle(first_move[1])
	check(Progress.new(path + ".ui").restore_attempt(app.levels[0]).moves == 1, "Move checkpoint exists before animation completes")
	await app.transfer_finished
	await process_frame
	var snapshot: Dictionary = app.game.snapshot()
	app._leave_level()
	app._difficulty_menu()
	check(app.root.find_children("*", "Button", true, false).any(func(button): return button.text.begins_with("Continuar —")), "Home exposes Continue")
	app._start(0)
	check(app.game.snapshot() == snapshot and not is_instance_valid(app.overlay), "Continue restores gameplay without repeating introductions")
	profile.records[app.levels[0].id] = {"version": 1, "stars": 3, "best_moves": 3}
	app._start(1)
	check(is_instance_valid(app.overlay) and app.level_index == 0, "Replacing another attempt requires confirmation")
	app._close_modal(false)
	app._start(1, true)
	check(profile.attempts.journey.level_id == app.levels[1].id, "Confirmed replacement starts the selected level")
	app._close_modal(false)
	for step in proofs[1].solution:
		app.game.pour(step[0], step[1])
	app._save_attempt()
	var win := Progress.new(path + ".ui")
	check(win.record(app.levels[1]).stars == 3 and not win.attempts.has("journey"), "Win stores score and removes attempt atomically")
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	for suffix in [".cfg", ".cfg.bak", ".ui", ".ui.bak", ".prefs", ".prefs.bak"]:
		DirAccess.remove_absolute(path + suffix)
	print("SESSIONS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
