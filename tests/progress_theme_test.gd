extends SceneTree
const Preferences = preload("res://scripts/preferences.gd")
const Progress = preload("res://scripts/progress.gd")
const Identity = preload("res://scripts/identity.gd")
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
	var levels: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json")).levels
	var proofs: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/relatorios/jornada-v3-provas.json")).results
	var path := OS.get_environment("TEMP").path_join("arenis-progress-theme-%d" % Time.get_ticks_usec())
	var seed := ConfigFile.new()
	seed.set_value("levels", "level-051", {"version": 99, "stars": 2, "best_moves": 5})
	seed.set_value("levels", "level-101", {"version": 99, "stars": 3, "best_moves": 3})
	seed.set_value("levels", "level-108", {"version": 1, "stars": 3, "best_moves": 22})
	check(seed.save(path + ".cfg") == OK, "Legacy fixture saved")
	var progress := Progress.new(path + ".cfg")
	var scene = _scene(progress, path)
	root.add_child(scene)
	await process_frame
	check(not scene._is_unlocked(51), "Old Medium 1 does not unlock current Medium 2")
	check(progress.record(levels[107]).stars == 3, "Current Hard 8 stars were preserved")
	check(scene._is_unlocked(107), "Already completed current level remains replayable")
	check(progress.records["level-051"].stars == 2 and progress.record(levels[50]).is_empty(), "Old Medium stars remain stored separately")
	check(progress.records["level-101"].stars == 3 and progress.record(levels[100]).is_empty(), "Old Hard stars remain stored separately")
	scene._choose_difficulty("hard")
	await process_frame
	var actions = scene.root.find_children("*", "Button", true, false)
	check(not actions.any(func(button): return button.text == "Resultados anteriores"), "Campaign has no previous results action")
	check(scene.find_child("JourneyMap", true, false).nodes[107][1].text == "★★★", "Current Hard 8 displays its saved stars in grid")
	# Start a clean current board; opening a result without victory cannot save it.
	progress.records[levels[99].id] = {"version": 1, "stars": 1, "best_moves": 50}
	scene._start(100)
	scene._close_modal(false)
	scene._show_result()
	check(progress.record(levels[100]).is_empty() and not is_instance_valid(scene.overlay), "Unfinished board cannot produce a saved result")
	for dark in [false, true]:
		if scene.dark_mode != dark:
			scene._toggle_theme()
			await create_timer(0.35).timeout
		scene._show_settings()
		var toggle: CheckButton = scene.overlay.find_children("*", "CheckButton", true, false)[1]
		toggle.set_pressed_no_signal(true)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var property: String = "font_color" if state == "normal" else "font_" + state + "_color"
			var foreground := toggle.get_theme_color(property)
			var background: StyleBoxFlat = toggle.get_theme_stylebox(state)
			check(_contrast(foreground, background.bg_color) >= 4.5, "Toggle contrast in %s / dark=%s" % [state, dark])
		scene._close_modal(false)
	# Save current Medium/Hard wins via the real final transfer and completion UI.
	for index in [50, 100]:
		progress.records[levels[index-1].id] = {"version": 1, "stars": 1, "best_moves": 50}
		scene._start(index)
		scene._close_modal(false)
		await process_frame
		var solution: Array = proofs[index].solution
		for step in solution.slice(0, -1):
			scene.game.pour(step[0], step[1])
		scene._refresh()
		var final_step: Array = solution[-1]
		scene._on_bottle(final_step[0])
		scene._on_bottle(final_step[1])
		await scene.transfer_finished
		await process_frame
		check(scene.game.won() and is_instance_valid(scene.overlay), "Final animation opens completion for %s" % levels[index].id)
		var reloaded := Progress.new(path + ".cfg")
		check(reloaded.record(levels[index]).stars == 3 and reloaded.record(levels[index]).best_moves == int(levels[index].minimum_moves), "Current score persists after disk reload for %s" % levels[index].id)
		check(scene._is_unlocked(index + 1), "Current completion unlocks its successor")
		check(reloaded.archived_records.has("%s@99" % levels[index].id), "Old score remains separate after current completion")
		scene._close_modal(false)
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	var reopened = _scene(Progress.new(path + ".cfg"), path)
	root.add_child(reopened)
	reopened._choose_difficulty("hard")
	await process_frame
	check(reopened.find_child("JourneyMap", true, false).nodes[100][1].text == "★★★", "Hard stars remain visible after reopening app")
	reopened._choose_difficulty("medium")
	await process_frame
	check(reopened._is_unlocked(51) and reopened.find_child("JourneyMap", true, false).nodes[50][1].text == "★★★", "Medium score and sequential access remain after reopening")
	reopened.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(path + ".cfg")
	DirAccess.remove_absolute(path + ".prefs")
	print("PROGRESS/THEME: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _scene(progress: RefCounted, path: String) -> Control:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = progress
	scene.preferences = Preferences.new(path + ".prefs")
	scene.preferences.theme_mode = "light"
	scene.preferences.language_mode = "pt_BR"
	return scene

func _luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b

func _contrast(a: Color, b: Color) -> float:
	var first := _luminance(a)
	var second := _luminance(b)
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)
