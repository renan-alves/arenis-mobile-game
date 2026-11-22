extends SceneTree
const Localization = preload("res://scripts/localization.gd")
const Preferences = preload("res://scripts/preferences.gd")
const Progress = preload("res://scripts/progress.gd")
var checks := 0
var failures := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://locales/pt_BR.json"))
	var expression := RegEx.new()
	expression.compile("%[sd]")
	for locale in Localization.SUPPORTED:
		var pack: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://locales/%s.json" % locale))
		check(pack.size() == base.size(), "Language pack key count")
		for key in base:
			check(pack.has(key) and pack[key] is String and not pack[key].is_empty(), "Translation present: " + locale + "/" + key)
			check(expression.search_all(key).size() == expression.search_all(pack[key]).size(), "Formatting placeholders preserved")
	for pair in [["en_US", "en"], ["es_MX", "es_419"], ["es_ES", "es_419"], ["pt_PT", "pt_BR"], ["fr_FR", "pt_BR"]]:
		check(Localization.resolve("system", pair[0]) == pair[1], "Device locale mapping")
	check(Localization.resolve("en", "pt_BR") == "en", "Manual language overrides device")
	Localization.apply("es_419")
	check(Localization.resolve("es_419", "en_US") == "es_419" and TranslationServer.get_locale().begins_with("es") and tr("Nível %d") % 7 == "Nivel 7", "Latin American Spanish loads natively")
	Localization.apply("en")
	check(tr("Frascos trancados") == "Locked tubes", "Obstacle text is translated")
	var path := OS.get_environment("TEMP").path_join("arenis-localization-%d" % Time.get_ticks_usec())
	var app = load("res://scenes/main.tscn").instantiate()
	app.preferences = Preferences.new(path + ".prefs")
	app.preferences.language_mode = "pt_BR"
	app.preferences.basic_tutorial_seen = true
	app.preferences.theme_mode = "light"
	app.progress = Progress.new(path + ".progress")
	root.add_child(app)
	app._start(0)
	app._close_modal(false)
	await process_frame
	var board: Dictionary = app.game.snapshot()
	app._show_settings()
	app._change_language(2)
	await process_frame
	check(app.overlay.find_children("*", "Label", true, false).any(func(label): return label.text == "Settings"), "Settings rebuilt in English")
	check(app.find_children("*", "Label", true, false).any(func(label): return label.text == "Level 1"), "Level word is translated")
	check(app.game.snapshot() == board and app.game.history.is_empty(), "Language change preserves gameplay")
	check(Preferences.new(path + ".prefs").language_mode == "en", "Manual language persists")
	app._change_language(3)
	await process_frame
	check(app.overlay.find_children("*", "Label", true, false).any(func(label): return label.text == "Configuración"), "Settings rebuilt in Spanish")
	check(app.find_children("*", "Label", true, false).any(func(label): return label.text == "Nivel 1"), "Spanish level title is translated")
	check(app.banner.find_children("*", "Label", true, false)[0].text == "Espacio para anuncio", "Persistent chrome changes language")
	app._change_language(1)
	await process_frame
	check(app.game.snapshot() == board and TranslationServer.get_locale() == "pt_BR", "Returning to Portuguese preserves board")
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	for suffix in [".prefs", ".prefs.bak", ".progress", ".progress.bak"]:
		DirAccess.remove_absolute(path + suffix)
	print("LOCALIZATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
