extends Control

signal tapped(index: int)
signal origin_requested(index: int)
const Identity = preload("res://scripts/identity.gd")
const TOP_PADDING := 26.0
const BOTTOM_PADDING := 6.0
const SYMBOLS := {"coral": "●", "aqua": "≈", "gold": "◆", "lilac": "+", "sky": "▲", "sage": "■", "rose": "○", "peach": "≡", "indigo": "×", "mint": "✦"}
var symbols_enabled := false
var dark_mode := false
var index := 0
var units: Array = []
var known: Dictionary = {}
var capacity := 3
var locked := false
var unlock_color := ""
var selected := false
var valid_target := false
var interactive := true
var tube_height := 252.0
var fill_units := -1.0
var hold_timer := Timer.new()
var long_pressed := false
var selection_strength := 0.0:
	set(value):
		selection_strength = value
		queue_redraw()
var selection_tween: Tween
var pour_offset := Vector2.ZERO
var pour_angle := 0.0

func set_selected(value: bool) -> void:
	if selected == value:
		return
	selected = value
	if is_instance_valid(selection_tween):
		selection_tween.kill()
	selection_tween = create_tween()
	selection_tween.tween_property(self, "selection_strength", 1.0 if value else 0.0, 0.16).set_trans(Tween.TRANS_SINE)

func visual_transform() -> Transform2D:
	var pivot := Vector2(size.x / 2, TOP_PADDING + tube_height)
	return Transform2D(pour_angle, pivot + pour_offset + Vector2(0, -4 * selection_strength)) * Transform2D(0, -pivot)

func mouth_position() -> Vector2:
	return global_position + visual_transform() * Vector2(size.x / 2, TOP_PADDING)

func _ready() -> void:
	custom_minimum_size = Vector2(88, tube_height + TOP_PADDING + BOTTOM_PADDING)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = tr("Tubo %d") % (index + 1)
	resized.connect(queue_redraw)
	hold_timer.one_shot = true
	hold_timer.wait_time = 0.4
	add_child(hold_timer)
	hold_timer.timeout.connect(func():
		if interactive:
			long_pressed = true
			origin_requested.emit(index))

func _gui_input(event: InputEvent) -> void:
	if interactive and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			long_pressed = false
			hold_timer.start()
		else:
			hold_timer.stop()
			if not long_pressed:
				tapped.emit(index)
		accept_event()
	elif event is InputEventMouseMotion and hold_timer.time_left > 0 and event.relative.length() > 12:
		hold_timer.stop()

func _draw() -> void:
	draw_set_transform_matrix(visual_transform())
	var colors := Identity.colors(dark_mode)
	var palette := Identity.sand_palette(dark_mode)
	var width := 52.0
	var left := (size.x - width) / 2
	var top := TOP_PADDING
	var bottom := top + tube_height
	var radius := width / 2
	var border: Color = colors.control
	if selection_strength > 0:
		var marker := PackedVector2Array([Vector2(size.x / 2 - 4, top - 13), Vector2(size.x / 2, top - 9), Vector2(size.x / 2 + 4, top - 13)])
		draw_polyline(marker, Color(colors.text, selection_strength), 1.4, true)
	draw_set_transform_matrix(visual_transform())
	draw_colored_polygon(_band(top, bottom, left, width, bottom, radius), Color(colors.surface, .16 if dark_mode else .25))
	var shadow := PackedVector2Array()
	for i in 33:
		var angle := TAU*i/32.0
		shadow.append(Vector2(size.x/2+cos(angle)*width*.52,bottom+3+sin(angle)*2))
	draw_colored_polygon(shadow,Color(0.05,0.12,0.13,.08))
	var inner_left := left + 3
	var inner_width := width - 6
	var inner_bottom := bottom - 3
	var inner_radius := inner_width / 2
	var unit_height := (inner_bottom - top - 4) / capacity
	for j in units.size():
		var fraction := clampf(fill_units - j, 0, 1) if fill_units >= 0 else 1.0
		if fraction * unit_height < 0.08:
			continue
		var token: Dictionary = units[j]
		var color: Color = palette[token.color] if known.has(token.id) else colors.hidden
		var y0 := inner_bottom - (j + fraction) * unit_height
		var y1 := inner_bottom - j * unit_height
		draw_colored_polygon(_band(y0, y1, inner_left, inner_width, inner_bottom, inner_radius), color)
		for grain in 10:
			var gy := lerpf(y0, y1, 0.08 + fmod(float(grain * 13 + j * 7), 97) / 97 * 0.84)
			var span := _span(gy, inner_left, inner_width, inner_bottom, inner_radius)
			if span.y - span.x > 4:
				var gx := span.x + 2 + fmod(float(grain * 31 + j * 17), span.y - span.x - 4)
				draw_circle(Vector2(gx, gy), 0.65, Color(1, 1, 1, 0.12 if dark_mode else 0.22))
		var symbol := _symbol_for(token)
		if not symbol.is_empty():
			var font := get_theme_font("font", "Label")
			var text_width := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_string(font, Vector2(size.x / 2 - text_width / 2, (y0 + y1) / 2 + 5), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Identity.sand_symbol_color(dark_mode))
	var outline := PackedVector2Array([Vector2(left, top), Vector2(left, bottom - radius)])
	for i in 25:
		var angle := PI - float(i) / 24 * PI
		outline.append(Vector2(left + radius + cos(angle) * radius, bottom - radius + sin(angle) * radius))
	outline.append(Vector2(left + width, top))
	draw_polyline(outline, border, 1.4, true)
	var rim := PackedVector2Array()
	for i in 33:
		var angle := TAU*i/32.0
		rim.append(Vector2(left+width/2+cos(angle)*(width/2+2),top+sin(angle)*2.4))
	draw_polyline(rim,Color(border,.8),1.1,true)
	draw_line(Vector2(left+5,top+11),Vector2(left+5,bottom-radius-5),Color(1,1,1,.22 if dark_mode else .7),2.2,true)
	draw_line(Vector2(left+width-5,top+14),Vector2(left+width-5,bottom-radius+2),Color(1,1,1,.10 if dark_mode else .35),1.2,true)
	draw_arc(Vector2(left+radius,bottom-radius),radius-4,.18,PI-.18,25,Color(1,1,1,.10 if dark_mode else .30),1.4,true)
	if locked:
		var center := Vector2(size.x / 2, 12)
		draw_arc(center, 6, PI, TAU, 16, colors.text, 1.8, true)
		draw_style_box(_lock_style(colors, palette.get(unlock_color, colors.accent)), Rect2(center + Vector2(-9, 0), Vector2(18, 11)))

func _span(y: float, left: float, width: float, bottom: float, radius: float) -> Vector2:
	var half := width / 2
	if y > bottom - radius:
		var dy := minf(radius, y - (bottom - radius))
		half = sqrt(maxf(0, radius * radius - dy * dy))
	return Vector2(left + width / 2 - half, left + width / 2 + half)

func _symbol_for(unit: Dictionary) -> String:
	return str(SYMBOLS.get(unit.color, "")) if symbols_enabled and known.has(unit.id) else ""

func _band(top: float, bottom: float, left: float, width: float, bowl_bottom: float, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 25:
		var y := lerpf(top, bottom, float(i) / 24)
		points.append(Vector2(_span(y, left, width, bowl_bottom, radius).x, y))
	for i in range(24, -1, -1):
		var y := lerpf(top, bottom, float(i) / 24)
		var point := Vector2(_span(y, left, width, bowl_bottom, radius).y, y)
		if points[-1].distance_squared_to(point) > 0.001:
			points.append(point)
	return points

func _lock_style(colors: Dictionary, fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = colors.text
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	return box
