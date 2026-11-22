extends Control
## A single progression path. Scrolling is intentional only on this long map.
signal level_selected(index: int)
const Identity = preload("res://scripts/identity.gd")
var levels: Array = []
var progress: RefCounted
var dark_mode := false
var current_index := 0
var nodes: Array = []
const STEP := 94.0
func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 80 + levels.size() * STEP)
	mouse_filter = Control.MOUSE_FILTER_PASS
	for i in levels.size():
		var record: Dictionary = progress.record(levels[i])
		var unlocked: bool = i == 0 or not progress.record(levels[i-1]).is_empty() or not record.is_empty()
		var button := Button.new()
		button.name = "Level%d" % (i+1)
		button.text = str(i+1)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.disabled = not unlocked
		button.tooltip_text = tr("Nível %d") % (i+1)
		button.accessibility_name = button.tooltip_text + (" · " + tr("Bloqueado") if not unlocked else "")
		button.add_theme_font_size_override("font_size", 21)
		_style_node(button, i)
		button.pressed.connect(func(): level_selected.emit(i))
		add_child(button)
		if not unlocked:
			var lock := TextureRect.new()
			lock.name = "LockBadge"
			lock.texture = load("res://assets/icons/lock.svg")
			lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock.position = Vector2(45,47)
			lock.size = Vector2(16,16)
			lock.modulate = Identity.colors(dark_mode).muted
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(lock)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var stars := int(record.get("stars",0))
		label.text = "★".repeat(stars) + "☆".repeat(3-stars) if stars > 0 else tr("Tempo") if levels[i].get("mode", "free") == "timed" else ""
		add_child(label)
		nodes.append([button,label])
	resized.connect(_layout_nodes)
	_layout_nodes()
func point(index: int) -> Vector2:
	return Vector2(size.x*.5 + sin(index*.91)*minf(118,size.x*.27),44+index*STEP)
func _layout_nodes() -> void:
	for i in nodes.size():
		var center := point(i)
		nodes[i][0].position = center - Vector2(32,32)
		nodes[i][0].size = Vector2(64,64)
		nodes[i][1].position = center + Vector2(-48,34)
		nodes[i][1].size = Vector2(96,20)
	queue_redraw()
func _draw() -> void:
	var palette := Identity.colors(dark_mode)
	for i in maxi(0,levels.size()-1):
		var a := point(i)
		var b := point(i+1)
		var route := PackedVector2Array()
		for step in 13:
			var t := step/12.0
			route.append(a.lerp(b,smoothstep(0,1,t)))
		draw_polyline(route,Color(palette.control,.48 if i < current_index else .20),2.0,true)

func _style_node(button: Button, index: int) -> void:
	var palette := Identity.colors(dark_mode)
	if button.has_node("LockBadge"): button.get_node("LockBadge").modulate = palette.muted
	for state in ["normal", "disabled", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = palette.accent if index == current_index or state in ["hover", "pressed"] else palette.background if button.disabled else palette.surface
		box.border_color = palette.text if index == current_index else palette.border
		box.set_border_width_all(2 if index == current_index else 1)
		box.set_corner_radius_all(32)
		button.add_theme_stylebox_override(state, box)

func set_dark_mode(dark: bool) -> void:
	dark_mode = dark
	for i in nodes.size(): _style_node(nodes[i][0], i)
	queue_redraw()
