extends RefCounted
const SUPPORTED := ["pt_BR", "en", "es_419"]
static var installed := false

static func resolve(mode: String, device_locale: String) -> String:
	if mode in SUPPORTED:
		return mode
	var language := device_locale.replace("-", "_").get_slice("_", 0).to_lower()
	if language == "en":
		return "en"
	if language == "es":
		return "es_419"
	return "pt_BR"

static func apply(mode: String, device_locale := "") -> String:
	if not installed:
		for locale in SUPPORTED:
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://locales/%s.json" % locale))
			if not data is Dictionary:
				push_error("Invalid translation pack: " + locale)
				continue
			var translation := Translation.new()
			translation.locale = locale
			for key in data:
				translation.add_message(key, data[key])
			TranslationServer.add_translation(translation)
		installed = true
	var locale := resolve(mode, OS.get_locale() if device_locale.is_empty() else device_locale)
	TranslationServer.set_locale(locale)
	return locale
