extends "res://tests/capture_refinement.gd"

func _capture(name: String, wait := 0.36) -> void:
	var output := "res://docs/relatorios/imagens/espacamento/"
	DirAccess.make_dir_recursive_absolute(output)
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output + name + ".png") != OK:
		quit(1)
