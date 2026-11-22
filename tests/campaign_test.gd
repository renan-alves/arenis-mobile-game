extends SceneTree
const Catalog = preload("res://scripts/level_catalog.gd")
const Progress = preload("res://scripts/progress.gd")
const Rules = preload("res://scripts/rules.gd")
const Solver = preload("res://scripts/solver.gd")
var checks := 0
var failures := 0
func check(condition: bool, text: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(text)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var loaded := Catalog.load_file("res://data/campaign.json")
	check(loaded.ok, "Campaign schema")
	if not loaded.ok:
		printerr(loaded.errors)
		quit(1)
		return
	var levels: Array = loaded.pack.levels
	var proof: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/relatorios/jornada-v3-provas.json"))
	check(proof.accepted and proof.rules_version == 3 and proof.results.size() == 150, "Final campaign proof accepted")
	for i in levels.size():
		var result: Dictionary = proof.results[i]
		check(result.status == "optimal" and result.fingerprint == Solver.fingerprint(levels[i]) and result.minimum_moves == levels[i].minimum_moves, "Current board matches proven minimum")
		var game := Rules.new(levels[i])
		for move in result.solution:
			check(not game.pour(move[0], move[1]).is_empty(), "Campaign solution replay")
		check(game.won(), "Campaign level wins")
	check(levels.size() == 150, "150 levels")
	for i in levels.size():
		check(levels[i].difficulty_id == "journey" and levels[i].title == "Nível %d" % (i + 1) and int(levels[i].minimum_moves) > 0, "Sequential number and minimum")
	var path := OS.get_environment("TEMP").path_join("arenis-progress-%d.cfg" % Time.get_ticks_usec())
	var progress := Progress.new(path)
	var first: Dictionary = levels[0]
	check(progress.complete(first, 2, 10) == OK, "Save completed score")
	check(progress.complete(first, 1, 15) == OK, "Replay saves")
	check(progress.record(first).stars == 2 and progress.record(first).best_moves == 10, "Replay cannot downgrade record")
	check(Progress.new(path).record(first) == progress.record(first), "Progress reloads")
	var changed := first.duplicate(true)
	changed.version = 2
	check(progress.record(changed).is_empty(), "Different board revision never inherits record")
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = progress
	root.add_child(scene)
	await process_frame
	check(scene.levels.size() == 150, "Game loads campaign")
	check(scene._is_unlocked(0) and scene._is_unlocked(1) and not scene._is_unlocked(2), "Sequential progression")
	check(not scene._is_unlocked(50) and not scene._is_unlocked(100), "Later campaign levels remain locked")
	scene._choose_difficulty("easy")
	await process_frame
	await process_frame
	var scroll = scene.root.find_children("*", "ScrollContainer", true, false)[0]
	check(not scroll.get_h_scroll_bar().is_visible_in_tree(), "Campaign grid has no horizontal overflow")
	check(scene.active_difficulty == "journey", "Single campaign selection")
	scene._start(0)
	scene._close_modal()
	await process_frame
	check(scene.game.capacity == 3, "Playable campaign board")
	for move in proof.results[0].solution:
		scene.game.pour(move[0], move[1])
	scene._refresh()
	scene._show_result()
	check(Progress.new(path).record(first).stars == 3 and Progress.new(path).record(first).best_moves == int(first.minimum_moves), "Game victory persists its optimal result")
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(path)
	print("CAMPAIGN: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
