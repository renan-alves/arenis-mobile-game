extends Control
## Cosmetic event consumer. Never reads or changes puzzle state.
const Identity = preload("res://scripts/identity.gd")
var dark_mode := false
var motion_enabled := true
var activity := "idle"
var gaze := Vector2.ZERO
var target_gaze := Vector2.ZERO
var hold_remaining := 0.0
var blink_remaining := 0.0
var next_blink := 3.6
var clock := 0.0
var eyes_open := 1.0
var body: Texture2D
var eye_style := StyleBoxFlat.new()

func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(Vector2(64, 64))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye_style.set_corner_radius_all(4)
	set_dark_mode(dark_mode)
	resized.connect(queue_redraw)

func set_dark_mode(dark: bool) -> void:
	dark_mode = dark
	body = load("res://assets/branding/mascot-body-%s.svg" % ("dark" if dark else "light"))
	eye_style.bg_color = Identity.colors(dark).text
	queue_redraw()

func look_at_point(point: Vector2, duration := 1.8, event := "selection") -> void:
	var center := get_global_rect().get_center()
	var delta := point - center
	target_gaze = Vector2(clampf(delta.x / 45.0, -5.5, 5.5), clampf(delta.y / 65.0, -4, 5))
	hold_remaining = duration
	activity = event
	if not motion_enabled:
		gaze = target_gaze
	queue_redraw()

func rest() -> void:
	activity = "idle"
	hold_remaining = 0.0
	target_gaze = Vector2.ZERO

func blink() -> void:
	blink_remaining = 0.22
	queue_redraw()

func celebrate() -> void:
	activity = "win"
	target_gaze = Vector2(0, -1)
	hold_remaining = 1.3
	next_blink = 0.65

func set_motion_enabled(enabled: bool) -> void:
	motion_enabled = enabled
	if not enabled:
		blink_remaining = 0
		eyes_open = 1
		if activity == "idle":
			target_gaze = Vector2.ZERO
		gaze = target_gaze
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	hold_remaining = maxf(0, hold_remaining - delta)
	if hold_remaining == 0:
		activity = "idle"
		target_gaze = Vector2(sin(clock / 3.1) * 2.2, cos(clock / 4.7) * 1.2) if motion_enabled else Vector2.ZERO
	if motion_enabled:
		next_blink -= delta
		if next_blink <= 0:
			blink()
			next_blink = 4.2 + sin(clock) * 0.6
	blink_remaining = maxf(0, blink_remaining - delta)
	eyes_open = maxf(0.08, absf(blink_remaining - 0.11) / 0.11) if blink_remaining > 0 else 1.0
	gaze = gaze.lerp(target_gaze, 1 - exp(-delta / 0.13)) if motion_enabled else target_gaze
	queue_redraw()

func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2.ONE * side) / 2
	if body != null:
		draw_texture_rect(body, Rect2(origin, Vector2.ONE * side), false)
	var scale_factor := side / 128.0
	var height := 17 * eyes_open * (1.06 if activity == "win" else 1.0)
	for x in [48.0, 72.5]:
		var point := origin + (Vector2(x, 66.5 - height / 2) + gaze) * scale_factor
		draw_style_box(eye_style, Rect2(point, Vector2(7.5, height) * scale_factor))
