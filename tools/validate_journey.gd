extends SceneTree
const Catalog = preload("res://scripts/level_catalog.gd")
const Solver = preload("res://scripts/solver.gd")
const Rules = preload("res://scripts/rules.gd")
func _initialize() -> void:
	var options := {"--input":"res://data/campaign.json", "--witnesses":"res://docs/relatorios/jornada-v3-provas.json", "--output":"res://tmp/journey-certified.json"}
	var args := OS.get_cmdline_user_args()
	for i in args.size()-1:
		if options.has(args[i]): options[args[i]] = args[i+1]
	if options["--output"] in [options["--input"], options["--witnesses"]]:
		printerr("Output must differ from the pack and its witness input."); quit(2); return
	var loaded := Catalog.load_file(options["--input"])
	if not loaded.ok:
		printerr(loaded.errors)
		quit(2)
		return
	var witnesses: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(options["--witnesses"]))
	var cached: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(options["--output"])) if "--reuse" in OS.get_cmdline_user_args() else {}
	var results: Array = []
	var accepted := true
	for i in loaded.pack.levels.size():
		var level: Dictionary = loaded.pack.levels[i]
		var result: Dictionary
		if cached.get("results", []).size() > i and cached.results[i].get("accepted", false) and cached.results[i].fingerprint == Solver.fingerprint(level):
			result = cached.results[i].duplicate(true)
		else:
			result = Solver.new().solve(level, 120000, 20000, witnesses.results[i].solution)
		result.id = level.id
		result.version = int(level.version)
		result.fingerprint = Solver.fingerprint(level)
		result.accepted = result.status == "optimal" and result.minimum_moves == int(level.minimum_moves)
		var replay := Rules.new(level)
		for move in result.solution:
			if replay.pour(int(move[0]), int(move[1])).is_empty(): result.accepted = false
		result.accepted = result.accepted and replay.won() and replay.failed_reason.is_empty()
		accepted = accepted and result.accepted
		results.append(result)
		print("%s: minimum=%s; states=%s; accepted=%s" % [level.id, str(result.minimum_moves), str(result.states), str(result.accepted)])
	var report := {"mode":"validate", "godot_version":Engine.get_version_info().string, "max_states":120000, "max_ms":20000, "rules_version": 3, "pack_id": loaded.pack.pack_id, "pack_version": loaded.pack.pack_version, "accepted": accepted, "results": results}
	var file := FileAccess.open(options["--output"], FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	quit(0 if accepted else 1)
