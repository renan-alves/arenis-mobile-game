extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var path := OS.get_environment("TEMP").path_join("arenis-refinement-preview-%d" % Time.get_ticks_usec())
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.preferences = load("res://scripts/preferences.gd").new(path + ".cfg")
	scene.preferences.theme_mode = "light"
	scene.preferences.language_mode = "pt_BR"
	scene.progress = load("res://scripts/progress.gd").new(path + ".progress")
	root.add_child(scene)
	await _capture("home")
	var campaign: Array = scene.levels.duplicate(true)
	scene.level_pack_path = "res://data/prototype_levels.json"
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/prototype_levels.json")).levels[0]
	fixture.bottles = [{"colors": ["coral", "aqua"]}, {"colors": ["coral", "coral"]}, {"colors": []}, {"colors": ["aqua", "aqua"]}, {"colors": []}, {"colors": []}]
	scene.levels = [fixture]
	scene._start(0)
	scene._close_modal(false)
	await create_timer(0.35).timeout
	scene._on_bottle(0)
	await _capture("selection")
	scene._on_bottle(3)
	await _capture("vertical-pour", 0.65)
	await scene.transfer_finished
	await process_frame
	scene._undo()
	await _capture("vertical-undo", 0.65)
	await scene.transfer_finished
	await process_frame
	scene._show_level_menu()
	await _capture("menu")
	scene._show_lesson()
	await _capture("help-top")
	scene.overlay.find_children("*", "ScrollContainer", true, false)[0].scroll_vertical = 100000
	await _capture("help-bottom")
	scene._show_settings()
	await _capture("settings")
	scene._toggle_theme()
	await _capture("settings-dark")
	scene._close_modal(false)
	for difficulty in ["medium", "hard"]:
		var examples: Array = campaign.filter(func(level): return level.difficulty_id == difficulty)
		scene.levels = [examples[0]]
		scene._start(0)
		scene._close_modal(false)
		await _capture(difficulty + "-first")
		scene.levels = [examples[-1]]
		scene._start(0)
		scene._close_modal(false)
		await _capture(difficulty + "-last")
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(path + ".cfg")
	DirAccess.remove_absolute(path + ".progress")
	quit()
func _capture(name: String, wait := 0.36) -> void:
	var output := "res://docs/relatorios/imagens/refinamento/"
	DirAccess.make_dir_recursive_absolute(output)
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output + name + ".png") != OK:
		quit(1)
