extends SceneTree
const Preferences = preload("res://scripts/preferences.gd")
const Progress = preload("res://scripts/progress.gd")
const Practice = preload("res://scripts/basic_tutorial.gd")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var path := OS.get_environment("TEMP").path_join("arenis-phase4-preview-%d" % Time.get_ticks_usec())
	var app = _app(path)
	root.add_child(app)
	await _capture("pt-inicio")
	app._start(0)
	await _capture("pt-tutorial")
	var practice = app.overlay.find_children("*", "VBoxContainer", true, false).filter(func(node): return node.get_script() == Practice)[0]
	practice._tap(0)
	practice._tap(1)
	await create_timer(0.8).timeout
	practice._tap(0)
	practice._tap(2)
	await create_timer(0.8).timeout
	await _capture("pt-tutorial-concluido")
	app._finish_basic_tutorial(true)
	var proof: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/relatorios/revisao-desafio-provas.json")).results[0]
	var move: Array = proof.solution[0]
	app._on_bottle(move[0])
	app._on_bottle(move[1])
	await app.transfer_finished
	await process_frame
	var before: Dictionary = app.game.snapshot()
	app._leave_level()
	app._difficulty_menu()
	await _capture("pt-continuar")
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	app = _app(path)
	root.add_child(app)
	app._start(app.progress.latest_attempt(app.levels))
	await _capture("pt-retomada")
	print("RESTORED SAME BOARD: ", before == app.game.snapshot())
	app._show_settings()
	app._change_language(2)
	await _capture("en-configuracoes")
	app._close_modal(false)
	await _capture("en-nivel")
	app._show_lesson()
	await _capture("en-ajuda")
	app._show_basic_tutorial(false)
	await _capture("en-tutorial")
	app._close_modal(false)
	app._show_settings()
	app._change_language(3)
	await _capture("es-configuracoes")
	app._close_modal(false)
	app._show_lesson()
	await _capture("es-ajuda")
	app._show_basic_tutorial(false)
	await _capture("es-tutorial")
	app._close_modal(false)
	app._leave_level()
	app._difficulty_menu()
	await _capture("es-continuar")
	app.progress.records[app.levels[9].id] = {"version": int(app.levels[9].version), "stars": 1, "best_moves": 100}
	app._start(10, true)
	app._toggle_theme()
	await _capture("es-obstaculo-escuro", 1.75)
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	for suffix in [".prefs", ".prefs.bak", ".progress", ".progress.bak"]:
		DirAccess.remove_absolute(path + suffix)
	quit()
func _app(path: String) -> Control:
	var app = load("res://scenes/main.tscn").instantiate()
	app.preferences = Preferences.new(path + ".prefs")
	app.preferences.language_mode = "pt_BR"
	app.preferences.theme_mode = "light"
	app.progress = Progress.new(path + ".progress")
	return app
func _capture(name: String, wait := 0.38) -> void:
	var output := "res://docs/relatorios/imagens/fase-04b/"
	DirAccess.make_dir_recursive_absolute(output)
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output + name + ".png") != OK:
		quit(1)
