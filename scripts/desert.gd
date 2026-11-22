extends Control
## Quiet vector dunes. No textures, downloads or random per-frame work.
var dark_mode := false:
	set(value):
		dark_mode = value
		queue_redraw()
var subdued := false:
	set(value):
		subdued = value
		queue_redraw()
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var sky := Color("182d38") if dark_mode else Color("f5f0e6")
	var horizon := Color("283c43") if dark_mode else Color("f8f5ee")
	for band in 24:
		var y := size.y * band / 24.0
		draw_rect(Rect2(0, y, size.x, size.y / 24.0 + 1), sky.lerp(horizon, band / 23.0))
	var opacity := 0.24 if subdued else 0.65
	var sun := Vector2(size.x * .83, size.y * .21)
	draw_circle(sun, 24, Color("b2c1c4", opacity * .13) if dark_mode else Color("d8bd88", opacity * .25))
	if dark_mode:
		for point in [Vector2(.17,.13),Vector2(.35,.23),Vector2(.68,.12),Vector2(.89,.32)]:
			draw_circle(point * size, 1.1, Color(0.8, 0.86, 0.85, opacity * .35))
	var shades := [Color("b9a783"),Color("ccb99a"),Color("e2d4bb")] if not dark_mode else [Color("36454b"),Color("3c4e51"),Color("435953")]
	for layer in 3:
		var points := PackedVector2Array()
		for i in 65:
			var x := i * size.x / 64.0
			var y := size.y * (.65 + layer * .12) + sin(i / 64.0 * 4.5 + layer * 1.9) * (45 - layer * 7)
			points.append(Vector2(x,y))
		points.append(Vector2(size.x,size.y));points.append(Vector2(0,size.y))
		draw_colored_polygon(points, Color(shades[layer], opacity * (.25 + layer * .15)))
