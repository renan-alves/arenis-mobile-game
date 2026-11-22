extends SceneTree
const Identity = preload("res://scripts/identity.gd")
const Bottle = preload("res://scripts/bottle.gd")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var path := OS.get_environment("TEMP").path_join("arenis-dark-palette-preview-%d" % Time.get_ticks_usec())
	var app = load("res://scenes/main.tscn").instantiate()
	app.preferences = load("res://scripts/preferences.gd").new(path + ".prefs")
	app.preferences.theme_mode = "light"
	app.preferences.language_mode = "pt_BR"
	app.progress = load("res://scripts/progress.gd").new(path + ".progress")
	app.progress.records["hard-001"] = {"version": 1, "stars": 3, "best_moves": 3}
	root.add_child(app)
	app._choose_difficulty("hard")
	await _capture("grade-sem-historico")
	var level: Dictionary = app.levels[-1]
	app.level_pack_path = "res://data/prototype_levels.json"
	app.levels = [level]
	app._start(0)
	app._close_modal(false)
	await _capture("claro")
	app._toggle_theme()
	await _capture("escuro")
	for view in app.bottle_views:
		view.symbols_enabled = true
		view.queue_redraw()
	await _capture("escuro-simbolos")
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	var comparison := Control.new()
	comparison.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(comparison)
	var names := ["Coral", "Turquesa", "Dourado", "Lavanda", "Azul", "Sálvia", "Rosa", "Pêssego", "Índigo", "Menta"]
	for dark in [false, true]:
		var panel := PanelContainer.new()
		panel.position = Vector2(0, 480 if dark else 0)
		panel.size = Vector2(540, 480)
		panel.theme = Identity.make_theme(dark)
		var style := StyleBoxFlat.new()
		style.bg_color = Identity.colors(dark).background
		panel.add_theme_stylebox_override("panel", style)
		comparison.add_child(panel)
		var margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 24)
		panel.add_child(margin)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 12)
		margin.add_child(content)
		var heading := Label.new()
		heading.text = "Escuro · tons profundos" if dark else "Claro · tons pastéis"
		heading.add_theme_font_size_override("font_size", 24)
		content.add_child(heading)
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 12)
		content.add_child(grid)
		var index := 0
		for id in Identity.SAND:
			var cell := VBoxContainer.new()
			cell.add_theme_constant_override("separation", 0)
			grid.add_child(cell)
			var bottle := Bottle.new()
			bottle.tube_height = 116
			bottle.dark_mode = dark
			bottle.interactive = false
			for unit in 3:
				var token := {"id": str(unit), "color": id}
				bottle.units.append(token)
				bottle.known[token.id] = true
			cell.add_child(bottle)
			var label := Label.new()
			label.text = names[index]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 13)
			cell.add_child(label)
			index += 1
	await _capture("comparacao-paletas")
	comparison.queue_free()
	await process_frame
	DirAccess.remove_absolute(path + ".prefs")
	DirAccess.remove_absolute(path + ".progress")
	quit()
func _capture(name: String) -> void:
	var output := "res://docs/relatorios/imagens/paleta-escura/"
	DirAccess.make_dir_recursive_absolute(output)
	await create_timer(0.36).timeout
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output + name + ".png") != OK:
		quit(1)
