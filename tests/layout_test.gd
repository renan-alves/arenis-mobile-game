extends SceneTree
const Preferences = preload("res://scripts/preferences.gd")
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
	var path := OS.get_environment("TEMP").path_join("arenis-symbols-%d.cfg" % Time.get_ticks_usec())
	var settings := Preferences.new(path)
	settings.language_mode = "pt_BR"
	check(not settings.symbols_enabled, "Symbols default off")
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.preferences = settings
	scene.level_pack_path = "res://data/prototype_levels.json"
	root.add_child(scene)
	scene._start(3)
	scene._close_modal()
	await process_frame
	check(scene.status.text.is_empty(), "No persistent helper paragraph")
	var logos: Array = scene.find_children("*", "TextureRect", true, false).filter(func(node): return node.texture != null and "branding/logo" in node.texture.resource_path)
	check(logos.is_empty(), "App logo is absent inside levels")
	var controls: Array = []
	for node in scene.toolbar.get_children():
		if node is Button:
			controls.append(node)
	check(controls.size() == 3, "Only level menu, undo and help in level toolbar")
	for button in controls:
		check(button.text.is_empty() and button.icon != null and not button.accessibility_name.is_empty(), "Icon-only control remains labelled for accessibility")
		check(button.get_global_rect().end.y <= scene.move_label.get_global_rect().position.y, "Controls sit above level information")
	var snapshot: Dictionary = scene.game.snapshot()
	scene._confirm_restart()
	check(is_instance_valid(scene.overlay) and scene.game.snapshot() == snapshot, "Restart requires confirmation")
	scene._close_modal()
	scene.toolbar.get_node("Como jogar").pressed.emit()
	check(is_instance_valid(scene.overlay) and scene.game.snapshot() == snapshot, "Help does not mutate progress")
	scene._close_modal()
	var tube: Control = scene.bottle_views[0]
	var hidden: Dictionary = scene.game.bottles[0][0]
	var visible: Dictionary = scene.game.bottles[0].back()
	check(tube._symbol_for(visible).is_empty(), "Color symbols are absent by default")
	scene._show_settings()
	var toggles = scene.overlay.find_children("*", "CheckButton", true, false)
	check(toggles.size() == 2 and not toggles[0].button_pressed, "Accessibility setting is exposed")
	toggles[0].button_pressed = true
	check(settings.symbols_enabled and Preferences.new(path).symbols_enabled, "Preference persists and reloads")
	check(not tube._symbol_for(visible).is_empty(), "Toggle displays symbols immediately")
	check(tube._symbol_for(hidden).is_empty(), "Accessibility never reveals hidden sand")
	check(scene.game.snapshot() == snapshot, "Accessibility toggle preserves puzzle state")
	toggles[0].button_pressed = false
	check(not Preferences.new(path).symbols_enabled and tube._symbol_for(visible).is_empty(), "Preference can be disabled and persisted")
	scene._close_modal()
	scene._on_bottle(0)
	check(scene.status.text.is_empty(), "Selection uses highlighting instead of helper text")
	scene._on_bottle(1)
	check(scene.selected == 1 and scene.status.text.is_empty(), "Switching source needs no deselection")
	scene._notify("Destino indisponível.")
	scene._process(3)
	check(scene.status.text.is_empty(), "Feedback expires")
	check(controls[0].accessibility_name == "Menu da fase" and controls[0].icon.resource_path.ends_with("more.svg"), "Ellipsis opens the level menu")
	controls[0].pressed.emit()
	check(is_instance_valid(scene.overlay), "Level menu remains reachable")
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(path)
	print("LAYOUT/SETTINGS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
