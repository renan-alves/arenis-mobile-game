extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var output := "res://docs/relatorios/imagens/fase-04a/"
	DirAccess.make_dir_recursive_absolute(output)
	var path := OS.get_environment("TEMP").path_join("arenis-campaign-preview-%d.cfg" % Time.get_ticks_usec())
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = load("res://scripts/progress.gd").new(path)
	root.add_child(scene)
	await _capture(output + "difficulties.png")
	scene._choose_difficulty("easy")
	await _capture(output + "grid.png")
	# Temporary completed predecessor makes the combination example accessible.
	scene.progress.complete(scene.levels[34], 3, int(scene.levels[34].minimum_moves))
	scene._start(35)
	scene._close_modal()
	await _capture(output + "combined.png")
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
		quit(1)
