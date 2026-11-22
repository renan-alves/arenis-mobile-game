extends VBoxContainer
## Standalone example. Its Rules instance never reads or changes the active level.
signal playback_changed(active: bool)
const Rules = preload("res://scripts/rules.gd")
const Bottle = preload("res://scripts/bottle.gd")
const Identity = preload("res://scripts/identity.gd")
var kind := "hidden"
var capacity := 3
var key_color := "coral"
var dark_mode := false
var symbols_enabled := false
var playing := false
var game: RefCounted
var views: Array = []
var names: Array = []
var caption: Label
var source := 0
var target := 1
var before: Dictionary
var after: Dictionary
var amount := 0

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var center := CenterContainer.new()
	add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	center.add_child(row)
	for index in 3:
		var cell := VBoxContainer.new()
		row.add_child(cell)
		var view := Bottle.new()
		view.index = index
		view.capacity = capacity
		view.tube_height = 112
		view.interactive = false
		cell.add_child(view)
		views.append(view)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		cell.add_child(label)
		names.append(label)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 16)
	add_child(caption)
	reset()
	_auto_play()

func reset() -> void:
	var other := "aqua" if key_color != "aqua" else "coral"
	var definition := {"capacity": capacity, "bottles": [], "minimum_moves": 1}
	if kind == "hidden":
		definition.bottles = [{"colors": [key_color] + _repeat(other, capacity - 1), "hidden": [0]}, {"colors": [other]}, {"colors": _repeat(key_color, capacity - 1)}]
		source = 0
		target = 1
	else:
		definition.bottles = [{"colors": _repeat(key_color, capacity - 1)}, {"colors": _repeat(other, capacity - 1) + [key_color]}, {"colors": [other], "unlock_color": key_color}]
		if kind == "combined":
			definition.bottles[1].hidden = range(capacity - 1)
		source = 1
		target = 0
	game = Rules.new(definition)
	_sync()
	caption.text = tr("A cor cinza está escondida sob o bloco do topo." if kind == "hidden" else "O cadeado só abre quando a cor indicada fica completa.")

func _auto_play() -> void:
	await get_tree().create_timer(0.65).timeout
	if is_inside_tree() and not playing and game.moves == 0:
		play()

func play() -> void:
	if playing:
		return
	reset()
	playing = true
	playback_changed.emit(true)
	before = game.snapshot()
	var known: Dictionary = game.known.duplicate()
	var result: Dictionary = game.pour(source, target)
	amount = result.amount
	after = game.snapshot()
	for view in views:
		view.known = known
		view.units = before.bottles[view.index]
		view.fill_units = view.units.size()
	views[target].units = after.bottles[target]
	caption.text = tr("Despejando apenas o bloco do topo…")
	var animation := create_tween()
	animation.tween_method(_fill, 0.0, 1.0, 0.95).set_trans(Tween.TRANS_SINE)
	await animation.finished
	_sync()
	caption.text = tr({"hidden": "O bloco escondido chegou ao topo: sua cor foi revelada.", "locked": "A cor do cadeado ficou completa: o tubo foi destrancado.", "combined": "A mesma jogada revelou uma cor e destrancou o tubo."}[kind])
	playing = false
	playback_changed.emit(false)

func _fill(progress: float) -> void:
	views[source].fill_units = before.bottles[source].size() - amount * progress
	views[target].fill_units = before.bottles[target].size() + amount * progress
	views[source].queue_redraw()
	views[target].queue_redraw()

func set_dark_mode(dark: bool) -> void:
	dark_mode = dark
	for view in views:
		view.dark_mode = dark
		view.queue_redraw()

func _sync() -> void:
	for index in views.size():
		var view: Control = views[index]
		view.units = game.bottles[index]
		view.known = game.known
		view.locked = game.locks[index]
		view.unlock_color = game.definition.bottles[index].get("unlock_color", "")
		view.fill_units = -1
		view.dark_mode = dark_mode
		view.symbols_enabled = symbols_enabled
		view.set_selected(index == source)
		view.queue_redraw()
	var labels := ["Origem", "Destino", "Apoio"] if kind == "hidden" else ["Complete", "Origem", "Trancado" if game.locks[2] else "Aberto"]
	for index in names.size():
		names[index].text = tr(labels[index])

func _repeat(color: String, count: int) -> Array:
	var result: Array = []
	for index in count:
		result.append(color)
	return result
