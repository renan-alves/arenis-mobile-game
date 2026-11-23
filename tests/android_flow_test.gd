extends SceneTree
const Progress = preload("res://scripts/progress.gd")
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
	var path := OS.get_environment("TEMP").path_join("arenis-android-flow-%d" % Time.get_ticks_usec())
	var app = load("res://scenes/main.tscn").instantiate()
	app.progress = Progress.new(path + ".progress")
	app.preferences = Preferences.new(path + ".prefs")
	app.preferences.language_mode = "pt_BR"
	app.preferences.basic_tutorial_seen = true
	root.add_child(app)
	app._start(0)
	app._close_modal(false)
	await process_frame
	check(app.services.state.completions == 0, "Starting an attempt does not count as completion")
	var proof: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/relatorios/jornada-v3-provas.json")).results[0]
	for step in proof.solution:
		app.game.pour(step[0], step[1])
		app._save_attempt()
	check(app.game.won() and app.services.state.completions == 0, "Winning an introductory level saves its result without building ad cadence")
	app._show_result()
	app._show_result()
	app._save_attempt()
	check(app.services.state.completions == 0, "Reopening result preserves the introductory ad exemption")
	app._restart()
	check(app.services.state.completions == 0 and app.game.moves == 0, "Restart does not advance cadence")
	for step in proof.solution:
		app.game.pour(step[0], step[1])
		app._save_attempt()
	check(app.services.state.completions == 0, "Replaying an introductory level remains exempt from full-screen ads")
	check(not app.services.state.cloud_enabled and app.services.native == null, "Desktop fallback requires no Google account")
	var original_top: float = app.theme_button.offset_top
	app._apply_safe_top(1080, 48)
	await process_frame
	check(is_equal_approx(app.theme_button.offset_top, 40 + 48 * app.size.x / 1080), "System top inset moves persistent theme control")
	app._apply_safe_top(1080, 48)
	check(is_equal_approx(app.theme_button.offset_top, 40 + app.safe_top), "Repeated native insets do not accumulate")
	app._apply_safe_top(1080, 0)
	check(is_equal_approx(app.theme_button.offset_top, original_top), "Removing system inset restores original alignment")
	app._show_services()
	await process_frame
	check(app.overlay.find_children("*", "CheckButton", true, false).size() == 1, "Cloud preferences have a separate opt-in control")
	var listeners: int = app.services.state_changed.get_connections().size()
	app._close_modal(false)
	await process_frame
	check(app.services.state_changed.get_connections().size() < listeners, "Closing account settings releases status subscription")
	app._difficulty_menu()
	app._show_services()
	var account_modal = app.overlay
	var remote := {"schema_version": 2, "results": [{"id": "level-002", "version": 1, "rules_version": 3, "stars": 3, "best_moves": 6}]}
	app.progress.merge_cloud(JSON.stringify(remote), app.levels)
	app._on_cloud_progress()
	check(app.overlay == account_modal and is_instance_valid(account_modal), "Cloud restore preserves the account modal while it is in use")
	app._show_settings()
	await process_frame
	check(is_instance_valid(app.overlay), "Replacing account settings with settings does not trigger a delayed refresh over the new modal")
	app._close_modal(false)
	await process_frame
	check(app.find_child("Level2", true, false).disabled == false, "Closing settings refreshes the campaign map after cloud restoration")
	app._choose_difficulty("easy")
	app._show_services()
	remote.results[0].id = "level-003"
	app.progress.merge_cloud(JSON.stringify(remote), app.levels)
	app._on_cloud_progress()
	app._close_modal(false)
	await process_frame
	check(app.find_child("JourneyMap", true, false).nodes[2][1].text == "★★★", "Closing account settings refreshes stars on the visible level grid")
	check(not app.find_child("Level4", true, false).disabled, "Restored completion unlocks the next visible level immediately")
	app._start(3)
	app._close_modal(false)
	var active_board: Dictionary = app.game.snapshot()
	app._show_services()
	app._on_cloud_progress()
	app._close_modal(false)
	await process_frame
	check(app.screen == "game" and app.game.snapshot() == active_board, "Cloud refresh never rebuilds or resets an active game")
	app.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("ANDROID FLOW: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
