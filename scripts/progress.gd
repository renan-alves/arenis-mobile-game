extends RefCounted
const Rules = preload("res://scripts/rules.gd")
const Solver = preload("res://scripts/solver.gd")
const Store = preload("res://scripts/config_store.gd")
const Cloud = preload("res://scripts/cloud_records.gd")
const DEFAULT_PATH := "user://journey_progress.cfg"
var path: String
var records: Dictionary = {}
var archived_records: Dictionary = {}
var attempts: Dictionary = {}
var sequence := 0
var recovered := false

func _init(file_path := DEFAULT_PATH) -> void:
	path = file_path
	var loaded := Store.read(path)
	if loaded.error != OK:
		return
	var config: ConfigFile = loaded.config
	recovered = loaded.recovered
	for section in ["levels", "archived_levels"]:
		for id in config.get_section_keys(section) if config.has_section(section) else []:
			var value: Variant = config.get_value(section, id)
			if value is Dictionary and value.get("version") is int and value.get("stars") is int and value.get("best_moves") is int:
				if value.version > 0 and value.stars >= 1 and value.stars <= 3 and value.best_moves > 0:
					if section == "levels":
						records[id] = value
					else:
						archived_records[id] = value
	for difficulty in ["journey", "easy", "medium", "hard"]:
		var value: Variant = config.get_value("attempts", difficulty, {})
		if value is Dictionary and value.get("sequence") is int and value.sequence >= 0 and value.get("level_id") is String and value.get("actions") is Array:
			attempts[difficulty] = value
			sequence = maxi(sequence, int(value.get("sequence", 0)))

func record(level: Dictionary) -> Dictionary:
	var value: Dictionary = records.get(level.id, {})
	return value if value.get("version", -1) == int(level.version) and value.get("rules_version", Rules.RULES_VERSION) == Rules.RULES_VERSION else {}

func complete(level: Dictionary, stars: int, moves: int) -> Error:
	if stars < 1 or stars > 3 or moves < 1:
		return ERR_INVALID_DATA
	var old := record(level)
	var pending_archives := archived_records.duplicate(true)
	if records.has(level.id) and (int(records[level.id].version) != int(level.version) or records[level.id].get("rules_version", Rules.RULES_VERSION) != Rules.RULES_VERSION):
		var previous: Dictionary = records[level.id]
		var archive_key := "%s@%d" % [level.id, previous.version]
		if previous.get("rules_version", Rules.RULES_VERSION) != Rules.RULES_VERSION:
			archive_key += "@%d" % previous.rules_version
		pending_archives[archive_key] = previous.duplicate(true)
	var value := {"rules_version": Rules.RULES_VERSION, "version": int(level.version), "stars": maxi(stars, int(old.get("stars", 0))), "best_moves": mini(moves, int(old.get("best_moves", moves)))}
	var pending := records.duplicate(true)
	pending[level.id] = value
	var pending_attempts := attempts.duplicate(true)
	pending_attempts.erase(level.difficulty_id)
	var error := _commit(pending, pending_archives, pending_attempts)
	if error == OK:
		records = pending
		archived_records = pending_archives
		attempts = pending_attempts
	return error

func save_attempt(level: Dictionary, game: RefCounted) -> Error:
	if game.moves != game.actions.size():
		return ERR_INVALID_DATA
	if game.won():
		return complete(level, game.stars(), game.moves)
	var next := attempts.duplicate(true)
	next[level.difficulty_id] = {"schema_version": 1, "rules_version": Rules.RULES_VERSION,
		"level_id": level.id, "version": int(level.version), "fingerprint": Solver.fingerprint(level),
		"sequence": sequence + 1, "actions": game.actions.duplicate(true),
		"elapsed_seconds": game.elapsed_seconds, "timer_started": game.timer_started}
	var error := _commit(records, archived_records, next)
	if error == OK:
		sequence += 1
		attempts = next
	return error

func restore_attempt(level: Dictionary) -> RefCounted:
	var saved: Dictionary = attempts.get(level.difficulty_id, {})
	if saved.get("level_id", "") != level.id or saved.get("schema_version") != 1 or saved.get("rules_version") != Rules.RULES_VERSION or saved.get("version") != int(level.version) or saved.get("fingerprint") != Solver.fingerprint(level):
		return null
	var game := Rules.new(level)
	if not game.restore_actions(saved.get("actions")) or game.won():
		return null
	var elapsed: Variant = saved.get("elapsed_seconds", 0.0)
	if not (elapsed is int or elapsed is float) or not is_finite(float(elapsed)) or elapsed < 0 or elapsed > 86400:
		return null
	game.elapsed_seconds = float(elapsed)
	game.timer_started = saved.get("timer_started", not game.actions.is_empty()) == true
	game._evaluate_limits()
	return game

func latest_attempt(levels: Array, difficulty := "") -> int:
	var latest := -1
	var order := -1
	for index in levels.size():
		var level: Dictionary = levels[index]
		if not difficulty.is_empty() and level.difficulty_id != difficulty:
			continue
		var saved: Dictionary = attempts.get(level.difficulty_id, {})
		if saved.get("level_id", "") == level.id and int(saved.get("sequence", -1)) > order and restore_attempt(level) != null:
			latest = index
			order = int(saved.sequence)
	return latest

func _commit(scores: Dictionary, archives: Dictionary, pending: Dictionary) -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", 2)
	for id in scores:
		config.set_value("levels", id, scores[id])
	for id in archives:
		config.set_value("archived_levels", id, archives[id])
	for difficulty in pending:
		config.set_value("attempts", difficulty, pending[difficulty])
	return Store.write(path, config)

func export_cloud() -> String:
	var results := {}
	for id in records:
		var item: Dictionary = records[id].duplicate(true)
		item["id"] = id
		item["rules_version"] = item.get("rules_version", Rules.RULES_VERSION)
		results["%s@%d@%d" % [id, item.version, item.rules_version]] = item
	for key in archived_records:
		var item: Dictionary = archived_records[key].duplicate(true)
		var id: String = key.get_slice("@", 0)
		item["id"] = id
		item["rules_version"] = item.get("rules_version", Rules.RULES_VERSION)
		var compound := "%s@%d@%d" % [id, item.version, item.rules_version]
		results[compound] = Cloud.combine(results.get(compound, {}), item)
	return Cloud.encode(results)

func merge_cloud(payload: String, levels: Array) -> Error:
	var merged := Cloud.merge(export_cloud(), payload)
	if not merged.ok:
		return ERR_INVALID_DATA
	var decoded := Cloud.decode(merged.payload)
	var pending := records.duplicate(true)
	var archives := archived_records.duplicate(true)
	var current := {}
	for level in levels:
		current[level.id] = int(level.version)
	for key in decoded.results:
		var item: Dictionary = decoded.results[key].duplicate(true)
		var id: String = item.id
		item.erase("id")
		if current.get(id, -1) == item.version and item.rules_version == Rules.RULES_VERSION:
			if pending.has(id) and (pending[id].version != item.version or pending[id].get("rules_version", Rules.RULES_VERSION) != item.rules_version):
				var previous: Dictionary = pending[id]
				archives["%s@%d@%d" % [id, previous.version, previous.get("rules_version", Rules.RULES_VERSION)]] = previous
			pending[id] = item
		else:
			archives[key] = item
	var error := _commit(pending, archives, attempts)
	if error == OK:
		records = pending
		archived_records = archives
	return error
