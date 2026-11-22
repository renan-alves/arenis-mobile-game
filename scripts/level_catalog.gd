extends RefCounted
const Rules = preload("res://scripts/rules.gd")
## Strict pack validation shared by the game and authoring tools.
const CAPACITIES := {"easy": 3, "medium": 5, "hard": 7}
const COLORS := ["coral", "aqua", "gold", "lilac", "sky", "sage", "rose", "peach", "indigo", "mint"]

static func integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))

static func unknown_fields(value: Dictionary, allowed: Array, path: String, errors: Array) -> void:
	for field in value:
		if not allowed.has(field):
			errors.append(path + ": campo desconhecido " + str(field))

static func validate(pack: Variant, require_minimum := true) -> Array:
	var errors: Array = []
	if not pack is Dictionary:
		return ["O pacote deve ser um objeto."]
	unknown_fields(pack, ["schema_version", "rules_version", "pack_id", "pack_version", "levels"], "pacote", errors)
	if not integer(pack.get("schema_version")) or not integer(pack.get("rules_version")) or pack.schema_version != 3 or pack.rules_version != Rules.RULES_VERSION:
		errors.append("Versão incompatível: esperado schema_version 3 e rules_version 3.")
	if not _identifier(pack.get("pack_id")) or not integer(pack.get("pack_version")) or pack.get("pack_version", 0) < 1:
		errors.append("pack_id e pack_version inválidos.")
	if not pack.get("levels") is Array or pack.get("levels", []).is_empty():
		errors.append("levels deve ser uma lista não vazia.")
		return errors
	var ids := {}
	for i in pack.levels.size():
		var level: Variant = pack.levels[i]
		var path := "levels[%d]" % i
		if not level is Dictionary:
			errors.append(path + ": fase deve ser objeto.")
			continue
		unknown_fields(level, ["id", "version", "title", "difficulty", "difficulty_id", "capacity", "minimum_moves", "lesson", "bottles", "number", "mode", "move_limit", "time_limit"], path, errors)
		if not _identifier(level.get("id")):
			errors.append(path + ": id inválido.")
		elif ids.has(level.id):
			errors.append(path + ": id duplicado " + level.id)
		else:
			ids[level.id] = true
		if not integer(level.get("version")) or level.get("version", 0) < 1:
			errors.append(path + ": version deve ser inteiro positivo.")
		for field in ["title", "difficulty", "lesson"]:
			if not level.get(field) is String or str(level.get(field, "")).strip_edges().is_empty():
				errors.append(path + ": texto obrigatório " + field)
		var difficulty: Variant = level.get("difficulty_id")
		var capacity: Variant = level.get("capacity")
		if not difficulty is String or not (CAPACITIES.has(difficulty) or difficulty == "journey"):
			errors.append(path + ": difficulty_id inválido.")
			continue
		if not integer(capacity) or capacity < 3 or capacity > 7 or (difficulty != "journey" and capacity != CAPACITIES[difficulty]):
			errors.append(path + ": capacidade incompatível com dificuldade.")
			continue
		if difficulty == "journey":
			if not integer(level.get("number")) or int(level.get("number", 0)) != i + 1:
				errors.append(path + ": número fora da sequência.")
			var mode: Variant = level.get("mode")
			var moves: Variant = level.get("move_limit")
			var seconds: Variant = level.get("time_limit")
			if mode not in ["free", "moves", "timed"] or not integer(moves) or not integer(seconds):
				errors.append(path + ": tipo de desafio ou limite inválido.")
			elif moves < 0 or seconds < 0 or seconds > 3600 or moves > 10000 or (moves > 0 and seconds > 0):
				errors.append(path + ": limites incompatíveis.")
			elif (mode == "free" and (moves != 0 or seconds != 0)) or (mode == "moves" and (moves < 1 or seconds != 0)) or (mode == "timed" and (seconds < 1 or moves != 0)):
				errors.append(path + ": limite não corresponde ao modo.")
			elif require_minimum and moves > 0 and integer(level.get("minimum_moves")) and moves < level.minimum_moves:
				errors.append(path + ": limite abaixo do mínimo possível.")
		if not integer(level.get("minimum_moves")) or level.get("minimum_moves", -1) < (1 if require_minimum else 0):
			errors.append(path + ": minimum_moves inválido.")
		if not level.get("bottles") is Array or level.get("bottles", []).size() < 2:
			errors.append(path + ": pelo menos dois frascos são necessários.")
			continue
		var counts := {}
		var lock_colors: Array = []
		for j in level.bottles.size():
			var bottle: Variant = level.bottles[j]
			var bp := path + ".bottles[%d]" % j
			if not bottle is Dictionary:
				errors.append(bp + ": frasco deve ser objeto.")
				continue
			unknown_fields(bottle, ["colors", "hidden", "unlock_color"], bp, errors)
			if not bottle.get("colors") is Array:
				errors.append(bp + ": colors deve ser lista.")
				continue
			if bottle.colors.size() > int(capacity):
				errors.append(bp + ": capacidade excedida.")
			for color in bottle.colors:
				if not color is String or not COLORS.has(color):
					errors.append(bp + ": cor não suportada.")
				else:
					counts[color] = int(counts.get(color, 0)) + 1
			var hidden: Variant = bottle.get("hidden", [])
			if not hidden is Array:
				errors.append(bp + ": hidden deve ser lista.")
			else:
				var seen := {}
				for index in hidden:
					if not integer(index) or index < 0 or index >= bottle.colors.size():
						errors.append(bp + ": índice oculto inválido.")
					elif seen.has(int(index)):
						errors.append(bp + ": índice oculto repetido.")
					else:
						seen[int(index)] = true
			if bottle.has("unlock_color"):
				if not bottle.unlock_color is String or not COLORS.has(bottle.unlock_color):
					errors.append(bp + ": unlock_color inválido.")
				else:
					lock_colors.append(bottle.unlock_color)
		if counts.is_empty():
			errors.append(path + ": não há areia.")
		for color in counts:
			if counts[color] % int(capacity) != 0:
				errors.append(path + ": quantidade de " + color + " não completa frascos inteiros.")
		for color in lock_colors:
			if not counts.has(color):
				errors.append(path + ": cor de desbloqueio ausente.")
	return errors

static func load_file(path: String, require_minimum := true) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "errors": ["Não foi possível abrir " + path], "pack": {}}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"ok": false, "errors": ["JSON linha %d: %s" % [parser.get_error_line(), parser.get_error_message()]], "pack": {}}
	var errors := validate(parser.data, require_minimum)
	return {"ok": errors.is_empty(), "errors": errors, "pack": parser.data if errors.is_empty() else {}}

static func _identifier(value: Variant) -> bool:
	if not value is String or value.is_empty():
		return false
	for character in value:
		if not "abcdefghijklmnopqrstuvwxyz0123456789-_".contains(character):
			return false
	return true
