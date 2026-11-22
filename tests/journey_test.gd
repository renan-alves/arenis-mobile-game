extends SceneTree
const Rules = preload("res://scripts/rules.gd")
const Progress = preload("res://scripts/progress.gd")
const Preferences = preload("res://scripts/preferences.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
const Solver = preload("res://scripts/solver.gd")
const Cloud = preload("res://scripts/cloud_records.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func fixture() -> Dictionary:
	return {"capacity":3,"minimum_moves":2,"bottles":[{"colors":["coral","aqua","aqua"]},{"colors":["aqua"]},{"colors":["coral","coral"]}]}
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var game := Rules.new(fixture())
	check(game.transfer_count(0,2)==0 and game.moves==0,"Different top color rejects a pour without spending moves")
	check(game.transfer_count(0,1)==2,"Same top color accepts the whole contiguous block")
	var partial := Rules.new({"capacity":3,"bottles":[{"colors":["coral","coral"]},{"colors":["coral","coral"]}, {"colors":[]}]})
	check(partial.transfer_count(0,1)==1 and partial.transfer_count(0,2)==2,"Partial capacity and empty helpers remain legal")
	var bounded := fixture();bounded.move_limit=1
	game=Rules.new(bounded);game.pour(0,1)
	check(game.failed_reason=="moves" and game.pour(0,2).is_empty(),"An exhausted move budget ends the attempt")
	bounded.move_limit=2;game=Rules.new(bounded);game.pour(0,1);game.pour(0,2)
	check(game.won() and game.failed_reason.is_empty(),"Winning on the final allowed move has priority over failure")
	game=Rules.new(bounded);game.pour(0,1);game.undo()
	check(game.moves==2 and game.failed_reason=="moves","Undo spends a move and can exhaust the budget")
	var timed := fixture();timed.time_limit=10
	game=Rules.new(timed);game.advance_time(30);game.pour(0,2)
	check(game.elapsed_seconds==0 and not game.timer_started,"Planning before the first valid move is free")
	game.pour(0,1);game.advance_time(3.5);game.undo()
	check(is_equal_approx(game.elapsed_seconds,3.5) and game.timer_started,"Undo never refunds elapsed time")
	var path := OS.get_environment("TEMP").path_join("arenis-journey-%d" % Time.get_ticks_usec())
	var profile := Progress.new(path+".cfg")
	var timed_level := timed.duplicate(true)
	timed_level.merge({"id":"level-001","version":1,"difficulty_id":"journey"},true)
	check(profile.save_attempt(timed_level,game)==OK,"Elapsed time is checkpointed with the action journal")
	var restored = Progress.new(path+".cfg").restore_attempt(timed_level)
	check(restored!=null and is_equal_approx(restored.elapsed_seconds,3.5) and restored.moves==2,"Reopening preserves time, moves and undo state")
	restored.advance_time(7)
	check(restored.failed_reason=="time" and restored.remaining_seconds()==0,"Active time expires deterministically")
	check(not Cloud.decode('{"schema_version":1,"results":[]}').ok,"Legacy cloud documents cannot enter the new namespace")
	var loaded := Catalog.load_file("res://data/campaign.json")
	check(loaded.ok,"New campaign validates strictly")
	if not loaded.ok:
		printerr(loaded.errors);quit(1);return
	var proof: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/relatorios/jornada-v3-provas.json"))
	check(proof.accepted and loaded.pack.levels.size()==150,"All 150 levels have independent minimum certificates")
	var modes := {};var locked_count := 0;var hidden_count := 0
	for i in loaded.pack.levels.size():
		var level: Dictionary = loaded.pack.levels[i]
		var certificate: Dictionary = proof.results[i]
		check(level.number==i+1 and level.difficulty_id=="journey","One continuous numbered campaign")
		check(certificate.fingerprint==Solver.fingerprint(level) and certificate.minimum_moves==level.minimum_moves,"Certificate matches the exact current board and constraints")
		game=Rules.new(level)
		for step in certificate.solution:
			check(not game.pour(int(step[0]),int(step[1])).is_empty(),"Every certified move is legal under the strict color rule")
		check(game.won() and game.failed_reason.is_empty(),"Certified solution wins within the move budget")
		modes[level.mode]=int(modes.get(level.mode,0))+1
		for bottle in level.bottles:
			locked_count+=int(bottle.has("unlock_color"));hidden_count+=int(not bottle.get("hidden",[]).is_empty())
		check(not(level.move_limit>0 and level.time_limit>0),"Move and time limits alternate instead of overlapping")
	check(modes.size()==3 and modes.timed>=10 and locked_count>0 and hidden_count>0,"Campaign includes free, move and timed challenges plus both obstacles")
	var app = load("res://scenes/main.tscn").instantiate()
	app.progress=Progress.new(path+".ui");app.preferences=Preferences.new(path+".prefs")
	app.preferences.basic_tutorial_seen=true;app.preferences.theme_mode="light";app.preferences.language_mode="pt_BR"
	root.add_child(app);await process_frame;await process_frame
	check(app.find_child("JourneyMap",true,false)!=null,"Home opens directly on the campaign map")
	check(app.find_child("PlayCurrentLevel",true,false).text.contains("Nível 1"),"Primary action points at the next playable level")
	check(app._is_unlocked(0) and not app._is_unlocked(1),"Campaign unlocks sequentially from level one")
	app._show_settings();await process_frame;await process_frame
	var scroll: ScrollContainer = app.overlay.find_child("ModalScroll",true,false)
	check(not scroll.get_h_scroll_bar().is_visible_in_tree(),"Settings never scroll horizontally")
	check(not scroll.get_v_scroll_bar().is_visible_in_tree(),"Normal settings fit without unnecessary vertical scroll")
	app._show_services();await process_frame;await process_frame
	scroll=app.overlay.find_child("ModalScroll",true,false)
	check(not scroll.get_v_scroll_bar().is_visible_in_tree(),"Account settings fit without unnecessary scrolling")
	app._close_modal(false)
	for i in 47:
		app.progress.complete(app.levels[i],3,int(app.levels[i].minimum_moves))
	app._start(47,true)
	check(is_instance_valid(app.overlay),"First timed level has a dedicated explanation")
	app._dismiss_mechanic_intro("timed");app._close_modal(false)
	var step: Array = proof.results[47].solution[0]
	app.game.pour(int(step[0]),int(step[1]));app._refresh()
	app._process(2.0);var elapsed: float=app.game.elapsed_seconds
	app._show_services();app._process(5.0)
	check(is_equal_approx(app.game.elapsed_seconds,elapsed),"Opening menus pauses the countdown")
	app._close_modal(false);app.busy=true;app._process(5.0);app.busy=false
	check(is_equal_approx(app.game.elapsed_seconds,elapsed),"Pour animations do not spend countdown time")
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED);app._process(20.0)
	check(is_equal_approx(app.game.elapsed_seconds,elapsed),"Background time is not charged")
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED);app._process(100.0)
	check(is_equal_approx(app.game.elapsed_seconds,elapsed),"The first resume frame cannot charge a background gap")
	app._process(1.0)
	check(is_equal_approx(app.game.elapsed_seconds,elapsed+1),"Countdown resumes during active play")
	app._show_lesson();await process_frame
	check(app.overlay.find_child("PinnedActions",true,false)!=null,"Help keeps its acknowledgement actions outside the scrolling text")
	app.queue_free();await process_frame;await create_timer(.2).timeout
	print("JOURNEY: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
