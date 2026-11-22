extends SceneTree
var viewport: SubViewport
var app: Control
var output := "res://docs/relatorios/imagens/jornada-0.6"
func _initialize() -> void:
	root.hide()
	_run.call_deferred()
func capture(name: String) -> void:
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(output.path_join(name+".png"))
	if error != OK: push_error("Capture failed: "+name)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	viewport=SubViewport.new();viewport.size=Vector2i(540,960);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	app=load("res://scenes/main.tscn").instantiate()
	var path := OS.get_environment("TEMP").path_join("arenis-capture-journey-%d" % Time.get_ticks_usec())
	app.progress=load("res://scripts/progress.gd").new(path+".progress")
	app.preferences=load("res://scripts/preferences.gd").new(path+".prefs")
	app.preferences.theme_mode="light";app.preferences.language_mode="pt_BR";app.preferences.basic_tutorial_seen=true
	viewport.add_child(app)
	await capture("map-light")
	app._toggle_theme();await capture("map-dark");app._toggle_theme()
	for index in [0,30,47,75,140]:
		if index>0: app.progress.records[app.levels[index-1].id]={"version":1,"stars":1,"best_moves":50}
		app._start(index,true);app._close_modal(false)
		await capture("level-%d-light" % (index+1))
		app._toggle_theme();await capture("level-%d-dark" % (index+1));app._toggle_theme()
	app._show_settings();await capture("settings-light")
	app._toggle_theme();await capture("settings-dark");app._toggle_theme()
	app._show_services();await capture("account")
	app._show_lesson();await capture("help")
	app._show_basic_tutorial(false);await capture("practice")
	for kind in ["moves","timed","hidden","locked","combined"]:
		app._show_mechanic_intro(kind);await capture(kind+"-intro")
	app._close_modal(false)
	app.game.failed_reason="moves";app.failure_shown=false;app._show_failure();await capture("failure")
	app._close_modal(false);app._start(0,true);app._close_modal(false)
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/relatorios/jornada-v3-provas.json"))
	for step in proof.results[0].solution: app.game.pour(step[0],step[1])
	app._refresh();app._show_result();await capture("result")
	app._close_modal(false);app._restart();app._show_level_menu();await capture("level-menu")
	app._confirm_restart();await capture("restart")
	print("Journey rendering captured: "+output)
	app.queue_free();await process_frame;await create_timer(.2).timeout;quit()
