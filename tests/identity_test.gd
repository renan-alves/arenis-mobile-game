extends SceneTree
const Mascot = preload("res://scripts/mascot.gd")
const Identity = preload("res://scripts/identity.gd")
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
	var mascot := Mascot.new()
	root.add_child(mascot)
	await process_frame
	mascot.set_process(false)
	check(mascot.body != null and mascot.body.resource_path.ends_with("body-light.svg"), "Approved light body loads")
	if mascot.body == null:
		quit(1)
		return
	mascot.look_at_point(Vector2(-10000, 10000))
	check(mascot.target_gaze == Vector2(-5.5, 5), "Gaze stays inside the shape")
	mascot._process(0.15)
	check(mascot.gaze.x < 0 and mascot.gaze.x > -5.5, "Gaze interpolates rather than snapping")
	mascot.blink()
	mascot._process(0.11)
	check(mascot.eyes_open <= 0.09, "Blink closes eyes")
	mascot._process(0.12)
	check(mascot.eyes_open == 1, "Blink reopens eyes")
	mascot.celebrate()
	check(mascot.activity == "win", "Victory response")
	mascot.rest()
	mascot.set_motion_enabled(false)
	mascot._process(20)
	check(mascot.gaze == Vector2.ZERO and mascot.eyes_open == 1, "Reduced motion disables idle drift and auto blinks")
	mascot.set_dark_mode(true)
	check(mascot.body.resource_path.ends_with("body-dark.svg"), "Dark body loads")
	check(Identity.make_theme().get_color("font_color", "Button") == Identity.colors().text, "Light button text contrast token")
	check(Identity.make_theme(true).get_color("font_color", "Label") == Identity.colors(true).text, "Dark label contrast token")
	mascot.queue_free()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.level_pack_path = "res://data/prototype_levels.json"
	scene.preferences = load("res://scripts/preferences.gd").new(OS.get_environment("TEMP").path_join("arenis-identity_test.gd-%d.cfg" % Time.get_ticks_usec()))
	scene.preferences.theme_mode = "light"
	scene.preferences.language_mode = "pt_BR"
	root.add_child(scene)
	scene._start(2)
	scene._close_modal()
	await process_frame
	var initial: Dictionary = scene.game.snapshot()
	scene._on_bottle(1)
	check(scene.mascot.activity == "selection" and scene.game.snapshot() == initial, "Selection animates mascot without changing board")
	scene._select_origin(2)
	check(scene.selected == 2 and scene.game.snapshot() == initial, "Switching origin is cosmetic")
	scene._select_origin(1)
	scene._on_bottle(0)
	check(scene.mascot.activity == "pour" and scene.busy, "Mascot tracks active stream")
	await scene.transfer_finished
	await process_frame
	check(scene.mascot.activity == "destination", "Gaze rests on destination after pour")
	var before_theme: Dictionary = scene.game.snapshot()
	var history_size: int = scene.game.history.size()
	scene._toggle_theme()
	await process_frame
	check(scene.dark_mode and scene.game.snapshot() == before_theme and scene.game.history.size() == history_size, "Theme toggle preserves board and undo history")
	check(scene.mascot.dark_mode and scene.bottle_views[0].dark_mode, "Theme reaches mascot and bottles")
	scene._undo()
	await scene.transfer_finished
	await process_frame
	check(scene.mascot.activity == "idle" and scene.game.moves == 2, "Undo returns mascot to idle and counts a move")
	check(scene.board.get_global_rect().end.y < scene.root.get_global_rect().end.y, "Board fits within portrait layout")
	var preferences_path: String = scene.preferences.path
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("IDENTITY: %d checks, %d failures" % [checks, failures])
	DirAccess.remove_absolute(preferences_path)
	quit(1 if failures else 0)
