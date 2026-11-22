extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var output := "res://docs/relatorios/imagens/revisao-niveis/"
	DirAccess.make_dir_recursive_absolute(output)
	var path := OS.get_environment("TEMP").path_join("arenis-layout-preview-%d.cfg" % Time.get_ticks_usec())
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.preferences = load("res://scripts/preferences.gd").new(path)
	scene.level_pack_path = "res://data/prototype_levels.json"
	root.add_child(scene)
	scene._start(0)
	scene._close_modal()
	await _capture(output + "level.png")
	scene._toggle_theme()
	await _capture(output + "level-dark.png")
	scene._show_settings()
	await _capture(output + "settings.png")
	var toggle = scene.overlay.find_children("*", "CheckButton", true, false)[0]
	toggle.button_pressed = true
	scene._close_modal()
	await _capture(output + "symbols-on.png")
	scene.preferences.set_symbols_enabled(false)
	scene._toggle_theme()
	scene._start(3)
	scene._close_modal()
	await _capture(output + "hidden.png")
	scene._start(4)
	scene._close_modal()
	await _capture(output + "locked.png")
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	quit()

func _capture(path: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.36).timeout
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(path) != OK:
		push_error("Não foi possível capturar " + path)
		quit(1)
