extends SceneTree
const Rules = preload("res://scripts/rules.gd")
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
	var sample := {"capacity": 3, "minimum_moves": 4, "bottles": [{"colors": ["coral", "aqua", "aqua"]}, {"colors": ["aqua", "aqua"]}, {"colors": []}]}
	var rules := Rules.new(sample)
	check(rules.transfer_count(0, 2) == 2, "Multi-portion block fits in empty tube")
	check(rules.transfer_count(0, 1) == 1, "Partial block fills exactly remaining space")
	rules.pour(0, 1)
	check(rules.bottles[1].size() == 3 and rules.bottles[0].size() == 2, "Partial transfer leaves remainder in source")
	var file := OS.get_environment("TEMP").path_join("arenis-polish-%d.cfg" % Time.get_ticks_usec())
	var prefs := Preferences.new(file)
	prefs.theme_mode = "light"
	prefs.language_mode = "pt_BR"
	check(prefs.effects_enabled and prefs.effects_volume == 0.3, "Audio defaults")
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.level_pack_path = "res://data/prototype_levels.json"
	scene.preferences = prefs
	root.add_child(scene)
	scene._start(1)
	scene._close_modal(false)
	await process_frame
	var initial: Dictionary = scene.game.snapshot()
	scene._on_bottle(0)
	scene._on_bottle(2)
	check(scene.busy and scene.bottle_views[2].fill_units == 0, "Destination starts empty visually")
	await create_timer(0.75).timeout
	check(scene.bottle_views[2].fill_units > 0 and scene.bottle_views[2].fill_units < 2, "Destination fills progressively")
	check(scene.bottle_views[0].fill_units > 1 and scene.bottle_views[0].fill_units < 3, "Source empties progressively")
	check(scene.audio.sand.playing, "Sand sound plays during pour")
	await scene.transfer_finished
	await process_frame
	scene._undo()
	check(scene.busy and scene.stream.visible, "Undo animates a reversed stream")
	await scene.transfer_finished
	await process_frame
	check(scene.game.bottles == initial.bottles and scene.game.locks == initial.locks and scene.game.moves == 2, "Animated undo restores board and adds one move")
	var target = scene.bottle_views[1]
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	target._gui_input(press)
	await create_timer(0.45).timeout
	check(scene.selected == 1 and scene.game.moves == 2 and not scene.busy, "Holding another tube selects it without pouring")
	press.pressed = false
	target._gui_input(press)
	check(scene.selected == 1 and scene.game.moves == 2, "Long press release does not trigger an extra pour or deselect")
	var reported: Dictionary = scene.levels[0].duplicate(true)
	reported.bottles = [{"colors": ["coral", "coral"]}, {"colors": ["aqua"]}, {"colors": ["coral", "aqua", "aqua"]}]
	scene.levels.append(reported)
	scene._start(scene.levels.size() - 1)
	scene._close_modal(false)
	await process_frame
	scene._on_bottle(0)
	check(not scene.bottle_views[1].valid_target and scene.bottle_views[0].selected, "Only the origin is selected; destinations are not highlighted")
	scene._on_bottle(1)
	check(not scene.busy and scene.game.moves == 0 and scene.selected == 1, "Different-color target becomes the new source without pouring")
	check(scene.game.bottles[0].size() == 2 and scene.game.bottles[1].size() == 1, "Invalid pour preserves both tubes")
	scene._start(3)
	scene._close_modal(false)
	await process_frame
	var concealed: String = scene.game.bottles[0][3].id
	scene._on_bottle(0)
	scene._on_bottle(2)
	check(scene.game.known.has(concealed) and not scene.bottle_views[0].known.has(concealed), "Animation does not reveal a still-covered layer early")
	await scene.transfer_finished
	await process_frame
	check(scene.bottle_views[0].known.has(concealed), "Exposed color appears when visual transfer completes")
	scene._start(2)
	scene._close_modal(false)
	await process_frame
	scene._on_bottle(1)
	scene._on_bottle(0)
	await scene.transfer_finished
	await process_frame
	scene._on_bottle(1)
	scene._on_bottle(2)
	check(scene.game.won() and scene.busy and not is_instance_valid(scene.overlay), "Last move does not open result immediately")
	await create_timer(0.3).timeout
	check(not is_instance_valid(scene.overlay), "Result waits for filling and settling")
	await scene.transfer_finished
	await process_frame
	check(is_instance_valid(scene.overlay), "Result opens after animation finishes")
	check(scene.theme_button.is_visible_in_tree(), "Global theme toggle is visible over result")
	check(scene.theme_button.get_global_rect().position.x >= 0 and scene.theme_button.get_global_rect().end.x <= scene.size.x, "Theme control is inside the viewport")
	var result_menu: Control = scene.overlay
	var before: Dictionary = scene.game.snapshot()
	scene._toggle_theme()
	check(scene.overlay == result_menu and scene.game.snapshot() == before and scene.dark_mode, "Theme change preserves menu and puzzle")
	check(Preferences.new(file).theme_mode == "dark", "Theme override persists")
	check(is_instance_valid(scene.theme_cover), "Theme crossfade exists")
	scene._close_modal(false)
	scene._show_settings()
	check(scene.theme_button.is_visible_in_tree(), "Theme toggle is visible in settings")
	check(scene.theme_button.get_theme_color("icon_normal_color") == scene.colors.text, "Global controls receive current theme across canvas layers")
	var toggles = scene.overlay.find_children("*", "CheckButton", true, false)
	check(toggles.size() == 2 and toggles[0].get_theme_icon("checked").get_width() >= 56, "Large accessibility and audio toggles")
	check(toggles[0].get_theme_constant("icon_max_width") >= 56, "Toggle graphic is not constrained by action icon size")
	check(scene.overlay.find_children("*", "HSlider", true, false).size() == 1, "Effects volume slider without music control")
	prefs.set_audio("effects_enabled", false)
	prefs.set_audio("effects_volume", 0.2)
	scene.audio.apply_preferences()
	check(not scene.audio.sand.playing, "Audio switches affect playback")
	var reloaded := Preferences.new(file)
	check(not reloaded.effects_enabled and reloaded.effects_volume == 0.2, "Audio settings persist")
	var actions: Array = scene.overlay.find_children("*", "Button", true, false).filter(func(b): return not b is CheckButton)
	check(actions.all(func(b): return b.alignment == HORIZONTAL_ALIGNMENT_CENTER and b.icon == null), "Menu text stays centered independently of icon")
	scene._close_modal(false)
	scene._show_lesson()
	var labels = scene.overlay.find_children("*", "Label", true, false)
	check(labels.any(func(l): return l.text.length() > 500), "Help explains rules and interactions")
	check(scene.overlay.find_children("*", "Button", true, false).any(func(b): return b.text == "Entendi"), "Help has a clear closing action")
	await process_frame
	check(scene.banner.size.x == scene.size.x and is_equal_approx(scene.banner.size.y, 75), "Narrow full-width banner area")
	scene._close_modal(false)
	var campaign: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
	var dense: Array = campaign.levels.filter(func(l): return l.bottles.size() == 6)
	scene.levels.append(dense[0])
	scene._start(scene.levels.size() - 1)
	scene._close_modal(false)
	await process_frame
	await process_frame
	check(scene.board.get_global_rect().end.y <= scene.banner.get_global_rect().position.y, "Two rows of tubes stay above the banner")
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(file)
	print("POLISH: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
