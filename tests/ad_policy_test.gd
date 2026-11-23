extends SceneTree
const State = preload("res://scripts/service_state.gd")
const Services = preload("res://scripts/android_services.gd")
var checks := 0
var failures := 0
class UnwritableState extends "res://scripts/service_state.gd":
	func _save(_count: int, _enabled: bool, _anchor: int) -> Error:
		return ERR_FILE_CANT_WRITE
class FakeNative extends RefCounted:
	var reads := 0
	var requests := 0
	func read_cloud() -> void: reads += 1
	func show_interstitial() -> void: requests += 1
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var path := OS.get_environment("TEMP").path_join("arenis-ad-policy-%d" % Time.get_ticks_usec())
	var clock := {"now":1000}
	var read_clock := func(): return clock.now
	var state := State.new(path+".state",read_clock)
	check(FileAccess.file_exists(path+".state"),"First-use grace period is persisted immediately")
	for number in range(1,11):
		check(state.completed(number)==OK and state.completions==0,"Introductory completion never adds advertising debt")
		check(not state.can_show_interstitial(number),"Every introductory level is exempt")
	clock.now=1300
	check(not state.can_show_interstitial(11),"Time alone cannot request an ad")
	clock.now=1000
	for i in 4: state.completed(11)
	clock.now=1300
	check(not state.can_show_interstitial(11),"Four completions remain below threshold even after five minutes")
	clock.now=1299;state.completed(11)
	check(not state.can_show_interstitial(11),"Five completions cannot bypass the 300-second boundary")
	clock.now=1300
	check(state.can_show_interstitial(11),"Both conditions allow an ad at exactly five minutes")
	for number in [0,1,10]:
		check(not state.can_show_interstitial(number),"Exemption still applies when an ad is otherwise due")
	var restored := State.new(path+".state",read_clock)
	check(restored.completions==5 and restored.can_show_interstitial(11),"Counter and elapsed grace survive restart")
	for i in 20: state.completed(11)
	check(state.completions==5,"Offline completions accumulate at most one opportunity")
	state.set_cloud_enabled(true)
	restored=State.new(path+".state",read_clock)
	check(restored.completions==5 and restored.cooldown_started_unix==1000 and restored.cloud_enabled,"Cloud setting does not reset advertising limits")
	state.consume_ad_break()
	check(state.completions==0 and state.cooldown_started_unix==1300,"Actual impression restarts both conditions")
	for i in 5: state.completed(11)
	clock.now=1599;restored=State.new(path+".state",read_clock)
	check(not restored.can_show_interstitial(11),"Restart cannot bypass the last impression cooldown")
	clock.now=1600
	check(restored.can_show_interstitial(11),"A later ad needs five new completions and five minutes")
	clock.now=1200
	check(not restored.can_show_interstitial(11),"A backward clock change cannot cause an early ad")
	var legacy := ConfigFile.new()
	legacy.set_value("ads","completions",2);legacy.set_value("cloud","enabled",true)
	legacy.save(path+".legacy")
	clock.now=2000
	var migrated := State.new(path+".legacy",read_clock)
	check(migrated.cloud_enabled and migrated.completions==0 and migrated.cooldown_started_unix==2000,"Legacy two-level debt is discarded, preserving cloud choice")
	clock.now=2100
	check(State.new(path+".legacy",read_clock).cooldown_started_unix==2000,"Migration grace is not restarted on every launch")
	var broken := ConfigFile.new()
	broken.set_value("ads","policy_version",2);broken.set_value("ads","completions",5);broken.set_value("ads","cooldown_started_unix","bad")
	broken.set_value("cloud","enabled",true);broken.save(path+".broken")
	var recovered := State.new(path+".broken",read_clock)
	check(recovered.completions==0 and recovered.cooldown_started_unix==2100 and recovered.cloud_enabled,"Malformed cooldown fails conservatively without resetting cloud preference")
	var unwritable := UnwritableState.new(path+".unwritable",read_clock)
	unwritable.completions=5;unwritable.cooldown_started_unix=1000
	check(unwritable.can_show_interstitial(11),"Storage-failure fixture is initially eligible")
	check(unwritable.consume_ad_break()!=OK and not unwritable.can_show_interstitial(11) and unwritable.cooldown_started_unix==2100,"An impression still enforces in-memory cooldown if its save fails")
	# Exemption only affects full-screen ads, not automatic synchronization.
	var services := Services.new()
	services.state=State.new(path+".services",read_clock)
	services.state.set_cloud_enabled(true)
	root.add_child(services)
	var native := FakeNative.new();services.native=native
	services.cloud_available=true;services.cloud_connected=true
	services.completed({"number":1})
	check(services.state.completions==0 and native.reads==1,"Protected completions still trigger automatic cloud sync")
	services.syncing=false
	services.queue_free();await process_frame
	# Exercise actual UI entry points with an otherwise eligible native adapter.
	var app = load("res://scenes/main.tscn").instantiate()
	app.progress=load("res://scripts/progress.gd").new(path+".ui")
	app.preferences=load("res://scripts/preferences.gd").new(path+".prefs")
	app.preferences.basic_tutorial_seen=true
	root.add_child(app)
	app.services.state=State.new(path+".ui.policy",read_clock)
	var app_native := FakeNative.new();app.services.native=app_native
	for i in 5: app.services.state.completed(11)
	clock.now+=300
	app.progress.records[app.levels[9].id]={"version":1,"stars":1,"best_moves":10}
	app._start(10,true);app._close_modal(false)
	app._show_level_menu();app._confirm_restart();app._show_lesson();app._restart()
	check(app_native.requests==0 and app.services.state.completions==5,"Menu, help and restart never request or build a full-screen ad")
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/relatorios/jornada-v3-provas.json"))
	for step in proof.results[10].solution: app.game.pour(step[0],step[1])
	app._save_attempt();app._show_result()
	check(app.game.won() and app_native.requests==0,"An eligible completion still waits on the result screen")
	app._after_result(app._show_levels)
	check(app_native.requests==1 and app.services.ad_waiting,"Leaving an eligible result is the only full-screen request point")
	app.services._interstitial_state("shown");app.services._interstitial_state("closed")
	await process_frame
	check(app.screen=="levels" and app.services.state.completions==0,"Closing the shown ad releases navigation and resets cadence")
	for i in 5: app.services.state.completed(11)
	clock.now+=300
	app._start(0,true);app._close_modal(false)
	for step in proof.results[0].solution: app.game.pour(step[0],step[1])
	app._save_attempt();app._show_result();app._after_result(app._show_levels)
	check(app_native.requests==1 and app.screen=="levels" and app.services.state.completions==5,"Protected result never shows an ad, even with mature debt and cooldown")
	app.queue_free();await process_frame;await create_timer(.2).timeout
	for suffix in [".state",".legacy",".broken",".services",".unwritable",".ui",".prefs",".ui.services",".ui.policy"]:
		for extra in ["",".bak"]: DirAccess.remove_absolute(path+suffix+extra)
	print("AD POLICY: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
