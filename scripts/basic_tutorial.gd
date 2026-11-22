extends VBoxContainer
## Guided practice uses an isolated board; it never changes campaign progress.
signal finished
const Rules = preload("res://scripts/rules.gd")
const Bottle = preload("res://scripts/bottle.gd")
var dark_mode := false
var symbols_enabled := false
var game: RefCounted
var views: Array = []
var guides: Array = []
var caption: Label
var selected := -1
var step := 0
var playing := false
var completed := false

func _ready() -> void:
	add_theme_constant_override("separation", 16)
	game = Rules.new({"capacity": 3, "minimum_moves": 2, "bottles": [{"colors": ["coral", "aqua", "aqua"]}, {"colors": ["aqua"]}, {"colors": ["coral", "coral"]}]})
	var center := CenterContainer.new()
	add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	center.add_child(row)
	for index in 3:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		row.add_child(cell)
		var guide := Label.new()
		guide.custom_minimum_size.y = 24
		guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(guide)
		guides.append(guide)
		var view := Bottle.new()
		view.index = index
		view.capacity = 3
		view.tube_height = 142
		view.tapped.connect(_tap)
		cell.add_child(view)
		views.append(view)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 20)
	add_child(caption)
	_sync()
	caption.text = tr("Toque no tubo indicado para selecionar a origem.")

func _tap(index: int) -> void:
	if playing or completed:
		return
	var target := 1 if step == 0 else 2
	if selected < 0:
		if index != 0:
			caption.text = tr("Toque no tubo indicado pela seta.")
			return
		selected = 0
		_sync()
		caption.text = tr("Agora toque no destino indicado para despejar o bloco do topo.")
		return
	if index != target:
		caption.text = tr("Toque no destino indicado pela seta.")
		return
	playing = true
	var before: Dictionary = game.snapshot()
	game.pour(0, target)
	views[0].units = before.bottles[0]
	views[target].units = game.bottles[target]
	var amount: int = before.bottles[0].size() - game.bottles[0].size()
	var animation := create_tween()
	animation.tween_method(func(value):
		views[0].fill_units = before.bottles[0].size() - amount * value
		views[target].fill_units = before.bottles[target].size() + amount * value
		views[0].queue_redraw()
		views[target].queue_redraw(), 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	await animation.finished
	step += 1
	selected = -1
	playing = false
	completed = game.won()
	_sync()
	caption.text = tr("Muito bem! Complete a outra cor: selecione a origem indicada.") if not completed else tr("Perfeito! Todos os tubos com areia estão cheios e têm uma única cor. Cada despejo conta uma jogada; desfazer também conta.")
	if completed:
		finished.emit()

func _sync() -> void:
	for index in views.size():
		views[index].units = game.bottles[index]
		views[index].known = game.known
		views[index].fill_units = -1
		views[index].dark_mode = dark_mode
		views[index].symbols_enabled = symbols_enabled
		views[index].set_selected(selected == index)
		views[index].interactive = not completed
		views[index].queue_redraw()
		guides[index].text = "↓" if not completed and index == (0 if selected < 0 else 1 if step == 0 else 2) else ""

func set_dark_mode(dark: bool) -> void:
	dark_mode = dark
	for view in views:
		view.dark_mode = dark
		view.queue_redraw()
