extends RefCounted
const RULES_VERSION := 3
## Deterministic rules: no Nodes, rendering, timers, or random physics.

var definition: Dictionary
var capacity: int
var bottles: Array = []
var locks: Array = []
var known: Dictionary = {}
var history: Array = []
var moves: int = 0
var actions: Array = []
var elapsed_seconds := 0.0
var timer_started := false
var failed_reason := ""

func _init(level: Dictionary) -> void:
	definition = level.duplicate(true)
	capacity = int(level.capacity)
	restart()

func restart() -> void:
	bottles.clear()
	locks.clear()
	known.clear()
	history.clear()
	actions.clear()
	moves = 0
	elapsed_seconds = 0.0
	timer_started = false
	failed_reason = ""
	for i in definition.bottles.size():
		var spec: Dictionary = definition.bottles[i]
		var units: Array = []
		# JSON numbers arrive as floats. Normalize indices before membership checks.
		var hidden: Array = []
		for hidden_index in spec.get("hidden", []):
			hidden.append(int(hidden_index))
		for j in spec.colors.size():
			var token := {"color": str(spec.colors[j]), "id": "%s:%s" % [i, j]}
			units.append(token)
			if not hidden.has(j):
				known[token.id] = true
		bottles.append(units)
		locks.append(not str(spec.get("unlock_color", "")).is_empty())
	_reveal_tops()
	_unlock_completed()

func transfer_count(source: int, target: int) -> int:
	if source < 0 or target < 0 or source >= bottles.size() or target >= bottles.size():
		return 0
	if source == target or locks[source] or locks[target]:
		return 0
	var origin: Array = bottles[source]
	var destination: Array = bottles[target]
	if origin.is_empty() or destination.size() >= capacity:
		return 0
	var color: String = origin.back().color
	if not destination.is_empty() and destination.back().color != color:
		return 0
	var run := 0
	for j in range(origin.size() - 1, -1, -1):
		if origin[j].color != color:
			break
		run += 1
	return mini(run, capacity - destination.size())

func pour(source: int, target: int, record_history := true) -> Dictionary:
	var amount := transfer_count(source, target)
	if amount == 0 or won() or not failed_reason.is_empty():
		return {}
	if record_history:
		history.append(snapshot())
		actions.append(["pour", source, target])
	var color: String = bottles[source].back().color
	for _i in amount:
		bottles[target].append(bottles[source].pop_back())
	moves += 1
	timer_started = true
	# A single atomic move: transfer, reveal exposed runs, latch unlocks, evaluate victory.
	_reveal_tops()
	var unlocked := _unlock_completed()
	_evaluate_limits()
	return {"amount": amount, "color": color, "unlocked": unlocked, "won": won()}

func undo() -> bool:
	if history.is_empty() or not failed_reason.is_empty():
		return false
	var previous: Dictionary = history.pop_back()
	actions.append(["undo"])
	bottles = previous.bottles.duplicate(true)
	locks = previous.locks.duplicate()
	moves += 1
	_evaluate_limits()
	# Knowledge intentionally survives undo. Restart begins a fresh attempt.
	_reveal_tops()
	return true

func advance_time(delta: float) -> void:
	if not timer_started or won() or not failed_reason.is_empty() or delta <= 0 or not is_finite(delta):
		return
	if int(definition.get("time_limit", 0)) > 0:
		elapsed_seconds = minf(elapsed_seconds + delta, float(definition.time_limit))
		_evaluate_limits()

func _evaluate_limits() -> void:
	if won():
		failed_reason = ""
		return
	var budget := int(definition.get("move_limit", 0))
	var seconds := int(definition.get("time_limit", 0))
	if budget > 0 and moves >= budget:
		failed_reason = "moves"
	elif seconds > 0 and elapsed_seconds >= seconds:
		failed_reason = "time"

func remaining_moves() -> int:
	return maxi(0, int(definition.get("move_limit", 0)) - moves)

func remaining_seconds() -> float:
	return maxf(0.0, float(definition.get("time_limit", 0)) - elapsed_seconds)

func snapshot() -> Dictionary:
	return {"bottles": bottles.duplicate(true), "locks": locks.duplicate(), "moves": moves}

func restore_actions(journal: Variant) -> bool:
	if not journal is Array or journal.size() > 100000:
		return false
	restart()
	for action in journal:
		if not action is Array or action.is_empty():
			return false
		if action[0] == "pour" and action.size() == 3 and action[1] is int and action[2] is int:
			if pour(action[1], action[2]).is_empty():
				return false
		elif action[0] == "undo" and action.size() == 1:
			if not undo():
				return false
		else:
			return false
	return true

func won() -> bool:
	for bottle in bottles:
		if not bottle.is_empty() and not _complete(bottle):
			return false
	return true

func has_moves() -> bool:
	for source in bottles.size():
		for target in bottles.size():
			if transfer_count(source, target) > 0:
				return true
	return false

func stars() -> int:
	if not won():
		return 0
	var minimum := int(definition.get("minimum_moves", 0))
	if minimum <= 0:
		return 1
	if 5 * moves <= 6 * minimum:
		return 3
	if 2 * moves <= 3 * minimum:
		return 2
	return 1

func _complete(bottle: Array) -> bool:
	if bottle.size() != capacity:
		return false
	for unit in bottle:
		if unit.color != bottle[0].color:
			return false
	return true

func _reveal_tops() -> void:
	for i in bottles.size():
		if locks[i] or bottles[i].is_empty():
			continue
		var color: String = bottles[i].back().color
		for j in range(bottles[i].size() - 1, -1, -1):
			if bottles[i][j].color != color:
				break
			known[bottles[i][j].id] = true

func _unlock_completed() -> Array:
	var unlocked: Array = []
	var changed := true
	while changed:
		changed = false
		for i in locks.size():
			if not locks[i]:
				continue
			var color: String = definition.bottles[i].unlock_color
			for j in bottles.size():
				if i != j and not locks[j] and _complete(bottles[j]) and bottles[j][0].color == color:
					locks[i] = false
					unlocked.append(i)
					changed = true
					break
	if not unlocked.is_empty():
		_reveal_tops()
	return unlocked
