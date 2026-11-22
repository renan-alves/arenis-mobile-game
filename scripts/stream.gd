extends Control
const Identity = preload("res://scripts/identity.gd")

var source := Vector2.ZERO
var target := Vector2.ZERO
var color := Color.WHITE
var progress := 0.0
var dark_mode := false
var color_id := ""

func set_dark_mode(dark: bool) -> void:
	dark_mode = dark
	if not color_id.is_empty():
		color = Identity.sand_color(color_id, dark)
	queue_redraw()

func point_at(t: float) -> Vector2:
	# The source tube moves beside the destination before the sand starts falling.
	return source.lerp(target, t) + Vector2(0, -sin(t * PI) * 22)

func _draw() -> void:
	if not visible:
		return
	for i in 90:
		var emitted_at := float(i) / 89.0 * 0.78
		var t := clampf((progress - emitted_at) / 0.22, 0, 1)
		if t <= 0 or t >= 1:
			continue
		var point := point_at(t) + Vector2(sin(i * 2.4) * 2.5, cos(i * 1.7) * 1.5)
		var grain_color := color
		grain_color.a *= smoothstep(0.0, 0.08, t) * (1 - smoothstep(0.9, 1.0, t))
		var outline := Color("e3ece5" if dark_mode else "354e50", grain_color.a * (0.16 if dark_mode else 0.32))
		draw_circle(point, 2.9, outline)
		draw_circle(point, 2.1, grain_color)
