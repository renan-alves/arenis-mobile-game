extends SceneTree
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
	var path := OS.get_environment("TEMP").path_join("arenis-refinement-%d" % Time.get_ticks_usec())
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.preferences = Preferences.new(path + ".cfg")
	scene.preferences.theme_mode = "light"
	scene.preferences.language_mode = "pt_BR"
	scene.progress = Progress.new(path + ".progress")
	root.add_child(scene)
	await process_frame
	await process_frame
	var settings = scene.root.find_children("Configurações", "Button", true, false)[0]
	check(is_equal_approx(settings.get_global_rect().get_center().y, scene.theme_button.get_global_rect().get_center().y), "Theme aligns with home header controls")
	var campaign: Array = scene.levels.duplicate(true)
	for count in [7, 8, 9, 10, 11]:
		var candidates: Array = campaign.filter(func(level): return level.bottles.size() == count)
		check(not candidates.is_empty(), "Campaign includes intended tube count: %d" % count)
		if candidates.is_empty():
			continue
		scene.level_pack_path = "res://data/prototype_levels.json"
		scene.levels = [candidates[0]]
		scene._start(0)
		scene._close_modal(false)
		await process_frame
		await process_frame
		check(scene.board.get_global_rect().end.y < scene.banner.get_global_rect().position.y and scene.board.get_global_rect().end.x <= scene.size.x, "Dense board fits above banner: %d" % count)
		check(scene.bottle_views.all(func(view): return view.tube_height >= 100 and view.size.x >= 88), "Dense tubes retain touch area and readable height")
		if count >= 10:
			check(scene.bottle_views[0].tube_height >= 170, "Three rows use the available height for taller tubes")
			var first = scene.bottle_views[0]
			var next_row = scene.bottle_views[4]
			var body_gap: float = next_row.mouth_position().y - (first.mouth_position().y + first.tube_height)
			check(body_gap <= 44.5, "Three rows do not reserve oversized empty cell margins")
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/prototype_levels.json")).levels[0]
	fixture.bottles = [{"colors": ["coral", "aqua"]}, {"colors": ["coral", "coral"]}, {"colors": []}, {"colors": ["aqua", "aqua"]}, {"colors": []}, {"colors": []}]
	scene.levels = [fixture]
	scene._start(0)
	scene._close_modal(false)
	await process_frame
	await process_frame
	var buttons: Array = scene.toolbar.find_children("*", "Button", true, false)
	check(buttons.size() == 3 and buttons.all(func(button): return button.name != "Reiniciar"), "Restart is absent from gameplay toolbar")
	check(buttons.all(func(button): return is_equal_approx(button.get_global_rect().get_center().y, scene.theme_button.get_global_rect().get_center().y)), "Theme and all gameplay icons share a baseline")
	scene._show_level_menu()
	var restart: Array = scene.overlay.find_children("*", "Button", true, false).filter(func(button): return button.text == "Reiniciar")
	check(restart.size() == 1, "Restart is available in level menu")
	restart[0].pressed.emit()
	check(scene.overlay.find_children("*", "Label", true, false).any(func(label): return label.text == "Reiniciar esta fase?"), "Restart still asks confirmation")
	scene._close_modal(false)
	scene._on_bottle(0)
	await create_timer(0.2).timeout
	check(scene.bottle_views[0].selected and scene.bottle_views[0].selection_strength > 0.95, "Selected origin rises gently and shows its marker")
	check(scene.status.get_parent() == scene and not scene.root.is_ancestor_of(scene.status), "Empty notifications reserve no board height")
	check(scene.bottle_views.slice(1).all(func(view): return not view.valid_target and not view.selected and view.selection_strength == 0), "Other tubes retain their original appearance")
	check(absf(scene.bottle_views[0].mouth_position().x - scene.bottle_views[3].mouth_position().x) < 1, "Regression fixture aligns source above target")
	scene._on_bottle(3)
	await create_timer(0.5).timeout
	check(scene.stream.source.y < scene.stream.target.y and absf(scene.stream.source.x - scene.stream.target.x) > 30, "Vertical transfer becomes a visible downward pour beside target")
	check(absf(scene.bottle_views[0].pour_angle) > 0.25 and scene.bottle_views[0].z_index > 0, "Source tube visibly tilts above the board")
	await scene.transfer_finished
	await process_frame
	check(scene.bottle_views[0].pour_offset == Vector2.ZERO and scene.bottle_views[0].pour_angle == 0, "Tube returns to grid after pour")
	scene._undo()
	await create_timer(0.5).timeout
	check(scene.stream.source.y < scene.stream.target.y, "Reverse vertical transfer also pours downward")
	await scene.transfer_finished
	await process_frame
	check(scene.game.moves == 2 and scene.game.bottles[0].size() == 2, "Animated undo restores board and retains its move cost")
	scene._show_lesson()
	await process_frame
	await process_frame
	var understood = scene.overlay.find_children("*", "Button", true, false).filter(func(button): return button.text == "Entendi")[0]
	var help_scroll = scene.overlay.find_children("*", "ScrollContainer", true, false)[0]
	check(not help_scroll.is_ancestor_of(understood) and understood.is_visible_in_tree(), "Help closing action is outside scrolling text")
	check(understood.get_global_rect().end.y < scene.banner.get_global_rect().position.y, "Help closing action remains above banner")
	help_scroll.scroll_vertical = 100000
	await process_frame
	check(understood.get_global_rect().position.y >= 0 and understood.get_global_rect().end.y < scene.banner.get_global_rect().position.y, "Help closing action stays visible at end of text")
	scene._close_modal(false)
	scene._show_settings()
	check(scene.overlay.find_children("*", "CheckButton", true, false).size() == 2 and scene.overlay.find_children("*", "HSlider", true, false).size() == 1, "Settings contain accessibility and effects only")
	check(scene.audio.get_child_count() == 3, "Only sand, tap and completion audio players exist")
	scene._close_modal(false)
	scene.apply_banner_measurement(1080, 100)
	await process_frame
	check(is_equal_approx(scene.banner.size.y, scene.size.x * 100.0 / 1080.0), "Native pixel height converts to Godot layout units")
	scene.apply_banner_measurement(1080, 150)
	scene.level_pack_path = "res://data/campaign.json"
	scene.levels = campaign
	scene.progress.records[campaign[50].id] = {"version": 99, "stars": 3, "best_moves": 5}
	check(scene.progress.record(campaign[50]).is_empty(), "Revised board does not inherit old stars or move record")
	check(not scene._is_unlocked(51), "Previous board revision does not unlock the next current level")
	check(scene.progress.complete(campaign[50], 1, 30) == OK and scene.progress.record(campaign[50]).stars == 1, "New board earns its own score independently of old three-star result")
	check(scene.progress.archived_records["level-051@99"].stars == 3 and scene.progress.archived_records["level-051@99"].best_moves == 5, "Prior board score is archived rather than discarded")
	var reloaded := Progress.new(path + ".progress")
	check(reloaded.archived_records["level-051@99"].stars == 3 and reloaded.record(campaign[50]).stars == 1, "Both board revisions survive save and reload")
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(path + ".cfg")
	DirAccess.remove_absolute(path + ".progress")
	print("REFINEMENT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
