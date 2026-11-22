extends SceneTree

var failures := 0
var checks := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.level_pack_path = "res://data/prototype_levels.json"
	scene.preferences = load("res://scripts/preferences.gd").new(OS.get_environment("TEMP").path_join("arenis-ui_test.gd-%d.cfg" % Time.get_ticks_usec()))
	scene.preferences.theme_mode = "light"
	scene.preferences.language_mode = "pt_BR"
	root.add_child(scene)
	await process_frame
	check(scene.screen == "levels", "Level list opens")
	scene._start(2)
	await process_frame
	check(is_instance_valid(scene.overlay), "Skippable lesson opens")
	scene._close_modal()
	scene._on_bottle(1)
	check(scene.selected == 1, "Tap source selects")
	scene._select_origin(2)
	check(scene.selected == 2 and scene.game.moves == 0, "Explicit origin switch does not pour")
	scene._select_origin(1)
	scene._on_bottle(0)
	check(scene.busy, "Animation blocks interactions")
	scene._confirm_restart()
	check(not is_instance_valid(scene.overlay), "Cannot restart during animation")
	await scene.transfer_finished
	await process_frame
	check(not scene.busy and scene.game.moves == 1, "Transfer animation completes")
	scene._undo()
	await scene.transfer_finished
	await process_frame
	check(scene.game.moves == 2, "Undo via UI costs a move")
	scene._on_bottle(1)
	scene._on_bottle(0)
	await scene.transfer_finished
	await process_frame
	scene._on_bottle(1)
	scene._on_bottle(2)
	await scene.transfer_finished
	await process_frame
	check(scene.game.won() and is_instance_valid(scene.overlay), "Victory modal")
	scene._restart()
	check(scene.game.moves == 0 and not scene.game.won(), "Replay resets state")
	scene._back()
	check(is_instance_valid(scene.overlay), "Android back / Escape opens level menu")
	scene._back()
	check(not is_instance_valid(scene.overlay), "Back dismisses level menu")
	scene._show_levels()
	await process_frame
	check(scene.screen == "levels", "Return to demo list")
	print("UI: ", checks, " checks, ", failures, " failures")
	var preferences_path: String = scene.preferences.path
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(preferences_path)
	quit(1 if failures else 0)
