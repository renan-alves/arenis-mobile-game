extends RefCounted
## Completed results only. Merge is commutative, associative and idempotent.
const MAX_BYTES := 1048576
const MAX_RESULTS := 15000

static func decode(payload: String) -> Dictionary:
	if payload.is_empty():
		return {"ok": true, "results": {}}
	if payload.to_utf8_buffer().size() > MAX_BYTES:
		return {"ok": false}
	var parser := JSON.new()
	if parser.parse(payload) != OK:
		return {"ok": false}
	var data: Variant = parser.data
	if not data is Dictionary or data.get("schema_version") != 2 or not data.get("results") is Array or data.results.size() > MAX_RESULTS:
		return {"ok": false}
	var results := {}
	for item in data.results:
		if not item is Dictionary or not item.get("id") is String or item.id.is_empty() or item.id.length() > 96:
			return {"ok": false}
		for ch in item.id:
			if not (ch in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-."):
				return {"ok": false}
		for field in ["version", "rules_version", "stars", "best_moves"]:
			var value: Variant = item.get(field)
			if not (value is int or value is float) or not is_finite(float(value)) or value != floor(float(value)) or value < 1 or value > (3 if field == "stars" else 1000000):
				return {"ok": false}
		var record := {"id": item.id, "version": int(item.version), "rules_version": int(item.rules_version), "stars": int(item.stars), "best_moves": int(item.best_moves)}
		var key := "%s@%d@%d" % [record.id, record.version, record.rules_version]
		results[key] = combine(results.get(key, {}), record)
	return {"ok": true, "results": results}

static func combine(left: Dictionary, right: Dictionary) -> Dictionary:
	var result := right.duplicate(true)
	if not left.is_empty():
		result.stars = maxi(int(left.stars), int(right.stars))
		result.best_moves = mini(int(left.best_moves), int(right.best_moves))
	return result

static func encode(results: Dictionary) -> String:
	var keys := results.keys()
	keys.sort()
	var items := []
	for key in keys:
		items.append(results[key])
	return JSON.stringify({"schema_version": 2, "results": items})

static func merge(left: String, right: String) -> Dictionary:
	var a := decode(left)
	var b := decode(right)
	if not a.ok or not b.ok:
		return {"ok": false}
	for key in b.results:
		a.results[key] = combine(a.results.get(key, {}), b.results[key])
	if a.results.size() > MAX_RESULTS:
		return {"ok": false}
	var payload := encode(a.results)
	return {"ok": payload.to_utf8_buffer().size() <= MAX_BYTES, "payload": payload}
