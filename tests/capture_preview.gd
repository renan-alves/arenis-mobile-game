extends SceneTree
## Developer utility. Requires a rendering display; outputs PNGs to --output directory.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var output := OS.get_environment("TEMP").path_join("arenis-preview")
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--output":
		output = args[1]
	DirAccess.make_dir_recursive_absolute(output)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.level_pack_path = "res://data/prototype_levels.json"
	scene.preferences = load("res://scripts/preferences.gd").new(OS.get_environment("TEMP").path_join("arenis-capture-temp.cfg"))
	root.add_child(scene)
	await _capture(output.path_join("menu.png"))
	scene._start(0)
	scene._close_modal()
	await _capture(output.path_join("level.png"))
	scene._toggle_theme()
	await _capture(output.path_join("level-dark.png"))
	scene._toggle_theme()
	scene._start(3)
	scene._close_modal()
	await _capture(output.path_join("hidden.png"))
	scene._start(4)
	scene._close_modal()
	await _capture(output.path_join("locked.png"))
	scene.game.pour(1, 0)
	scene.game.pour(2, 1)
	scene.game.pour(3, 2)
	scene._refresh()
	scene._show_result()
	await _capture(output.path_join("result.png"))
	print("Previews: ", output)
	quit()

func _capture(path: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.36).timeout
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Could not capture " + path)
