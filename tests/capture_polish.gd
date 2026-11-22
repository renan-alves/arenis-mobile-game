extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var path := OS.get_environment("TEMP").path_join("arenis-polish-preview-%d.cfg" % Time.get_ticks_usec())
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.preferences = load("res://scripts/preferences.gd").new(path)
	scene.preferences.theme_mode = "light"
	scene.preferences.language_mode = "pt_BR"
	scene.progress = load("res://scripts/progress.gd").new(path + ".progress")
	root.add_child(scene)
	await _capture("home")
	scene._choose_difficulty("easy")
	await _capture("grid")
	scene.level_pack_path = "res://data/prototype_levels.json"
	scene.levels = JSON.parse_string(FileAccess.get_file_as_string(scene.level_pack_path)).levels
	scene._start(1)
	scene._close_modal(false)
	await _capture("level")
	scene._on_bottle(0)
	scene._on_bottle(2)
	await _capture("filling", 0.48)
	await scene.transfer_finished
	await process_frame
	scene._show_settings()
	await _capture("settings")
	scene._toggle_theme()
	await _capture("settings-dark")
	scene._close_modal(false)
	scene._show_lesson()
	await _capture("help")
	scene._close_modal(false)
	var campaign: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
	var dense: Array = campaign.levels.filter(func(l): return l.bottles.size() == 6)
	scene.levels.append(dense[0])
	scene._start(scene.levels.size() - 1)
	scene._close_modal(false)
	await _capture("six-tubes")
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(path)
	quit()
func _capture(name: String, wait := 0.36) -> void:
	var output := "res://docs/relatorios/imagens/polimento/"
	DirAccess.make_dir_recursive_absolute(output)
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output + name + ".png") != OK:
		quit(1)
