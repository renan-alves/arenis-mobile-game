extends SceneTree
const Identity = preload("res://scripts/identity.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
const Preferences = preload("res://scripts/preferences.gd")
const Progress = preload("res://scripts/progress.gd")
var checks := 0
var failures := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	check(Identity.sand_palette().size() == Catalog.COLORS.size() and Identity.sand_palette(true).size() == Catalog.COLORS.size(), "Both palettes cover the full game catalog")
	for id in Catalog.COLORS:
		var light := Identity.sand_color(id)
		var dark := Identity.sand_color(id, true)
		check(_luminance(dark) < _luminance(light) * 0.7, "Dark sand is visibly less luminous: " + id)
		check(_contrast(dark, Identity.colors(true).background) >= 3, "Dark sand remains distinct from board: " + id)
		check(_contrast(dark, Identity.sand_symbol_color(true)) >= 4.5 and _contrast(light, Identity.sand_symbol_color()) >= 4.5, "Color symbols remain readable in both palettes: " + id)
	var path := OS.get_environment("TEMP").path_join("arenis-palette-%d" % Time.get_ticks_usec())
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.preferences = Preferences.new(path + ".prefs")
	scene.preferences.theme_mode = "light"
	scene.preferences.language_mode = "pt_BR"
	scene.preferences.symbols_enabled = true
	scene.progress = Progress.new(path + ".progress")
	scene.level_pack_path = "res://data/prototype_levels.json"
	root.add_child(scene)
	scene._start(1)
	scene._close_modal(false)
	await process_frame
	scene._on_bottle(0)
	scene._on_bottle(2)
	await create_timer(0.45).timeout
	var id: String = scene.stream.color_id
	check(scene.stream.color == Identity.sand_color(id), "Pour starts with the light sand color")
	var state: Dictionary = scene.game.snapshot()
	scene._toggle_theme()
	check(scene.stream.color == Identity.sand_color(id, true), "Active stream changes to dark palette with the tubes")
	check(scene.game.snapshot() == state and scene.bottle_views.all(func(view): return view.dark_mode and view.symbols_enabled), "Theme change preserves board and symbol option")
	await scene.transfer_finished
	await process_frame
	scene._undo()
	check(scene.stream.color == Identity.sand_color(scene.stream.color_id, true), "Undo uses the current dark palette")
	scene._toggle_theme()
	check(scene.stream.color == Identity.sand_color(scene.stream.color_id), "Undo stream also updates when returning to light")
	await scene.transfer_finished
	await process_frame
	check(scene.game.moves == 2, "Palette changes preserve undo move cost")
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(path + ".prefs")
	DirAccess.remove_absolute(path + ".progress")
	print("PALETTE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func _luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return linear.r * 0.2126 + linear.g * 0.7152 + linear.b * 0.0722
func _contrast(a: Color, b: Color) -> float:
	var first := _luminance(a)
	var second := _luminance(b)
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)
