extends SceneTree
const Catalog = preload("res://scripts/level_catalog.gd")
const Solver = preload("res://scripts/solver.gd")
const Rules = preload("res://scripts/rules.gd")

func _initialize() -> void:
	var options := {"--input": "res://data/prototype_levels.json", "--output": "", "--max-states": "100000", "--max-ms": "10000"}
	var solve_only := false
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		if args[i] == "--solve":
			solve_only = true
			i += 1
			continue
		if not options.has(args[i]) or i + 1 >= args.size():
			printerr("Uso: --input arquivo --output relatório --max-states N --max-ms N [--solve]")
			quit(2)
			return
		options[args[i]] = args[i + 1]
		i += 2
	for option in ["--max-states", "--max-ms"]:
		if not str(options[option]).is_valid_int() or int(options[option]) < 1:
			printerr("Limite inválido: ", option)
			quit(2)
			return
	if not str(options["--output"]).is_empty() and _absolute(options["--output"]) == _absolute(options["--input"]):
		printerr("A saída não pode sobrescrever o arquivo de fases.")
		quit(2)
		return
	var loaded := Catalog.load_file(options["--input"], not solve_only)
	if not loaded.ok:
		printerr(JSON.stringify(loaded.errors))
		_save_report(options["--output"], {"schema_version": 1, "accepted": false, "errors": loaded.errors})
		quit(2)
		return
	var results: Array = []
	var failed := false
	for level in loaded.pack.levels:
		var result := Solver.new().solve(level, int(options["--max-states"]), int(options["--max-ms"]))
		result.id = level.id
		result.version = int(level.version)
		result.fingerprint = Solver.fingerprint(level)
		result.declared_minimum = int(level.minimum_moves)
		result.accepted = result.status == "optimal" and result.minimum_moves > 0 and (solve_only or result.minimum_moves == result.declared_minimum)
		if result.status == "optimal":
			var replay := Rules.new(level)
			for move in result.solution:
				if replay.pour(move[0], move[1]).is_empty():
					result.accepted = false
			result.accepted = result.accepted and replay.won() and replay.moves == result.minimum_moves
		failed = failed or not result.accepted
		results.append(result)
		print("%s: %s | mínimo=%s | estados=%d | %d ms | aceito=%s" % [level.id, result.status, str(result.minimum_moves), result.states, result.elapsed_ms, str(result.accepted)])
	var report := {"schema_version": 1, "pack_id": loaded.pack.pack_id, "pack_version": int(loaded.pack.pack_version), "rules_version": Rules.RULES_VERSION,
		"godot_version": Engine.get_version_info().string, "max_states": int(options["--max-states"]), "max_ms": int(options["--max-ms"]),
		"mode": "solve" if solve_only else "validate", "accepted": not failed, "results": results}
	if not _save_report(options["--output"], report):
		quit(2)
		return
	quit(1 if failed else 0)

func _save_report(path: String, report: Dictionary) -> bool:
	if path.is_empty():
		return true
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("Não foi possível gravar o relatório.")
		return false
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.flush()
	if file.get_error() != OK:
		printerr("Falha ao concluir a gravação do relatório.")
		return false
	return true

func _absolute(path: String) -> String:
	var absolute := ProjectSettings.globalize_path(path)
	if not absolute.is_absolute_path():
		absolute = ProjectSettings.globalize_path("res://").path_join(absolute)
	return absolute.simplify_path().to_lower() if OS.get_name() == "Windows" else absolute.simplify_path()
