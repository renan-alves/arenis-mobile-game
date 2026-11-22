extends SceneTree
## Run with: godot --headless --path . --script tests/rules_test.gd
const Rules = preload("res://scripts/rules.gd")
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func level(colors: Array, capacity := 3) -> Dictionary:
	var specs: Array = []
	for bottle in colors:
		specs.append({"colors": bottle})
	return {"capacity": capacity, "bottles": specs, "minimum_moves": 5}

func _initialize() -> void:
	var game := Rules.new(level([["a", "b", "b"], ["b", "a"], ["b"], ["a"]]))
	check(game.transfer_count(0, 2) == 2, "Transfer whole upper run")
	check(game.transfer_count(0, 1) == 0, "Different top color is rejected even with room")
	check(game.transfer_count(0, 0) == 0, "Reject self")
	check(game.transfer_count(-1, 0) == 0, "Reject out of range")
	var before := game.snapshot()
	check(game.pour(0, 0).is_empty() and game.moves == 0 and game.history.is_empty(), "Invalid pour cannot mutate history")
	check(game.snapshot() == before, "Invalid pour preserves state")
	var result := game.pour(0, 2)
	check(result.amount == 2 and game.moves == 1 and game.bottles[2].size() == 3, "One move for multiple units")
	check(game.undo() and game.bottles == before.bottles and game.locks == before.locks and game.moves == 2, "Undo restores board but costs one more move")
	check(not game.undo() and game.moves == 2, "Undo on empty history does not count")
	game = Rules.new(level([["a", "b", "b"], ["b", "b"], []]))
	check(game.transfer_count(0, 1) == 1, "Partial pour respects remaining capacity")
	game.pour(0, 1)
	check(game.bottles[0].size() == 2 and game.bottles[1].size() == 3, "Partial pour preserves remaining upper run")
	check(game.transfer_count(0, 1) == 0, "Cannot overfill")
	game = Rules.new(level([["coral", "coral"], ["aqua"], ["coral", "aqua", "aqua"]]))
	check(game.transfer_count(0, 1) == 0, "Different-color destination rejects a full top block")
	game.pour(0, 1)
	check(game.bottles[0].size() == 2 and game.bottles[1].size() == 1 and game.moves == 0, "Rejected different-color pour preserves board and move count")
	game = Rules.new(level([["a", "a"], ["b", "b", "a"], ["b"]]))
	game.definition.minimum_moves = 2
	game.pour(1, 0)
	game.undo()
	game.pour(1, 0)
	game.pour(2, 1)
	check(game.won() and game.moves == 4 and game.stars() == 1, "Undo is included in completion score")
	var hidden := level([["a", "b", "a"], [], []])
	hidden.bottles[0].hidden = [0, 1]
	game = Rules.new(hidden)
	check(game.known.has("0:2") and not game.known.has("0:1"), "Initial exposure")
	game.pour(0, 1)
	check(game.known.has("0:1"), "Reveal newly exposed color")
	game.undo()
	check(game.known.has("0:1") and game.moves == 2, "Undo preserves discoveries")
	game.restart()
	check(not game.known.has("0:1") and game.history.is_empty() and game.moves == 0, "Restart resets secrets and history")
	var lock_level := level([["a", "a"], ["b", "b", "a"], ["c", "c", "b"], ["c"]])
	lock_level.bottles[2].unlock_color = "a"
	game = Rules.new(lock_level)
	check(game.transfer_count(2, 1) == 0 and game.transfer_count(3, 2) == 0, "Locked vial cannot send or receive")
	game.pour(1, 0)
	check(not game.locks[2], "Completion unlocks indicated vial")
	game.undo()
	check(game.locks[2], "Undo restores lock")
	game.pour(1, 0)
	game.pour(2, 1)
	game.pour(3, 2)
	check(game.won(), "Full monochrome vials and empty helper win")
	check(game.pour(0, 3).is_empty(), "No moves after victory")
	game.definition.minimum_moves = 5
	for pair in [[6, 3], [7, 2], [8, 1]]:
		game.moves = pair[0]
		check(game.stars() == pair[1], "Star thresholds at integer boundaries")
	var cascade := level([["c", "c", "c"], ["b", "b", "b"], ["a", "a", "a"], ["x"]])
	cascade.bottles[0].unlock_color = "b"
	cascade.bottles[1].unlock_color = "a"
	var chain := Rules.new(cascade)
	check(not chain.locks[0] and not chain.locks[1], "Unlock cascades settle independent of bottle order")
	game = Rules.new(level([["a", "b", "a"], ["b", "a", "b"], ["c", "c", "c"]]))
	check(not game.won() and not game.has_moves(), "Incomplete uniform vials are not victory; detect no available move")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/prototype_levels.json"))
	for fixture in data.levels:
		var validation := validate_fixture(fixture)
		check(validation, "Fixture structure: " + fixture.id)
		if not validation:
			continue
		var solution := shortest_solution(fixture)
		check(not solution.is_empty(), "Fixture must be solvable: " + fixture.id)
		check(solution.size() == int(fixture.minimum_moves), "Minimum must match proof: " + fixture.id)
		print("FIXTURE ", fixture.id, " minimum=", solution.size(), " solution=", JSON.stringify(solution))
		game = Rules.new(fixture)
		for bottle_index in fixture.bottles.size():
			var fixture_hidden: Array = fixture.bottles[bottle_index].get("hidden", [])
			if not fixture_hidden.is_empty():
				check(not game.known.has("%d:%d" % [bottle_index, int(fixture_hidden[0])]), "JSON hidden indices remain concealed initially")
		for move in solution:
			check(not game.pour(move[0], move[1]).is_empty(), "Replay solution step")
		check(game.won() and game.stars() == 3, "Solution replay wins with 3 stars")
		while game.undo():
			pass
		check(game.moves == solution.size() * 2 and game.bottles == Rules.new(fixture).bottles, "Full undo sequence restores fixture")
	print("RULES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func validate_fixture(fixture: Dictionary) -> bool:
	var counts := {}
	for bottle in fixture.bottles:
		if bottle.colors.size() > int(fixture.capacity):
			return false
		for color in bottle.colors:
			counts[color] = int(counts.get(color, 0)) + 1
		for index in bottle.get("hidden", []):
			if index < 0 or index >= bottle.colors.size():
				return false
	for count in counts.values():
		if count % int(fixture.capacity) != 0:
			return false
	for bottle in fixture.bottles:
		if bottle.has("unlock_color") and not counts.has(bottle.unlock_color):
			return false
	return true

func key(game: RefCounted) -> String:
	var state: Array = []
	for i in game.bottles.size():
		var colors: Array = []
		for token in game.bottles[i]:
			colors.append(token.color)
		state.append([colors, game.locks[i]])
	return JSON.stringify(state)

func shortest_solution(fixture: Dictionary) -> Array:
	# Small exhaustive fixture proof, not the production campaign solver (phase 2).
	var first := Rules.new(fixture)
	var queue: Array = [{"state": first.snapshot(), "path": []}]
	var visited := {key(first): true}
	var cursor := 0
	while cursor < queue.size() and cursor < 100000:
		var item: Dictionary = queue[cursor]
		cursor += 1
		var game := Rules.new(fixture)
		game.bottles = item.state.bottles.duplicate(true)
		game.locks = item.state.locks.duplicate()
		game.moves = item.state.moves
		if game.won():
			return item.path
		for source in game.bottles.size():
			for target in game.bottles.size():
				if game.transfer_count(source, target) == 0:
					continue
				var next := Rules.new(fixture)
				next.bottles = game.bottles.duplicate(true)
				next.locks = game.locks.duplicate()
				next.moves = game.moves
				next.pour(source, target)
				var next_key := key(next)
				if visited.has(next_key):
					continue
				visited[next_key] = true
				var path: Array = item.path.duplicate(true)
				path.append([source, target])
				queue.append({"state": next.snapshot(), "path": path})
	return []
