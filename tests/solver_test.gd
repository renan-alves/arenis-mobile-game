extends SceneTree
const Catalog = preload("res://scripts/level_catalog.gd")
const Solver = preload("res://scripts/solver.gd")
const Rules = preload("res://scripts/rules.gd")
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var loaded := Catalog.load_file("res://data/prototype_levels.json")
	check(loaded.ok, "Migrated pack loads")
	if not loaded.ok:
		printerr(loaded.errors)
		quit(1)
		return
	var pack: Dictionary = loaded.pack
	for level in pack.levels:
		var result := Solver.new().solve(level)
		check(result.status == "optimal" and result.minimum_moves == int(level.minimum_moves), "Known fixture minimum: " + level.id)
		var game := Rules.new(level)
		for move in result.solution:
			check(not game.pour(move[0], move[1]).is_empty(), "Legal certificate step")
		check(game.won(), "Certificate wins")
	var witness: Array = Solver.new().solve(pack.levels[0]).solution
	var misleading: Dictionary = pack.levels[0].duplicate(true)
	misleading.minimum_moves = 1
	check(Solver.new().solve(misleading, 100000, 10000, witness).minimum_moves == pack.levels[0].minimum_moves, "Witness proves the board independently of its claimed minimum")
	for invalid_witness in [[[0, 0]], [[-1, 0]], [[0.5, 1]], [[0, 1]]]:
		check(Solver.new().solve(pack.levels[0], 100000, 10000, invalid_witness).minimum_moves == pack.levels[0].minimum_moves, "Invalid or incomplete witness cannot certify a shorter answer")
	var limit := Solver.new().solve(pack.levels[0], 1, 10000)
	check(limit.status == "limit" and limit.reason == "states" and limit.minimum_moves == null and limit.solution.is_empty(), "Limit is never an impossibility or minimum proof")
	check(Solver.new().solve(pack.levels[0], 0).status == "invalid_options", "Reject invalid solver budgets")
	var benchmark: Dictionary = Catalog.load_file("res://tests/data/benchmark_levels.json", false).pack
	var timed := Solver.new().solve(benchmark.levels[1], 1000000, 1)
	check(timed.status == "limit" and timed.reason == "time" and timed.minimum_moves == null, "Time budget never invents a minimum")
	var deadlock: Dictionary = pack.levels[0].duplicate(true)
	deadlock.bottles.pop_back()
	check(Catalog.validate(_pack(pack, deadlock)).is_empty(), "Structurally valid unsolvable board")
	var dead_result := Solver.new().solve(deadlock)
	check(dead_result.status == "unsolvable" and dead_result.minimum_moves == null, "Exhaustion proves unsolvable")
	var locked := deadlock.duplicate(true)
	locked.bottles[0].unlock_color = "aqua"
	locked.bottles[1].unlock_color = "coral"
	check(Solver.new().solve(locked).status == "unsolvable", "Circular locks cannot magically unlock")
	var solved := deadlock.duplicate(true)
	solved.bottles = [{"colors": ["coral", "coral", "coral"]}, {"colors": ["aqua", "aqua", "aqua"]}]
	var solved_result := Solver.new().solve(solved)
	check(solved_result.status == "optimal" and solved_result.minimum_moves == 0, "Zero-move goal is distinguishable from no solution")
	for field in ["schema_version", "rules_version", "pack_id", "pack_version", "levels"]:
		for bad in [null, true, {}, "", -1, 1.5]:
			var damaged := pack.duplicate(true)
			damaged[field] = bad
			check(not Catalog.validate(damaged).is_empty(), "Reject malformed pack " + field)
	for field in ["id", "version", "capacity", "difficulty_id", "minimum_moves", "bottles"]:
		for bad in [null, true, {}, [], -1, 1.5]:
			var damaged := pack.duplicate(true)
			damaged.levels[0][field] = bad
			check(not Catalog.validate(damaged).is_empty(), "Reject malformed level " + field)
	for patch in [{"hidden": [0.5]}, {"hidden": [0, 0]}, {"hidden": [99]}, {"colors": ["missing"]}, {"unlock_color": 1}, {"typo": 1}]:
		var damaged := pack.duplicate(true)
		damaged.levels[0].bottles[0].merge(patch, true)
		check(not Catalog.validate(damaged).is_empty(), "Reject malformed bottle")
	var duplicate := pack.duplicate(true)
	duplicate.levels.append(duplicate.levels[0].duplicate(true))
	check(not Catalog.validate(duplicate).is_empty(), "Duplicate IDs")
	var absent_key := pack.duplicate(true)
	absent_key.levels[0].bottles[0].unlock_color = "gold"
	check(not Catalog.validate(absent_key).is_empty(), "Missing unlock color")
	var fingerprint := Solver.fingerprint(pack.levels[0])
	var changed: Dictionary = pack.levels[0].duplicate(true)
	changed.title = "Texto diferente"
	changed.minimum_moves = 99
	check(Solver.fingerprint(changed) == fingerprint, "Fingerprint excludes prose and claimed answer")
	changed.version = 2
	check(Solver.fingerprint(changed) != fingerprint, "Revision changes fingerprint")
	changed = pack.levels[0].duplicate(true)
	changed.bottles[0].hidden = [0]
	check(Solver.fingerprint(changed) != fingerprint, "Hidden layout changes fingerprint")
	# All 20 two-color arrangements of two full capacity-3 vials plus an empty helper.
	for mask in 64:
		var colors: Array = []
		var reds := 0
		for bit in 6:
			var red := (mask & (1 << bit)) != 0
			reds += int(red)
			colors.append("coral" if red else "aqua")
		if reds != 3:
			continue
		var sample: Dictionary = pack.levels[0].duplicate(true)
		sample.bottles = [{"colors": colors.slice(0, 3)}, {"colors": colors.slice(3, 6)}, {"colors": []}]
		var result := Solver.new().solve(sample)
		check(result.status == "optimal" and result.minimum_moves == _reference_minimum(sample), "Cross-check complete small family against original BFS")
		for key_color in ["coral", "aqua"]:
			var with_lock := sample.duplicate(true)
			with_lock.bottles[2].unlock_color = key_color
			var expected := _reference_minimum(with_lock)
			var exact := Solver.new().solve(with_lock)
			check((exact.status == "unsolvable" and expected == -1) or (exact.status == "optimal" and exact.minimum_moves == expected), "Lock-aware symmetry agrees with positional BFS")
			with_lock.bottles.reverse()
			var permuted := Solver.new().solve(with_lock)
			check(permuted.status == exact.status and permuted.minimum_moves == exact.minimum_moves, "Permuting tubes preserves the exact answer with locks")
	# Distributed free space and partial blocks, including hidden units.
	for rows in [[["coral", "aqua"], ["coral", "aqua"], ["coral", "aqua"]], [["coral", "coral"], ["aqua"], ["coral", "aqua", "aqua"]]]:
		var sample: Dictionary = pack.levels[0].duplicate(true)
		sample.bottles = rows.map(func(row): return {"colors": row})
		sample.bottles[2].hidden = [0]
		var exact := Solver.new().solve(sample)
		var reference := _reference_minimum(sample)
		check((exact.status == "unsolvable" and reference == -1) or (exact.status == "optimal" and exact.minimum_moves == reference), "Distributed space and hidden colors agree with independent BFS")
	var unlocking: Dictionary = pack.levels[0].duplicate(true)
	unlocking.bottles = [{"colors": ["coral", "coral"]}, {"colors": ["aqua", "aqua", "coral"]}, {"colors": ["aqua"], "unlock_color": "coral"}, {"colors": []}]
	for permutation in 4:
		var exact := Solver.new().solve(unlocking)
		check(exact.status == "optimal" and exact.minimum_moves == _reference_minimum(unlocking), "Latch unlock during play agrees with positional BFS")
		var replay := Rules.new(unlocking)
		for move in exact.solution:
			replay.pour(move[0], move[1])
		check(replay.won(), "Symmetric search retains a certificate using original tube indices")
		unlocking.bottles.append(unlocking.bottles.pop_front())
	print("SOLVER/CATALOG: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _pack(pack: Dictionary, level: Dictionary) -> Dictionary:
	var copy := pack.duplicate(true)
	copy.levels = [level]
	return copy

func _reference_minimum(level: Dictionary) -> int:
	# Independent queue/deep-snapshot implementation retained as a tiny oracle.
	var initial := Rules.new(level)
	var queue: Array = [initial.snapshot()]
	var seen := {}
	var cursor := 0
	while cursor < queue.size():
		var state: Dictionary = queue[cursor]
		cursor += 1
		var game := Rules.new(level)
		game.bottles = state.bottles.duplicate(true)
		game.locks = state.locks.duplicate()
		game.moves = state.moves
		if game.won():
			return game.moves
		for source in game.bottles.size():
			for target in game.bottles.size():
				var next := Rules.new(level)
				next.bottles = game.bottles.duplicate(true)
				next.locks = game.locks.duplicate()
				next.moves = game.moves
				if next.pour(source, target).is_empty():
					continue
				var colors: Array = []
				for bottle in next.bottles:
					var row: Array = []
					for token in bottle:
						row.append(token.color)
					colors.append(row)
				var key := JSON.stringify([colors, next.locks])
				if not seen.has(key):
					seen[key] = true
					queue.append(next.snapshot())
	return -1
