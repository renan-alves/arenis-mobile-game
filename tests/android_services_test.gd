extends SceneTree
const Cloud = preload("res://scripts/cloud_records.gd")
const Progress = preload("res://scripts/progress.gd")
const Rules = preload("res://scripts/rules.gd")
const State = preload("res://scripts/service_state.gd")
const Services = preload("res://scripts/android_services.gd")
var checks := 0
var failures := 0
var continuations := 0
class FakeNative extends RefCounted:
	var requests := 0
	var cancels := 0
	var reads := 0
	var connections := 0
	var diagnostic := ""
	var writes := []
	func show_interstitial() -> void: requests += 1
	func cancel_interstitial() -> void: cancels += 1
	func read_cloud() -> void: reads += 1
	func write_cloud(payload: String) -> void: writes.append(payload)
	func cancel_cloud() -> void: cancels += 1
	func connect_games() -> void: connections += 1
	func get_cloud_diagnostic() -> String: return diagnostic
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func payload(items: Array) -> String:
	return JSON.stringify({"schema_version": 2, "results": items})
func result(id := "level-001", stars := 2, moves := 8, version := 1) -> Dictionary:
	return {"id": id, "version": version, "rules_version": 3, "stars": stars, "best_moves": moves}
func continued() -> void: continuations += 1
func _run() -> void:
	var path := OS.get_environment("TEMP").path_join("arenis-android-test-%d" % Time.get_ticks_usec())
	var a := payload([result()])
	var b := payload([result("level-001", 3, 6), result("level-051", 1, 25, 2)])
	var c := payload([result("level-101", 2, 30, 1)])
	var merged := Cloud.merge(a, b)
	check(merged.ok and Cloud.decode(merged.payload).results["level-001@1@3"].stars == 3, "Merge retains maximum stars")
	check(Cloud.decode(merged.payload).results["level-001@1@3"].best_moves == 6, "Merge retains lowest move count")
	check(merged.payload == Cloud.merge(b, a).payload, "Merge is commutative")
	check(Cloud.merge(merged.payload, merged.payload).payload == merged.payload, "Merge is idempotent")
	check(Cloud.merge(merged.payload, c).payload == Cloud.merge(a, Cloud.merge(b, c).payload).payload, "Merge is associative")
	check(Cloud.decode(Cloud.merge(a, "").payload).results.size() == 1, "Empty new snapshot keeps local results")
	for invalid in ["{broken", "[]", '{"schema_version":99,"results":[]}', payload([result("x", 4)]), payload([result("x", 1, 0)]), payload([result("../bad")]), payload([{"id": "x"}]), " ".repeat(1048577)]:
		check(not Cloud.merge(a, invalid).ok, "Malformed or oversized cloud save rejected")
	var fractional := result()
	fractional.best_moves = 2.5
	check(not Cloud.decode(payload([fractional])).ok, "Fractional moves rejected")
	var levels: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json")).levels
	var progress := Progress.new(path + ".progress")
	var game := Rules.new(levels[0])
	var first_step: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/relatorios/jornada-v3-provas.json")).results[0].solution[0]
	game.pour(first_step[0], first_step[1])
	progress.complete(levels[50], 1, 25)
	progress.save_attempt(levels[0], game)
	var attempts := progress.attempts.duplicate(true)
	check(progress.merge_cloud(merged.payload, levels) == OK, "Cloud merge commits to local storage")
	check(progress.record(levels[0]).stars == 3 and progress.record(levels[0]).best_moves == 6, "Current board receives remote records")
	check(progress.attempts == attempts, "Cloud merge preserves active attempt and undo journal")
	check(progress.merge_cloud(payload([result("level-052", 3, 3, 2)]), levels) == OK and progress.record(levels[51]).is_empty(), "Old board revision cannot acquire current stars")
	check(progress.export_cloud().contains('level-052') and progress.archived_records.size() >= 1, "Old revision remains in cloud archive")
	var before := progress.export_cloud()
	check(progress.merge_cloud("oops", levels) == ERR_INVALID_DATA and progress.export_cloud() == before, "Bad remote data cannot overwrite local progress")
	check(Progress.new(path + ".progress").export_cloud() == before, "Merged results persist after reopening")
	check(not before.contains('actions') and not before.contains('preferences'), "Cloud export excludes attempts and preferences")
	var old_rules := result("level-002", 3, 1)
	old_rules.rules_version = 1
	progress.merge_cloud(payload([old_rules]), levels)
	check(progress.record(levels[1]).is_empty() and progress.archived_records.has("level-002@1@1"), "Different rules cannot unlock a current level")
	var state := State.new(path + ".state")
	check(state.completions == 0 and not state.cloud_enabled, "Cloud is opt-in and cadence starts empty")
	state.completed()
	check(state.completions == 1, "First completion does not reach ad cadence")
	state.completed()
	check(State.new(path + ".state").completions == 2, "Ad cadence persists across app sessions")
	state.completed()
	check(state.completions == 2, "Offline completions cannot accumulate multiple ad breaks")
	state.set_cloud_enabled(true)
	check(State.new(path + ".state").cloud_enabled, "Cloud choice persists")
	state.consume_ad_break()
	check(state.completions == 0 and state.cloud_enabled, "Displayed ad resets cadence without changing sync")
	var services := Services.new()
	services.state = State.new(path + ".services")
	services.progress = progress
	services.levels = levels
	root.add_child(services)
	services.transition(continued)
	check(continuations == 1, "No native SDK never blocks navigation")
	var native := FakeNative.new()
	services.native = native
	services.completed()
	services.transition(continued)
	check(continuations == 2 and native.requests == 0, "One completion does not request interstitial")
	services.completed()
	services.transition(continued)
	check(native.requests == 1 and continuations == 2, "Ad requested only at transition after two completions")
	services.transition(continued)
	check(native.requests == 1, "Repeated tap cannot schedule a second ad")
	services._interstitial_state("unavailable")
	await process_frame
	check(continuations == 3 and services.state.completions == 2, "Unavailable ad continues without consuming cadence")
	services._interstitial_state("closed")
	await process_frame
	check(continuations == 3, "Late duplicate callback cannot navigate again")
	services.transition(continued)
	services._interstitial_state("shown")
	check(services.state.completions == 0 and continuations == 3, "Only shown event consumes cadence")
	services._process(5)
	check(continuations == 3, "Navigation waits while full-screen ad is showing")
	services._interstitial_state("closed")
	await process_frame
	check(continuations == 4, "Closing ad continues once")
	services.completed()
	services.completed()
	services.transition(continued)
	services._process(4)
	await process_frame
	check(continuations == 5 and native.cancels == 1, "Stalled request cancels native display and releases navigation")
	services.cloud_available = true
	services.enable_cloud(true)
	check(native.connections == 1 and services.cloud_connecting and native.reads == 0, "Opt-in waits for authentication before reading snapshots")
	services._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	services.request_sync()
	check(native.reads == 0 and native.connections == 1, "Resume during Google login neither reads nor opens a duplicate login")
	native.diagnostic = "sign_in / status=10"
	services._cloud_state("failed")
	check(not services.cloud_connecting and not services.cloud_connected and services.cloud_diagnostic == native.diagnostic, "Failed authentication exposes sanitized diagnostic and clears connection")
	check(services.cloud_feedback().contains(native.diagnostic) == OS.is_debug_build(), "Technical failure details are visible only in debug builds")
	services.cloud_debug_details = false
	check(not services.cloud_feedback().contains(native.diagnostic), "Release mode hides diagnostic even when the test engine is a debug build")
	services.cloud_debug_details = OS.is_debug_build()
	services.request_sync()
	check(native.connections == 2 and native.reads == 0 and services.cloud_diagnostic.is_empty(), "Manual retry repeats authentication instead of reading an unauthenticated snapshot")
	services._cloud_state("connected")
	check(native.reads == 1 and services.syncing, "Opt-in connection starts one snapshot read")
	services.request_sync()
	check(native.reads == 1 and services.dirty, "Concurrent syncs queue instead of opening multiple snapshots")
	services._cloud_snapshot(c, "")
	check(native.writes.size() == 1 and progress.record(levels[100]).stars == 2, "Remote snapshot merges before commit")
	services._cloud_state("saved")
	await process_frame
	check(native.reads == 2, "Changes during sync cause another read")
	services.enable_cloud(false)
	services._cloud_snapshot(a, b)
	check(not services.syncing and native.writes.size() == 1, "Opt-out stops pending upload")
	services.enable_cloud(true)
	services._cloud_state("connected")
	services._cloud_snapshot("corrupt", "")
	check(not services.syncing and native.writes.size() == 1 and progress.record(levels[100]).stars == 2, "Corrupt cloud cancels upload and keeps local results")
	services._cloud_state("connected")
	services._process(31)
	check(not services.syncing and services.cloud_status.begins_with("Não foi possível"), "Stalled cloud request times out without blocking gameplay")
	check(not services.cloud_connected, "Timed-out snapshot invalidates connection for the next retry")
	services.request_sync()
	check(services.cloud_connecting and not services.syncing, "Retry after a failed snapshot checks authentication again")
	services._process(121)
	check(not services.cloud_connecting and services.cloud_diagnostic == "connection_timeout", "Stalled authentication releases its pending state and reports a timeout")
	var reads_before_disable := native.reads
	services.enable_cloud(false)
	services._cloud_state("connected")
	services._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not services.cloud_connected and native.reads == reads_before_disable, "Opt-out ignores late connection and resume callbacks")
	services.queue_free()
	await process_frame
	print("ANDROID SERVICES: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
