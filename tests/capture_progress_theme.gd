extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var path := OS.get_environment("TEMP").path_join("arenis-progress-theme-preview-%d" % Time.get_ticks_usec())
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.preferences = load("res://scripts/preferences.gd").new(path + ".prefs")
	scene.preferences.theme_mode = "light"
	scene.preferences.language_mode = "pt_BR"
	scene.progress = load("res://scripts/progress.gd").new(path + ".progress")
	scene.progress.records = {
		"medium-001": {"version": 1, "stars": 2, "best_moves": 5},
		"hard-001": {"version": 1, "stars": 3, "best_moves": 3},
		"hard-008": {"version": 2, "stars": 3, "best_moves": 22}}
	root.add_child(scene)
	scene._show_settings()
	await create_timer(0.35).timeout
	var toggle: CheckButton = scene.overlay.find_children("*", "CheckButton", true, false)[0]
	toggle.set_pressed_no_signal(true)
	_hover(toggle)
	await _capture("toggle-light-hover")
	print("LIGHT HOVER MODE: ", toggle.get_draw_mode(), " COLOR: ", toggle.get_theme_color("font_hover_pressed_color"))
	scene._toggle_theme()
	await _capture("toggle-dark-hover")
	print("DARK HOVER MODE: ", toggle.get_draw_mode(), " COLOR: ", toggle.get_theme_color("font_hover_pressed_color"))
	scene._close_modal(false)
	scene._toggle_theme()
	scene._choose_difficulty("medium")
	await _capture("medium-grid")
	scene._choose_difficulty("hard")
	await _capture("hard-grid")
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(path + ".prefs")
	DirAccess.remove_absolute(path + ".progress")
	quit()
func _hover(control: Control) -> void:
	var event := InputEventMouseMotion.new()
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	Input.parse_input_event(event)
func _capture(name: String) -> void:
	var output := "res://docs/relatorios/imagens/progresso-tema/"
	DirAccess.make_dir_recursive_absolute(output)
	await create_timer(0.36).timeout
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output + name + ".png") != OK:
		quit(1)
