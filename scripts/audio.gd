extends Node
const SAND_RELEASE_SECONDS := 0.5
var preferences: RefCounted
var sand := AudioStreamPlayer.new()
var tap := AudioStreamPlayer.new()
var complete := AudioStreamPlayer.new()
var fade: Tween
var sand_releasing := false
var sand_gain := 1.0:
	set(value):
		sand_gain = clampf(value, 0, 1)
		_apply_sand_gain()

func _ready() -> void:
	for player in [sand, tap, complete]:
		add_child(player)
	sand.stream = load("res://assets/audio/sand.wav")
	tap.stream = load("res://assets/audio/tap.wav")
	complete.stream = load("res://assets/audio/complete.wav")
	apply_preferences()

func apply_preferences() -> void:
	if not sand.is_inside_tree():
		return
	var db := linear_to_db(maxf(0.0001, preferences.effects_volume))
	for player in [tap, complete]:
		player.volume_db = db
		if not preferences.effects_enabled:
			player.stop()
	_apply_sand_gain()
	if not preferences.effects_enabled:
		if is_instance_valid(fade):
			fade.kill()
		sand.stop()
		sand_releasing = false

func begin_sand() -> void:
	if is_instance_valid(fade):
		fade.kill()
	sand_releasing = false
	sand_gain = 1.0
	if preferences.effects_enabled:
		sand.play()

func update_sand_flow(progress: float) -> void:
	if not sand.playing or sand_releasing:
		return
	# The stream tapers as the last part leaves the source and arrives in the target.
	sand_gain = lerpf(1.0, 0.55, smoothstep(0.45, 0.90, clampf(progress, 0, 1)))

func end_sand() -> void:
	if sand.playing and not sand_releasing:
		sand_releasing = true
		fade = create_tween()
		# Fade linear amplitude, avoiding a steep dB drop perceived as an immediate cut.
		fade.tween_property(self, "sand_gain", 0.0, SAND_RELEASE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fade.tween_callback(sand.stop)
		fade.tween_callback(func(): sand_releasing = false)

func _apply_sand_gain() -> void:
	if preferences != null and sand.is_inside_tree():
		sand.volume_db = linear_to_db(maxf(0.0001, preferences.effects_volume * sand_gain))

func play_tap() -> void:
	if preferences.effects_enabled:
		tap.play()

func play_complete() -> void:
	if preferences.effects_enabled:
		complete.play()

func _exit_tree() -> void:
	if is_instance_valid(fade):
		fade.kill()
	for player in [sand, tap, complete]:
		player.stop()
		player.stream = null
