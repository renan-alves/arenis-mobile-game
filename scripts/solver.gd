extends RefCounted
## Exact A*: a pour can eliminate at most one contiguous color run.
const Rules = preload("res://scripts/rules.gd")

func solve(level: Dictionary, max_states := 100000, max_ms := 10000, witness: Array = []) -> Dictionary:
	var started := Time.get_ticks_msec()
	if max_states < 1 or max_ms < 1:
		return {"status": "invalid_options", "solution": [], "minimum_moves": null}
	var definition := level.duplicate(true)
	definition["move_limit"] = 0
	definition["time_limit"] = 0
	var game := Rules.new(definition)
	var certified: Array = []
	if not witness.is_empty():
		var replay := Rules.new(definition)
		var valid := true
		for move in witness:
			if not move is Array or move.size() != 2:
				valid = false
				break
			if not (move[0] is int or move[0] is float) or not (move[1] is int or move[1] is float) or float(move[0]) != floor(float(move[0])) or float(move[1]) != floor(float(move[1])):
				valid = false
				break
			var step := [int(move[0]), int(move[1])]
			if replay.pour(step[0], step[1]).is_empty():
				valid = false
				break
			certified.append(step)
		if not valid or not replay.won():
			certified.clear()
	var upper_bound := certified.size()
	var goal_tubes := 0
	for bottle in game.bottles:
		goal_tubes += bottle.size()
	goal_tubes /= game.capacity
	var first := _state(game, -1, [], 0, goal_tubes)
	var nodes: Array = [first]
	var best := {first.key: 0}
	var heap: Array = [0]
	var expanded := 0
	while not heap.is_empty():
		if Time.get_ticks_msec() - started >= max_ms:
			return _result("limit", "time", nodes, -1, expanded, started)
		var current := _pop(heap, nodes)
		var node: Dictionary = nodes[current]
		if node.depth != best[node.key]:
			continue
		if upper_bound > 0 and node.f >= upper_bound:
			return _witness_result(certified, nodes.size(), expanded, started)
		_restore(game, node)
		if game.won():
			return _result("optimal", "", nodes, current, expanded, started)
		expanded += 1
		for source in game.bottles.size():
			for target in game.bottles.size():
				if Time.get_ticks_msec() - started >= max_ms:
					return _result("limit", "time", nodes, -1, expanded, started)
				_restore(game, node)
				if game.transfer_count(source, target) == 0:
					continue
				game.pour(source, target, false)
				var key := _key(game)
				var depth: int = node.depth + 1
				if best.has(key) and best[key] <= depth:
					continue
				var next := _state(game, current, [source, target], depth, goal_tubes)
				if upper_bound > 0 and next.f >= upper_bound:
					continue
				if nodes.size() >= max_states:
					return _result("limit", "states", nodes, -1, expanded, started)
				best[key] = depth
				nodes.append(next)
				_push(heap, nodes.size() - 1, nodes)
	if upper_bound > 0:
		return _witness_result(certified, nodes.size(), expanded, started)
	return _result("unsolvable", "exhausted", nodes, -1, expanded, started)

func _state(game: RefCounted, parent: int, move: Array, depth: int, goal: int) -> Dictionary:
	var runs := 0
	for bottle in game.bottles:
		var last := ""
		for token in bottle:
			if token.color != last:
				runs += 1
			last = token.color
	var h := maxi(0, runs - goal)
	return {"bottles": _copy_board(game.bottles), "locks": game.locks.duplicate(), "parent": parent,
		"move": move, "depth": depth, "h": h, "f": depth + h, "key": _key(game)}

func _copy_board(board: Array) -> Array:
	var copy: Array = []
	for bottle in board:
		copy.append(bottle.duplicate())
	return copy

func _restore(game: RefCounted, state: Dictionary) -> void:
	game.bottles = _copy_board(state.bottles)
	game.locks = state.locks.duplicate()
	game.moves = state.depth
	game.failed_reason = ""
	game.elapsed_seconds = 0.0

func _key(game: RefCounted) -> String:
	var state: Array[String] = []
	for i in game.bottles.size():
		var colors: Array = []
		for token in game.bottles[i]:
			colors.append(token.color)
		var required: String = game.definition.bottles[i].get("unlock_color", "") if game.locks[i] else ""
		state.append(JSON.stringify([colors, required]))
	state.sort()
	return JSON.stringify(state)

func _less(a: int, b: int, nodes: Array) -> bool:
	if nodes[a].f != nodes[b].f:
		return nodes[a].f < nodes[b].f
	if nodes[a].h != nodes[b].h:
		return nodes[a].h < nodes[b].h
	return a < b

func _push(heap: Array, value: int, nodes: Array) -> void:
	heap.append(value)
	var index := heap.size() - 1
	while index > 0:
		var parent := (index - 1) / 2
		if not _less(heap[index], heap[parent], nodes):
			break
		var swap: int = heap[parent]
		heap[parent] = heap[index]
		heap[index] = swap
		index = parent

func _pop(heap: Array, nodes: Array) -> int:
	var value: int = heap[0]
	var last: int = heap.pop_back()
	if heap.is_empty():
		return value
	heap[0] = last
	var index := 0
	while index * 2 + 1 < heap.size():
		var child := index * 2 + 1
		if child + 1 < heap.size() and _less(heap[child + 1], heap[child], nodes):
			child += 1
		if not _less(heap[child], heap[index], nodes):
			break
		var swap: int = heap[index]
		heap[index] = heap[child]
		heap[child] = swap
		index = child
	return value

func _result(status: String, reason: String, nodes: Array, goal: int, expanded: int, started: int) -> Dictionary:
	var solution: Array = []
	var index := goal
	while index >= 0 and nodes[index].parent >= 0:
		solution.push_front(nodes[index].move)
		index = nodes[index].parent
	return {"status": status, "reason": reason, "minimum_moves": solution.size() if goal >= 0 else null,
		"solution": solution, "states": nodes.size(), "expanded": expanded,
		"elapsed_ms": Time.get_ticks_msec() - started, "algorithm": "astar-runs-symmetry-v3", "rules_version": Rules.RULES_VERSION}

func _witness_result(solution: Array, states: int, expanded: int, started: int) -> Dictionary:
	return {"status": "optimal", "reason": "all_lower_cost_states_exhausted", "minimum_moves": solution.size(), "solution": solution.duplicate(true), "states": states, "expanded": expanded, "elapsed_ms": Time.get_ticks_msec() - started, "algorithm": "astar-verified-witness-v3", "rules_version": Rules.RULES_VERSION}

static func fingerprint(level: Dictionary) -> String:
	var bottles: Array = []
	for bottle in level.bottles:
		var hidden: Array = []
		for index in bottle.get("hidden", []):
			hidden.append(int(index))
		hidden.sort()
		bottles.append([bottle.colors, hidden, bottle.get("unlock_color", "")])
	return JSON.stringify([Rules.RULES_VERSION, level.id, int(level.version), level.difficulty_id, int(level.capacity), bottles, level.get("mode", "free"), int(level.get("move_limit", 0)), int(level.get("time_limit", 0))]).sha256_text()
