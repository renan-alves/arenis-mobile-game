extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var path := OS.get_environment("TEMP").path_join("arenis-mechanic-preview-%d" % Time.get_ticks_usec())
	var app = load("res://scenes/main.tscn").instantiate()
	app.preferences = load("res://scripts/preferences.gd").new(path + ".prefs")
	app.preferences.theme_mode = "light"
	app.preferences.language_mode = "pt_BR"
	app.preferences.basic_tutorial_seen = true
	app.progress = load("res://scripts/progress.gd").new(path + ".progress")
	root.add_child(app)
	for entry in [[10, "escondida"], [20, "trancas"], [35, "combinados"]]:
		var index: int = entry[0]
		app.progress.records[app.levels[index - 1].id] = {"version": int(app.levels[index - 1].version), "stars": 1, "best_moves": 100}
		app._start(index, true)
		await _capture(entry[1] + "-antes", 0.35)
		await _capture(entry[1] + "-depois", 1.4)
		if index == 35:
			app._toggle_theme()
			await _capture("combinados-escuro", 0.36)
		app._close_modal(false)
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(path + ".prefs")
	DirAccess.remove_absolute(path + ".progress")
	quit()
func _capture(name: String, wait: float) -> void:
	var output := "res://docs/relatorios/imagens/obstaculos/"
	DirAccess.make_dir_recursive_absolute(output)
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output + name + ".png") != OK:
		quit(1)
