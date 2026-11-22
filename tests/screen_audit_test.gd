extends SceneTree
const Progress = preload("res://scripts/progress.gd")
const Preferences = preload("res://scripts/preferences.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: _run.call_deferred()
func settle() -> void:
	for i in 4: await process_frame
func audit(app: Control, description: String) -> void:
	await settle()
	var scroll: ScrollContainer = app.overlay.find_child("ModalScroll",true,false)
	check(not scroll.get_h_scroll_bar().is_visible_in_tree(), description+": no horizontal scrolling")
	check(scroll.get_global_rect().position.y >= 0 and scroll.get_global_rect().end.y < app.banner.get_global_rect().position.y, description+": content fits above ad")
	var pinned = app.overlay.find_child("PinnedActions",true,false)
	if pinned != null:
		check(pinned.get_global_rect().end.y < app.banner.get_global_rect().position.y, description+": actions remain visible")
	if description in ["menu", "restart", "settings", "account", "result", "failure", "moves", "timed"] and app.size.y >= 900:
		check(not scroll.get_v_scroll_bar().is_visible_in_tree(), description+": no unnecessary scroll")
func _run() -> void:
	var path := OS.get_environment("TEMP").path_join("arenis-audit-%d" % Time.get_ticks_usec())
	var app = load("res://scenes/main.tscn").instantiate()
	app.progress=Progress.new(path+".progress");app.preferences=Preferences.new(path+".prefs")
	app.preferences.basic_tutorial_seen=true;app.preferences.language_mode="pt_BR";app.preferences.theme_mode="light"
	root.add_child(app)
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/relatorios/jornada-v3-provas.json"))
	for viewport in [Vector2i(540,960),Vector2i(540,800)]:
		root.size=viewport
		await settle()
		for locale in ["pt_BR","en","es_419"]:
			app.Localization.apply(locale)
			for dark in [false,true]:
				if app.dark_mode != dark: app._toggle_theme()
				app._show_levels();await settle()
				var map = app.find_child("JourneyMap",true,false)
				check(map.dark_mode==dark,"Map palette follows global theme")
				check(not app.find_child("CampaignMapScroll",true,false).get_h_scroll_bar().is_visible_in_tree(),"Map has only intentional vertical scrolling")
				for index in [0,30,75,140]:
					if index>0: app.progress.records[app.levels[index-1].id]={"version":1,"stars":1,"best_moves":50}
					app._start(index,true);app._close_modal(false);await settle()
					check(app.board.get_global_rect().end.y < app.banner.get_global_rect().position.y and app.board.get_global_rect().end.x <= app.size.x,"All board densities fit viewport and native banner")
				app._start(0,true);app._close_modal(false)
				for item in [["menu",app._show_level_menu],["restart",app._confirm_restart],["settings",app._show_settings],["account",app._show_services],["help",app._show_lesson],["practice",app._show_basic_tutorial.bind(false)]]:
					item[1].call();await audit(app,item[0]);app._close_modal(false)
				for kind in ["moves","timed","hidden","locked","combined"]:
					app._show_mechanic_intro(kind);await audit(app,kind);app._close_modal(false)
				for step in proof.results[0].solution: app.game.pour(step[0],step[1])
				app._refresh();app._show_result();await audit(app,"result");app._close_modal(false)
				app.game.restart();app.game.failed_reason="moves";app.failure_shown=false
				app._show_failure();await audit(app,"failure");app._close_modal(false)
	app.queue_free();await settle();await create_timer(.2).timeout
	print("SCREEN AUDIT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
