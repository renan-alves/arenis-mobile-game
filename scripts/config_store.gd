extends RefCounted
## Atomic local config writes, with a last-good backup for interrupted/corrupt saves.
static func read(path: String) -> Dictionary:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error == OK:
		return {"config": config, "error": OK, "recovered": false}
	var backup := ConfigFile.new()
	if backup.load(path + ".bak") == OK:
		return {"config": backup, "error": OK, "recovered": true}
	return {"config": ConfigFile.new(), "error": error, "recovered": false}

static func write(path: String, config: ConfigFile) -> Error:
	var target := ProjectSettings.globalize_path(path)
	var temporary := target + ".tmp"
	var error := config.save(temporary)
	if error != OK:
		return error
	var current := ConfigFile.new()
	if FileAccess.file_exists(target) and current.load(target) == OK:
		error = DirAccess.copy_absolute(target, target + ".bak")
		if error != OK:
			DirAccess.remove_absolute(temporary)
			return error
	error = DirAccess.rename_absolute(temporary, target)
	if error != OK:
		DirAccess.remove_absolute(temporary)
	return error
