extends Control
signal transfer_finished

const Catalog = preload("res://scripts/level_catalog.gd")
const Rules = preload("res://scripts/rules.gd")
const Bottle = preload("res://scripts/bottle.gd")
const Identity = preload("res://scripts/identity.gd")
const Mascot = preload("res://scripts/mascot.gd")
const Progress = preload("res://scripts/progress.gd")
const Preferences = preload("res://scripts/preferences.gd")
const Audio = preload("res://scripts/audio.gd")
const Stream = preload("res://scripts/stream.gd")
const MechanicDemo = preload("res://scripts/mechanic_demo.gd")
const BasicTutorial = preload("res://scripts/basic_tutorial.gd")
const Localization = preload("res://scripts/localization.gd")
const AndroidServices = preload("res://scripts/android_services.gd")
const Desert = preload("res://scripts/desert.gd")
const JourneyMap = preload("res://scripts/journey_map.gd")
var levels: Array = []
var game: RefCounted
var level_index := 0
var selected := -1
var busy := false
var screen := "levels"
var cloud_view_dirty := false
var root: VBoxContainer
var board: GridContainer
var status: Label
var move_label: Label
var undo_button: Button
var bottle_views: Array = []
var overlay: Control
var stream: Control
var best: Dictionary = {}
var dark_mode := false
var colors: Dictionary
var mascot: Control
var toast_remaining := 0.0
var toolbar: HBoxContainer
var move_caption: Label
var preferences: RefCounted
var progress: RefCounted
var level_pack_path := "res://data/campaign.json"
var active_difficulty := ""
var chrome: Control
var chrome_layer: CanvasLayer
var theme_button: Button
var banner: PanelContainer
var audio: Node
var fluid_source := -1
var fluid_target := -1
var fluid_before: Dictionary
var fluid_after: Dictionary
var fluid_amount := 0
var theme_cover: Control
var banner_height_units := 75.0
var fluid_travel := Vector2.ZERO
var fluid_tilt := 0.0
var fluid_sound_started := false
var save_failed := false
var services: Node
var completion_counted := false
var safe_top := 0.0
var desert: Control
var time_label: Label
var mode_label: Label
var failure_shown := false
var application_paused := false
var skip_timer_frame := false
var timer_checkpoint := 0.0

func _ready() -> void:
	if preferences == null:
		preferences = Preferences.new()
	if progress == null:
		progress = Progress.new()
	dark_mode = preferences.theme_mode == "dark" or (preferences.theme_mode == "system" and DisplayServer.is_dark_mode())
	Localization.apply(preferences.language_mode)
	_setup_chrome()
	audio = Audio.new()
	audio.preferences = preferences
	add_child(audio)
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	var loaded := Catalog.load_file(level_pack_path)
	if not loaded.ok:
		var label := Label.new()
		label.text = tr("Não foi possível carregar as fases.")
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(label)
		push_error(label.text)
		return
	levels = loaded.pack.levels
	_apply_theme()
	theme_button.icon = load("res://assets/icons/%s.svg" % ("sun" if dark_mode else "moon"))
	services = AndroidServices.new()
	if progress.path != Progress.DEFAULT_PATH:
		services.state = AndroidServices.State.new(progress.path + ".services")
	services.progress = progress
	services.levels = levels
	services.banner_measured.connect(apply_banner_measurement)
	services.safe_area_changed.connect(_apply_safe_top)
	services.progress_changed.connect(_on_cloud_progress)
	add_child(services)
	if OS.get_name() == "Android":
		banner.hide()
		apply_banner_measurement(size.x, 0)
	_show_levels()

func _reset_layout() -> void:
	for child in get_children():
		if child == chrome_layer or child == audio or child == services or child == desert:
			continue
		remove_child(child)
		child.queue_free()
	overlay = null
	status = null
	mascot = null
	toolbar = null
	toast_remaining = 0
	bottle_views.clear()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, ceili(banner_height_units + 24) if side == "bottom" else ceili(24 + safe_top) if side == "top" else 24)
	margin.set_meta("safe_top", true)
	margin.set_meta("banner_margin", true)
	add_child(margin)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	_fade_in(margin, 0.2)
func _base(title: String, subtitle: String) -> void:
	_reset_layout()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	header.custom_minimum_size.y = 80
	root.add_child(header)
	var logo := VBoxContainer.new()
	logo.custom_minimum_size.x = 190
	logo.add_theme_constant_override("separation", 0)
	header.add_child(logo)
	for item in [["arenis", 34], ["Sand Sort Challenge", 16]]:
		var word := Label.new()
		word.text = item[0]
		word.add_theme_font_size_override("font_size", item[1])
		word.add_theme_font_override("font", Identity.font(600 if item[1] == 34 else 500))
		logo.add_child(word)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_icon_button(header, "settings", "Configurações", _show_settings)
	mascot = Mascot.new()
	mascot.dark_mode = dark_mode
	header.add_child(mascot)
	var theme_space := Control.new()
	theme_space.custom_minimum_size.x = 50
	header.add_child(theme_space)
	var heading := _label(title, 28)
	heading.add_theme_font_override("font", Identity.font(600))
	if not subtitle.is_empty():
		_label(subtitle, 17, colors.muted)

func _label(text: String, font_size := 20, color := Color.TRANSPARENT) -> Label:
	var label := Label.new()
	label.text = tr(text)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colors.text if color == Color.TRANSPARENT else color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = tr(text)
	var icon_names := {"Desfazer": "undo", "Reiniciar": "restart", "Menu da fase": "more", "Próxima fase": "play", "Rejogar": "restart", "Seleção de níveis": "levels"}
	if icon_names.has(text):
		_set_button_icon(button, icon_names[text])
	button.custom_minimum_size.y = 52
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func():
		audio.play_tap()
		action.call())
	parent.add_child(button)
	return button

func _show_levels() -> void:
	cloud_view_dirty = false
	if level_pack_path != "res://data/prototype_levels.json":
		_show_campaign()
		return
	screen = "levels"
	_base("Um espaço para cada cor.", "Seis experiências para testar as regras.")
	_label("Todas as demonstrações estão abertas. A campanha tem progressão sequencial.", 18)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for i in levels.size():
		var level: Dictionary = levels[i]
		_button(list, tr("%s\n%s · %d unidades") % [_level_title(level), tr(level.difficulty), level.capacity], _start.bind(i))
	_label("Protótipo • sem anúncios • sem salvamento entre sessões", 15, colors.muted)

func _start(index: int, replace_attempt := false) -> void:
	if index < 0 or index >= levels.size():
		return
	if level_pack_path != "res://data/prototype_levels.json" and not _is_unlocked(index):
		return
	if level_pack_path != "res://data/prototype_levels.json" and not replace_attempt:
		var pending: Dictionary = progress.attempts.get(levels[index].difficulty_id, {})
		if not pending.is_empty() and pending.get("level_id", "") != levels[index].id and not pending.get("actions", []).is_empty():
			var content := _modal("Iniciar outro nível?", "A partida em andamento será substituída. Estrelas e recordes já conquistados continuam salvos.")
			_button(content, "Iniciar nível", _start.bind(index, true))
			_button(content, "Cancelar", _close_modal)
			return
	completion_counted = false
	failure_shown = false
	timer_checkpoint = 0.0
	level_index = index
	game = progress.restore_attempt(levels[index]) if level_pack_path != "res://data/prototype_levels.json" else null
	if game == null:
		game = Rules.new(levels[index])
	active_difficulty = levels[index].difficulty_id
	selected = -1
	busy = false
	_build_game()
	_save_attempt()
	if not game.failed_reason.is_empty():
		_show_failure()
		return
	if level_pack_path.ends_with("prototype_levels.json"):
		_show_lesson()
	else:
		var mechanic := _new_mechanic(levels[index])
		if not preferences.basic_tutorial_seen and game.moves == 0 and progress.record(levels[index]).is_empty():
			_show_basic_tutorial()
		elif not mechanic.is_empty():
			_show_mechanic_intro(mechanic)

func _build_game() -> void:
	screen = "game"
	if is_instance_valid(desert): desert.subdued = true
	var level: Dictionary = levels[level_index]
	_reset_layout()
	root.add_theme_constant_override("separation", 18)
	toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	toolbar.custom_minimum_size.y = 80
	root.add_child(toolbar)
	_icon_button(toolbar, "more", "Menu da fase", _show_level_menu)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)
	undo_button = _icon_button(toolbar, "undo", "Desfazer", _undo)
	_icon_button(toolbar, "help", "Como jogar", _show_lesson)
	var theme_space := Control.new()
	theme_space.custom_minimum_size.x = 50
	toolbar.add_child(theme_space)
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 20)
	root.add_child(summary)
	var level_info := VBoxContainer.new()
	level_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_info.add_theme_constant_override("separation", 2)
	summary.add_child(level_info)
	var title := Label.new()
	title.text = _level_title(level)
	title.add_theme_font_override("font", Identity.font(600))
	title.add_theme_font_size_override("font_size", 30)
	level_info.add_child(title)
	var difficulty := Label.new()
	mode_label = difficulty
	difficulty.text = _mode_name(level)
	difficulty.add_theme_font_size_override("font_size", 15)
	difficulty.add_theme_color_override("font_color", colors.muted)
	level_info.add_child(difficulty)
	mascot = Mascot.new()
	mascot.dark_mode = dark_mode
	summary.add_child(mascot)
	var counter := VBoxContainer.new()
	counter.custom_minimum_size.x = 70
	counter.add_theme_constant_override("separation", 0)
	summary.add_child(counter)
	move_label = Label.new()
	move_label.add_theme_font_override("font", Identity.font(600))
	move_label.add_theme_font_size_override("font_size", 30)
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counter.add_child(move_label)
	move_caption = Label.new()
	move_caption.add_theme_font_size_override("font_size", 13)
	move_caption.add_theme_color_override("font_color", colors.muted)
	move_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counter.add_child(move_caption)
	time_label = Label.new()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_font_size_override("font_size", 20)
	counter.add_child(time_label)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	board = GridContainer.new()
	board.columns = 4 if game.bottles.size() >= 7 else 3 if game.bottles.size() > 4 else mini(4, game.bottles.size())
	board.add_theme_constant_override("h_separation", 16)
	board.add_theme_constant_override("v_separation", 12)
	center.add_child(board)
	for i in game.bottles.size():
		var view := Bottle.new()
		view.index = i
		view.tube_height = 126.0 if game.bottles.size() > 8 else 200.0 if game.bottles.size() > 4 else 252.0
		view.dark_mode = dark_mode
		view.tapped.connect(_on_bottle)
		view.origin_requested.connect(_select_origin)
		board.add_child(view)
		bottle_views.append(view)
	center.resized.connect(_fit_board.bind(center))
	_fit_board.call_deferred(center)
	status = _label("", 16, colors.muted)
	root.remove_child(status)
	add_child(status)
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status.offset_left = 24
	status.offset_right = -24
	status.offset_top = -banner_height_units - 28
	status.offset_bottom = -banner_height_units - 2
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.z_index = 40
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stream = Stream.new()
	stream.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stream.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stream.visible = false
	add_child(stream)
	_refresh()

func _refresh() -> void:
	_update_game_counters()
	undo_button.disabled = busy or game.history.is_empty() or not game.failed_reason.is_empty()
	for i in bottle_views.size():
		var view: Control = bottle_views[i]
		view.fill_units = -1
		view.units = game.bottles[i]
		view.capacity = game.capacity
		view.known = game.known
		view.locked = game.locks[i]
		view.unlock_color = str(game.definition.bottles[i].get("unlock_color", ""))
		view.set_selected(selected == i)
		view.valid_target = false
		view.interactive = not busy and not game.won() and game.failed_reason.is_empty()
		view.symbols_enabled = preferences.symbols_enabled
		view.queue_redraw()
	if not game.won() and game.failed_reason.is_empty() and not game.has_moves():
		_notify("Sem movimentos. Desfaça uma jogada ou reinicie.", 0)

func _on_bottle(index: int) -> void:
	if busy or is_instance_valid(overlay) or game.won() or not game.failed_reason.is_empty():
		return
	if selected == index:
		selected = -1
		_notify("")
		mascot.rest()
	elif selected < 0:
		if game.locks[index]:
			_notify("Complete a cor da tranca para abrir este tubo.")
		elif game.bottles[index].is_empty():
			_notify("Este tubo está vazio.")
		else:
			selected = index
			mascot.look_at_point(bottle_views[index].get_global_rect().get_center())
			_notify("")
	else:
		var source := selected
		var color := Color.WHITE
		if game.transfer_count(source, index) == 0:
			if not game.locks[index] and not game.bottles[index].is_empty():
				selected = index
				mascot.look_at_point(bottle_views[index].get_global_rect().get_center())
				_notify("")
				_refresh()
			else:
				_notify("Complete a cor da tranca para abrir este tubo.")
			return
		color = Identity.sand_color(game.bottles[source].back().color, dark_mode)
		var before: Dictionary = game.snapshot()
		before["known"] = game.known.duplicate()
		var result: Dictionary = game.pour(source, index)
		_save_attempt()
		await _animate_transfer(source, index, before, game.snapshot(), color, result.amount)
		_notify("Não foi possível salvar a partida." if save_failed else "Tubo destrancado." if not result.unlocked.is_empty() else "")
		if game.won():
			_show_result()
		elif not game.failed_reason.is_empty():
			_show_failure()
		return
	_refresh()

func _animate_transfer(source: int, target: int, before: Dictionary, after: Dictionary, color: Color, amount: int) -> void:
	busy = true
	fluid_source = source
	fluid_target = target
	fluid_before = before
	fluid_after = after
	fluid_amount = amount
	_notify("")
	for view in bottle_views:
		view.interactive = false
		view.known = before.get("known", game.known).duplicate()
		view.units = before.bottles[view.index].duplicate(true)
		view.fill_units = view.units.size()
	bottle_views[target].units = after.bottles[target].duplicate(true)
	undo_button.disabled = true
	var origin_view: Control = bottle_views[source]
	var target_view: Control = bottle_views[target]
	origin_view.z_index = 20
	stream.z_index = 30
	var start: Vector2 = origin_view.global_position + Vector2(origin_view.size.x / 2, Bottle.TOP_PADDING)
	var destination: Vector2 = target_view.mouth_position()
	var side := -1.0 if start.x <= destination.x else 1.0
	if absf(start.x - destination.x) < 24:
		side = 1.0 if destination.x < size.x / 2 else -1.0
	if destination.x + side * 76 < 125 or destination.x + side * 76 > size.x - 125:
		side = -side
	fluid_tilt = -side * 0.32
	var desired := destination + Vector2(side * 76, -42)
	var body_shift: float = sin(fluid_tilt) * origin_view.tube_height
	desired.x = clampf(desired.x, 50 + maxf(0, body_shift), size.x - 50 + minf(0, body_shift))
	desired.y = maxf(desired.y, board.global_position.y + 4)
	var rotation_delta := Vector2(sin(fluid_tilt) * origin_view.tube_height, (1 - cos(fluid_tilt)) * origin_view.tube_height)
	fluid_travel = desired - start - rotation_delta
	stream.source = origin_view.mouth_position()
	stream.target = destination + Vector2(0, 9)
	stream.color = color
	stream.color_id = str(before.bottles[source].back().color)
	stream.set_dark_mode(dark_mode)
	stream.progress = 0
	stream.visible = true
	mascot.look_at_point(stream.source, 0.3, "pour")
	fluid_sound_started = false
	var animation := create_tween()
	animation.tween_method(_animate_stream, 0.0, 1.0, 1.45 + minf(0.45, amount * 0.08))
	await animation.finished
	audio.end_sand()
	stream.visible = false
	origin_view.pour_offset = Vector2.ZERO
	origin_view.pour_angle = 0
	origin_view.z_index = 0
	origin_view.queue_redraw()
	# Give the final grains time to settle before showing a victory or accepting a new move.
	await get_tree().create_timer(0.1).timeout
	selected = -1
	busy = false
	_refresh()
	mascot.look_at_point(bottle_views[target].get_global_rect().get_center(), 1.2, "destination")
	transfer_finished.emit()

func _animate_stream(value: float) -> void:
	if value >= 0.18 and not fluid_sound_started:
		fluid_sound_started = true
		audio.begin_sand()
	var pose := smoothstep(0.0, 0.18, value) * (1 - smoothstep(0.87, 1.0, value))
	var source_view: Control = bottle_views[fluid_source]
	source_view.pour_offset = fluid_travel * pose
	source_view.pour_angle = fluid_tilt * pose
	stream.source = source_view.mouth_position()
	stream.target = bottle_views[fluid_target].mouth_position() + Vector2(0, 9)
	stream.progress = clampf((value - 0.18) / 0.66, 0, 1)
	audio.update_sand_flow(stream.progress)
	stream.queue_redraw()
	var drained := smoothstep(0.18, 0.695, value)
	var arrived := smoothstep(0.325, 0.84, value)
	source_view.fill_units = fluid_before.bottles[fluid_source].size() - fluid_amount * drained
	bottle_views[fluid_target].fill_units = fluid_before.bottles[fluid_target].size() + fluid_amount * arrived
	source_view.queue_redraw()
	bottle_views[fluid_target].queue_redraw()
	mascot.look_at_point(stream.point_at(clampf(stream.progress * 1.5 - 0.25, 0, 1)), 0.3, "pour")

func _undo() -> void:
	if busy or is_instance_valid(overlay) or game.history.is_empty():
		return
	var before: Dictionary = game.snapshot()
	before["known"] = game.known.duplicate()
	if not game.undo():
		return
	_save_attempt()
	var after: Dictionary = game.snapshot()
	var source := -1
	var target := -1
	var amount := 0
	for i in game.bottles.size():
		var change: int = before.bottles[i].size() - after.bottles[i].size()
		if change > 0:
			source = i
			amount = change
		elif change < 0:
			target = i
	var color: Color = Identity.sand_color(before.bottles[source].back().color, dark_mode)
	await _animate_transfer(source, target, before, after, color, amount)
	mascot.rest()
	if not game.failed_reason.is_empty():
		_show_failure()

func _modal(title: String, message: String, pinned_action := false) -> VBoxContainer:
	_close_modal(false, false)
	overlay = Control.new()
	overlay.name = "Modal"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 50
	add_child(overlay)
	var shade := ColorRect.new()
	shade.name = "ModalShade"
	shade.color = Color(colors.background)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var margin := MarginContainer.new()
	margin.name = "ModalMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",24)
	margin.add_theme_constant_override("margin_right",24)
	margin.add_theme_constant_override("margin_top",ceili(40+safe_top))
	margin.add_theme_constant_override("margin_bottom",ceili(banner_height_units+24))
	margin.set_meta("safe_top",true)
	margin.set_meta("banner_margin",true)
	overlay.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",16)
	margin.add_child(layout)
	var heading_row := HBoxContainer.new()
	heading_row.custom_minimum_size.y = 48
	layout.add_child(heading_row)
	var heading := Label.new()
	heading.text = tr(title)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size",28)
	heading_row.add_child(heading)
	var theme_space := Control.new()
	theme_space.custom_minimum_size.x = 56
	heading_row.add_child(theme_space)
	var scroll := ScrollContainer.new()
	scroll.name = "ModalScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var body := VBoxContainer.new()
	body.name = "ModalBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",14)
	scroll.add_child(body)
	if not message.is_empty():
		var text := Label.new()
		text.text = tr(message)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_font_size_override("font_size",18)
		body.add_child(text)
	_fade_in(overlay,.18)
	if pinned_action:
		var actions := VBoxContainer.new()
		actions.name = "PinnedActions"
		actions.add_theme_constant_override("separation",10)
		layout.add_child(actions)
		return actions
	return body

func _close_modal(animated := true, refresh_cloud_view := true) -> void:
	if is_instance_valid(overlay):
		var previous: Control = overlay
		overlay = null
		if animated:
			previous.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for button in previous.find_children("*", "BaseButton", true, false):
				button.disabled = true
			for control in previous.find_children("*", "Control", true, false):
				control.mouse_filter = Control.MOUSE_FILTER_IGNORE
				control.focus_mode = Control.FOCUS_NONE
			var animation := previous.create_tween()
			animation.tween_property(previous, "modulate:a", 0, 0.14)
			animation.tween_callback(func():
				previous.queue_free()
				if refresh_cloud_view:
					_refresh_cloud_view())
		else:
			remove_child(previous)
			previous.queue_free()
			if refresh_cloud_view:
				_refresh_cloud_view.call_deferred()

func _show_lesson() -> void:
	if busy: return
	var help := tr("1. Toque no tubo de origem e depois no destino. Só o bloco da cor do topo é transferido. O destino precisa estar vazio ou ter a mesma cor no topo. Se couber apenas parte do bloco, o restante fica na origem.\n\n2. Toque em outro tubo com areia para trocar a origem quando o despejo não for permitido. Toque no tubo selecionado para cancelar.\n\n3. Complete cada tubo com uma única cor. Tubos vazios podem permanecer como apoio. Desfazer conta uma jogada; reiniciar zera a tentativa.\n\n4. Algumas fases têm limite de jogadas; outras têm tempo. O cronômetro começa na primeira jogada e pausa nos menus, nas animações e quando o app fica em segundo plano. Vencer na última jogada permitida vale.\n\n5. Para três estrelas, use até 20% de jogadas acima do mínimo; para duas, até 50%. Rejogue para melhorar seu recorde.")
	var actions := _modal("Como jogar",help,true)
	_button(actions,"Praticar",_show_basic_tutorial.bind(false))
	_button(actions,"Entendi",_close_modal)

func _show_basic_tutorial(introduction := true) -> void:
	if busy:
		return
	var actions := _modal("Vamos praticar", "Este treino não altera sua fase nem suas estrelas. Siga as setas para aprender a selecionar, despejar e completar os tubos.", true)
	overlay.set_meta("basic_tutorial", true)
	var practice := BasicTutorial.new()
	practice.dark_mode = dark_mode
	practice.symbols_enabled = preferences.symbols_enabled
	var body: VBoxContainer = overlay.find_child("ModalBody", true, false)
	body.add_child(practice)
	body.move_child(practice, 0)
	var start := _button(actions, "Começar fase" if introduction else "Voltar à fase", _finish_basic_tutorial.bind(introduction))
	start.disabled = true
	practice.finished.connect(func(): start.disabled = false)
	_button(actions, "Pular tutorial", _finish_basic_tutorial.bind(introduction))

func _finish_basic_tutorial(introduction: bool) -> void:
	preferences.mark_basic_tutorial()
	_close_modal(false)
	if introduction:
		var mechanic := _new_mechanic(levels[level_index])
		if not mechanic.is_empty():
			_show_mechanic_intro(mechanic)

func _show_level_menu() -> void:
	if busy:
		return
	if game.won():
		_show_result()
		return
	var content := _modal("Menu da fase", "")
	_button(content, "Continuar", _close_modal)
	_button(content, "Como jogar", _show_lesson)
	_button(content, "Configurações", _show_settings)
	_button(content, "Reiniciar", _confirm_restart)
	_button(content, "Seleção de níveis", _leave_level)

func _confirm_restart() -> void:
	if busy:
		return
	var content := _modal("Reiniciar esta fase?", "As jogadas, o tempo e as cores descobertas desta tentativa serão reiniciados.")
	_button(content, "Reiniciar", _restart)
	_button(content, "Cancelar", _close_modal)

func _restart() -> void:
	_close_modal()
	completion_counted = false
	failure_shown = false
	timer_checkpoint = 0.0
	game.restart()
	_save_attempt()
	selected = -1
	mascot.rest()
	_notify("")
	_refresh()

func _show_result() -> void:
	if game == null or not game.won() or busy:
		return
	var save_warning := ""
	var id: String = levels[level_index].id
	best[id] = mini(int(best.get(id, game.moves)), game.moves)
	if level_pack_path != "res://data/prototype_levels.json":
		var error: Error = progress.complete(levels[level_index], game.stars(), game.moves)
		if error != OK:
			save_warning = "\n" + tr("Não foi possível salvar este resultado.")
			push_warning(save_warning)
		var saved: Dictionary = progress.record(levels[level_index])
		best[id] = mini(best[id], int(saved.get("best_moves", best[id])))
	var content := _modal("Fase concluída!", tr("%s\n%d jogadas · Recorde: %d") % ["★".repeat(game.stars()) + "☆".repeat(3 - game.stars()), game.moves, best[id]] + save_warning)
	audio.play_complete()
	mascot.celebrate()
	var celebration := CenterContainer.new()
	var result_mascot := Mascot.new()
	result_mascot.dark_mode = dark_mode
	result_mascot.custom_minimum_size = Vector2(104, 104)
	celebration.add_child(result_mascot)
	content.add_child(celebration)
	content.move_child(celebration, 0)
	result_mascot.celebrate()
	if level_index + 1 < levels.size() and levels[level_index + 1].difficulty_id == levels[level_index].difficulty_id:
		_button(content, "Próxima fase", _after_result.bind(_start.bind(level_index + 1)))
	if not save_warning.is_empty():
		_button(content, "Tentar salvar novamente", _show_result)
	_button(content, "Rejogar", _after_result.bind(_restart))
	_button(content, "Seleção de níveis", _after_result.bind(_leave_level))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_attempt()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		application_paused = true
		_save_attempt()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		application_paused = false
		skip_timer_frame = true

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()

func _back() -> void:
	if busy:
		return
	if is_instance_valid(overlay):
		if game != null and game.won():
			return
		_close_modal()
	elif screen == "game":
		_show_level_menu()

func _apply_theme() -> void:
	if is_instance_valid(desert):
		desert.dark_mode = dark_mode
	colors = Identity.colors(dark_mode)
	theme = Identity.make_theme(dark_mode)
	if is_instance_valid(chrome):
		chrome.theme = theme
	RenderingServer.set_default_clear_color(colors.background)

func _toggle_theme() -> void:
	var cover := _theme_snapshot()
	var previous := colors.duplicate()
	dark_mode = not dark_mode
	preferences.set_theme("dark" if dark_mode else "light")
	_apply_theme()
	_recolor(self, previous)
	theme_button.icon = load("res://assets/icons/%s.svg" % ("sun" if dark_mode else "moon"))
	theme_button.add_theme_color_override("icon_normal_color", colors.text)
	banner.modulate = Color.WHITE
	var banner_style: StyleBoxFlat = banner.get_theme_stylebox("panel")
	banner_style.bg_color = colors.surface
	banner_style.border_color = colors.border
	if is_instance_valid(overlay):
		overlay.get_node("ModalShade").color = Color(colors.background)
	var animation := cover.create_tween()
	animation.tween_property(cover, "modulate:a", 0, 0.30).set_trans(Tween.TRANS_SINE)
	animation.tween_callback(cover.queue_free)

func _icon_button(parent: Node, icon_name: String, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = caption
	button.icon = load("res://assets/icons/%s.svg" % icon_name)
	button.tooltip_text = tr(caption)
	button.accessibility_name = tr(caption)
	button.custom_minimum_size = Vector2(50, 48)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.flat = true
	button.pressed.connect(func():
		audio.play_tap()
		action.call())
	parent.add_child(button)
	return button

func _notify(message: String, duration := 2.8) -> void:
	if is_instance_valid(status):
		status.text = tr(message)
		toast_remaining = duration if not message.is_empty() else 0.0

func _process(delta: float) -> void:
	if toast_remaining > 0:
		toast_remaining = maxf(0, toast_remaining-delta)
		if toast_remaining == 0 and is_instance_valid(status): status.text = ""
	if skip_timer_frame:
		skip_timer_frame = false
		return
	if screen != "game" or game == null or application_paused or busy or is_instance_valid(overlay): return
	if not game.failed_reason.is_empty() or game.won(): return
	game.advance_time(delta)
	_update_game_counters()
	if game.timer_started and int(game.definition.get("time_limit",0)) > 0:
		timer_checkpoint += delta
		if timer_checkpoint >= 1.0:
			timer_checkpoint = 0.0
			_save_attempt()
	if not game.failed_reason.is_empty(): _show_failure()

func _show_settings() -> void:
	if busy:
		return
	var content := _modal("Configurações", "Aparência e acessibilidade")
	var toggle := CheckButton.new()
	toggle.text = tr("Símbolos nas cores (daltonismo)")
	toggle.accessibility_name = toggle.text
	toggle.button_pressed = preferences.symbols_enabled
	_style_toggle(toggle)
	content.add_child(toggle)
	var feedback := Label.new()
	feedback.visible = false
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_font_size_override("font_size", 16)
	content.add_child(feedback)
	toggle.toggled.connect(_on_symbols_toggled.bind(toggle, feedback))
	_audio_control(content, "Efeitos sonoros", "effects_enabled", "effects_volume")
	var language_label := Label.new()
	language_label.text = tr("Idioma")
	content.add_child(language_label)
	var language := OptionButton.new()
	language.alignment = HORIZONTAL_ALIGNMENT_CENTER
	language.custom_minimum_size.y = 52
	language.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language.accessibility_name = tr("Idioma")
	for name in [tr("Seguir o sistema"), "Português (Brasil)", "English", "Español (Latinoamérica)"]:
		language.add_item(name)
	language.select(["system", "pt_BR", "en", "es_419"].find(preferences.language_mode))
	language.item_selected.connect(_change_language)
	content.add_child(language)
	_button(content, "Conta e privacidade", _show_services)
	_button(content, "Voltar", _close_modal)

func _on_symbols_toggled(enabled: bool, toggle: CheckButton, feedback: Label) -> void:
	if preferences.set_symbols_enabled(enabled) != OK:
		feedback.visible = true
		toggle.set_pressed_no_signal(preferences.symbols_enabled)
		feedback.text = tr("Não foi possível salvar a preferência. Tente novamente.")
		return
	feedback.text = ""
	feedback.visible = false
	for view in bottle_views:
		view.symbols_enabled = preferences.symbols_enabled
		view.queue_redraw()

func _choose_difficulty(_id: String) -> void:
	active_difficulty = "journey"
	_show_levels()

func _difficulty_menu() -> void:
	active_difficulty = "journey"
	_show_levels()

func _is_unlocked(index: int) -> bool:
	if index < 0 or index >= levels.size(): return false
	return index == 0 or not progress.record(levels[index-1]).is_empty() or not progress.record(levels[index]).is_empty()

func _new_mechanic(level: Dictionary) -> String:
	var mode: String = level.get("mode", "free")
	if mode in ["moves", "timed"] and not preferences.has_seen_mechanic("journey", mode): return mode
	var hidden := false
	var locked := false
	for bottle in level.bottles:
		hidden = hidden or not bottle.get("hidden", []).is_empty()
		locked = locked or bottle.has("unlock_color")
	if hidden and locked and not preferences.has_seen_mechanic(level.difficulty_id, "combined"):
		return "combined"
	if hidden and not preferences.has_seen_mechanic(level.difficulty_id, "hidden"):
		return "hidden"
	if locked and not preferences.has_seen_mechanic(level.difficulty_id, "locked"):
		return "locked"
	return ""

func _show_mechanic_intro(kind: String) -> void:
	if kind in ["moves", "timed"]:
		var title := "Limite de jogadas" if kind == "moves" else "Fases com tempo"
		var message := "Cada despejo válido e cada desfazer consomem uma jogada. Complete a fase antes de gastar todas. Se a última jogada concluir os tubos, você vence. Pode reiniciar quantas vezes quiser." if kind == "moves" else "O tempo começa na primeira jogada. Ele pausa durante animações, menus e quando você sai do app. As estrelas continuam dependendo das jogadas. Se o tempo terminar, tente novamente sem perder os níveis anteriores."
		var actions := _modal(title, message, true)
		_button(actions, "Entendi, jogar", _dismiss_mechanic_intro.bind(kind))
		return
	if busy:
		return
	var titles := {"hidden": "Areia escondida", "locked": "Frascos trancados", "combined": "Dois obstáculos juntos"}
	var messages := {
		"hidden": "As camadas cinzas têm cores fixas.\n\nDespeje o bloco de cima para expor a camada escondida. Quando um bloco chega ao topo de um tubo destrancado, sua cor é revelada.\n\nDesfazer mantém as cores que você descobriu. Reiniciar esconde as cores novamente.",
		"locked": "O cadeado mostra a cor que abre este tubo.\n\nEncha outro tubo destrancado com uma única cor igual à do cadeado. Um tubo apenas parcialmente cheio não abre a tranca.\n\nEnquanto estiver trancado, o tubo não recebe nem despeja areia. Desfazer pode fechar a tranca novamente.",
		"combined": "Agora há camadas escondidas e frascos trancados na mesma fase.\n\nExpor o bloco do topo revela sua cor. Completar em outro tubo a cor do cadeado abre a tranca.\n\nVeja como uma mesma jogada pode revelar uma camada e destrancar um tubo."}
	var actions := _modal(titles[kind], messages[kind], true)
	overlay.set_meta("mechanic", kind)
	var demo := MechanicDemo.new()
	demo.kind = kind
	demo.capacity = game.capacity
	demo.dark_mode = dark_mode
	demo.symbols_enabled = preferences.symbols_enabled
	for bottle in game.definition.bottles:
		if bottle.has("unlock_color"):
			demo.key_color = bottle.unlock_color
			break
	var body: VBoxContainer = overlay.find_child("ModalBody", true, false)
	body.add_child(demo)
	body.move_child(demo, 0)
	var replay := _button(actions, "Ver exemplo", demo.play)
	demo.playback_changed.connect(func(active): replay.disabled = active)
	_button(actions, "Entendi, jogar", _dismiss_mechanic_intro.bind(kind))

func _dismiss_mechanic_intro(kind: String) -> void:
	var error: Error = preferences.mark_mechanic_seen(active_difficulty, kind)
	if error != OK:
		push_warning("Não foi possível guardar a apresentação do obstáculo.")
	_close_modal()

func _show_campaign() -> void:
	screen = "levels"
	if is_instance_valid(desert): desert.subdued = false
	_base("Sua jornada", "")
	var current: int = progress.latest_attempt(levels)
	var continuing := current >= 0
	if current < 0:
		current = levels.size()-1
		for i in levels.size():
			if progress.record(levels[i]).is_empty():
				current = i
				break
	var caption := tr("Continuar — Nível %d") if continuing else tr("Jogar — Nível %d")
	var play := _button(root, caption % (current+1), _start.bind(current))
	play.name = "PlayCurrentLevel"
	play.custom_minimum_size.y = 62
	var scroll := ScrollContainer.new()
	scroll.name = "CampaignMapScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var map := JourneyMap.new()
	map.name = "JourneyMap"
	map.levels = levels
	map.progress = progress
	map.current_index = current
	map.dark_mode = dark_mode
	map.level_selected.connect(_start)
	scroll.add_child(map)
	_center_map.call_deferred(scroll, current)

func _center_map(scroll: Variant, current: int) -> void:
	if is_instance_valid(scroll):
		scroll.scroll_vertical = maxi(0, int(44+current*JourneyMap.STEP-scroll.size.y*.42))

func _mode_name(level: Dictionary) -> String:
	return tr("Limite de jogadas") if level.get("mode", "free") == "moves" else tr("Desafio de tempo") if level.get("mode", "free") == "timed" else tr("Sem limites")

func _update_game_counters() -> void:
	if game == null or not is_instance_valid(move_label): return
	var bounded := int(game.definition.get("move_limit",0)) > 0
	move_label.text = str(game.remaining_moves() if bounded else game.moves)
	move_caption.text = tr("restantes") if bounded else tr("jogada") if game.moves == 1 else tr("jogadas")
	if is_instance_valid(mode_label):
		mode_label.text = tr("%d jogadas usadas") % game.moves if bounded else _mode_name(game.definition)
	if is_instance_valid(time_label):
		time_label.visible = int(game.definition.get("time_limit",0)) > 0
		var seconds: int = ceili(game.remaining_seconds())
		time_label.text = "%d:%02d" % [seconds/60,seconds%60]
		time_label.add_theme_color_override("font_color", colors.text if seconds > 15 else Color("d0a16d") if dark_mode else Color("a15a43"))

func _show_failure() -> void:
	if game == null or game.failed_reason.is_empty() or game.won() or busy or failure_shown: return
	failure_shown = true
	_save_attempt()
	var title := "Tempo esgotado" if game.failed_reason == "time" else "Acabaram as jogadas"
	var actions := _modal(title, "Você pode tentar novamente quantas vezes quiser. Seus resultados anteriores continuam salvos.")
	_button(actions, "Tentar novamente", _restart)
	_button(actions, "Mapa de níveis", _leave_level)

func _leave_level() -> void:
	_save_attempt()
	_show_levels()

func _save_attempt() -> void:
	if level_pack_path == "res://data/prototype_levels.json" or game == null or screen != "game":
		return
	var error: Error = progress.save_attempt(levels[level_index], game)
	save_failed = error != OK
	if error == OK and game.won() and not completion_counted:
		completion_counted = true
		if is_instance_valid(services):
			services.completed(levels[level_index])
	if save_failed:
		push_warning("Não foi possível salvar a partida.")

func _setup_chrome() -> void:
	desert = Desert.new()
	desert.name = "DesertBackground"
	desert.z_index = -5
	desert.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(desert)
	chrome_layer = CanvasLayer.new()
	chrome_layer.layer = 100
	add_child(chrome_layer)
	chrome = Control.new()
	chrome.name = "GlobalControls"
	chrome.z_index = 100
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome_layer.add_child(chrome)
	theme_button = _icon_button(chrome, "moon", "Alternar tema", _toggle_theme)
	theme_button.z_index = 10
	theme_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	theme_button.offset_left = -74
	theme_button.offset_right = -24
	theme_button.offset_top = 40
	theme_button.offset_bottom = 88
	banner = PanelContainer.new()
	banner.z_index = 3
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	banner.offset_top = -banner_height_units
	chrome.add_child(banner)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Identity.colors(dark_mode).surface
	panel.border_color = Identity.colors(dark_mode).border
	panel.border_width_top = 1
	banner.add_theme_stylebox_override("panel", panel)
	var label := Label.new()
	label.text = tr("Espaço para anúncio")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Identity.colors(dark_mode).muted)
	banner.add_child(label)

func _set_button_icon(button: Button, icon_name: String, disabled := false) -> void:
	var icon := TextureRect.new()
	icon.name = "ActionIcon"
	icon.texture = load("res://assets/icons/%s.svg" % icon_name)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	icon.offset_left = 12
	icon.offset_right = 32
	icon.offset_top = -10
	icon.offset_bottom = 10
	icon.modulate = colors.muted if disabled else colors.text
	button.set_meta("action_icon", icon_name)

func _fade_in(control: Control, duration: float) -> void:
	control.modulate.a = 0
	control.create_tween().tween_property(control, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE)

func _theme_snapshot() -> Control:
	if is_instance_valid(theme_cover):
		theme_cover.queue_free()
	var cover: Control
	if DisplayServer.get_name() != "headless":
		var snapshot := TextureRect.new()
		snapshot.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
		snapshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		snapshot.stretch_mode = TextureRect.STRETCH_SCALE
		cover = snapshot
	else:
		var flat := ColorRect.new()
		flat.color = colors.background
		cover = flat
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(cover)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme_cover = cover
	return cover

func _recolor(node: Node, old: Dictionary) -> void:
	if node == theme_cover:
		return
	if node is Control:
		if node.has_theme_color_override("font_color"):
			var color: Color = node.get_theme_color("font_color")
			for key in ["text", "muted"]:
				if color == old[key]:
					node.add_theme_color_override("font_color", colors[key])
		if node.name == "ActionIcon":
			node.modulate = colors.muted if node.get_parent().disabled else colors.text
	if node.get_script() == Bottle:
		node.dark_mode = dark_mode
		node.queue_redraw()
	elif node.get_script() == JourneyMap:
		node.set_dark_mode(dark_mode)
	elif node.get_script() == Mascot:
		node.set_dark_mode(dark_mode)
	elif node.get_script() == Stream:
		node.set_dark_mode(dark_mode)
	elif node.get_script() == MechanicDemo:
		node.set_dark_mode(dark_mode)
	elif node.get_script() == BasicTutorial:
		node.set_dark_mode(dark_mode)
	for child in node.get_children():
		_recolor(child, old)

func _style_toggle(toggle: CheckButton) -> void:
	toggle.custom_minimum_size.y = 58
	toggle.add_theme_font_size_override("font_size", 18)
	toggle.add_theme_constant_override("h_separation", 14)
	toggle.add_theme_constant_override("icon_max_width", 56)
	for state in ["checked", "checked_disabled"]:
		toggle.add_theme_icon_override(state, load("res://assets/icons/toggle-on.svg"))
	for state in ["unchecked", "unchecked_disabled"]:
		toggle.add_theme_icon_override(state, load("res://assets/icons/toggle-off.svg"))

func _audio_control(content: VBoxContainer, caption: String, flag: String, volume: String) -> void:
	var toggle := CheckButton.new()
	toggle.text = tr(caption)
	toggle.accessibility_name = caption
	toggle.button_pressed = preferences.get(flag)
	_style_toggle(toggle)
	content.add_child(toggle)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = preferences.get(volume) * 100
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 44
	slider.accessibility_name = tr("Volume de %s") % tr(caption).to_lower()
	row.add_child(slider)
	var value := Label.new()
	value.custom_minimum_size.x = 48
	value.text = "%d%%" % slider.value
	row.add_child(value)
	var feedback := Label.new()
	feedback.visible = false
	feedback.add_theme_font_size_override("font_size", 14)
	content.add_child(feedback)
	toggle.toggled.connect(func(enabled):
		if preferences.set_audio(flag, enabled) != OK:
			feedback.visible = true
			toggle.set_pressed_no_signal(preferences.get(flag))
			feedback.text = tr("Não foi possível salvar o ajuste.")
		audio.apply_preferences())
	slider.value_changed.connect(func(number):
		value.text = "%d%%" % number
		if preferences.set_audio(volume, number / 100.0) != OK:
			feedback.visible = true
			feedback.text = tr("Não foi possível salvar o ajuste.")
		audio.apply_preferences())

func _select_origin(index: int) -> void:
	if busy or is_instance_valid(overlay) or game.won() or not game.failed_reason.is_empty() or index < 0 or index >= game.bottles.size():
		return
	if game.locks[index] or game.bottles[index].is_empty():
		return
	selected = index
	_notify("")
	mascot.look_at_point(bottle_views[index].get_global_rect().get_center())
	_refresh()

func _fit_board(center: Variant) -> void:
	if not is_instance_valid(center) or not is_instance_valid(board) or board.get_parent() != center or bottle_views.is_empty():
		return
	var rows := ceili(float(bottle_views.size()) / board.columns)
	var available := maxf(0, size.y - banner_height_units - 24 - center.global_position.y)
	var height := clampf((available - (rows - 1) * 12) / rows - Bottle.TOP_PADDING - Bottle.BOTTOM_PADDING, 64, 300)
	for view in bottle_views:
		view.tube_height = height
		view.custom_minimum_size.y = height + Bottle.TOP_PADDING + Bottle.BOTTOM_PADDING
		view.queue_redraw()

func apply_banner_measurement(screen_width_px: float, height_px: float) -> void:
	# Native SDK callback: measured pixels, including any bottom system inset.
	if screen_width_px <= 0 or height_px < 0:
		return
	banner_height_units = height_px * size.x / screen_width_px
	banner.offset_top = -banner_height_units
	if is_instance_valid(status):
		status.offset_top = -banner_height_units - 28
		status.offset_bottom = -banner_height_units - 2
	for margin in find_children("*", "MarginContainer", true, false):
		if margin.has_meta("banner_margin"):
			margin.add_theme_constant_override("margin_bottom", ceili(banner_height_units + 24))
	if is_instance_valid(board) and screen == "game":
		_fit_board.call_deferred(board.get_parent())

func _level_title(level: Dictionary) -> String:
	var number := str(level.title).trim_prefix("Nível ")
	return tr("Nível %d") % int(number) if number.is_valid_int() else tr(level.title)

func _change_language(index: int) -> void:
	var mode: String = ["system", "pt_BR", "en", "es_419"][index]
	if preferences.set_language(mode) != OK:
		_notify("Não foi possível salvar a preferência. Tente novamente.")
		return
	Localization.apply(mode)
	theme_button.tooltip_text = tr("Alternar tema")
	theme_button.accessibility_name = theme_button.tooltip_text
	for label in banner.find_children("*", "Label", true, false):
		label.text = tr("Espaço para anúncio")
	if screen == "game":
		_build_game()
	else:
		_show_levels()
	_show_settings()

func _after_result(action: Callable) -> void:
	if is_instance_valid(services) and game != null and game.won():
		services.transition(action, levels[level_index])
	else:
		action.call()

func _on_cloud_progress() -> void:
	cloud_view_dirty = true
	_refresh_cloud_view()

func _refresh_cloud_view() -> void:
	if cloud_view_dirty and screen == "levels" and not is_instance_valid(overlay):
		_show_levels()

func _show_services() -> void:
	var content := _modal("Conta e privacidade", "A sincronização é opcional. Ela guarda conclusões, estrelas e recordes no Play Games. Partidas em andamento e preferências ficam neste aparelho.", true)
	var body: VBoxContainer = overlay.find_child("ModalBody", true, false)
	var toggle := CheckButton.new()
	toggle.text = tr("Sincronizar progresso")
	_style_toggle(toggle)
	toggle.button_pressed = services.state.cloud_enabled
	toggle.disabled = not services.cloud_available
	body.add_child(toggle)
	var feedback := Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.text = services.cloud_feedback()
	body.add_child(feedback)
	toggle.toggled.connect(services.enable_cloud)
	var update_feedback := func():
		if is_instance_valid(feedback):
			feedback.text = services.cloud_feedback()
	services.state_changed.connect(update_feedback)
	feedback.tree_exiting.connect(func(): services.state_changed.disconnect(update_feedback))
	if services.cloud_available:
		_button(body, "Sincronizar agora", services.request_sync)
	if services.privacy_required:
		_button(body, "Privacidade dos anúncios", services.show_privacy)
	_button(content, "Voltar", _show_settings)

func _apply_safe_top(width_px: float, top_px: float) -> void:
	if width_px <= 0:
		return
	var next := maxf(0, top_px) * size.x / width_px
	if is_equal_approx(next, safe_top):
		return
	var change := next - safe_top
	safe_top = next
	theme_button.offset_top = 40 + safe_top
	theme_button.offset_bottom = 88 + safe_top
	for margin in find_children("*", "MarginContainer", true, false):
		if margin.has_meta("safe_top"):
			margin.add_theme_constant_override("margin_top", margin.get_theme_constant("margin_top") + ceili(change))
	if is_instance_valid(board) and screen == "game":
		_fit_board.call_deferred(board.get_parent())
