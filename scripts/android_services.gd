extends Node
signal banner_measured(width_px: float, height_px: float)
signal state_changed
signal progress_changed
signal safe_area_changed(width_px: float, top_px: float)
const State = preload("res://scripts/service_state.gd")
const Cloud = preload("res://scripts/cloud_records.gd")
var state: RefCounted
var progress: RefCounted
var levels: Array = []
var native: Object
var cloud_available := false
var cloud_status := "Sincronização desativada"
var privacy_required := false
var syncing := false
var cloud_connected := false
var cloud_connecting := false
var cloud_diagnostic := ""
var cloud_debug_details := OS.is_debug_build()
var dirty := false
var continuation: Callable
var ad_waiting := false
var ad_started := false
var ad_timeout := 0.0
var cloud_timeout := 0.0

func _ready() -> void:
	if state == null:
		state = State.new()
	if Engine.has_singleton("ArenisAndroid"):
		native = Engine.get_singleton("ArenisAndroid")
		for entry in [["banner_size", _banner_size], ["privacy_state", _privacy_state], ["interstitial_state", _interstitial_state], ["cloud_snapshot", _cloud_snapshot], ["cloud_state", _cloud_state]]:
			native.connect(entry[0], entry[1])
		cloud_available = native.is_cloud_configured()
		cloud_debug_details = native.is_debug_build()
		native.safe_area.connect(func(width: int, top: int): safe_area_changed.emit(float(width), float(top)))
		native.initialize_services()
		if state.cloud_enabled and cloud_available:
			_connect_cloud()

func completed() -> void:
	state.completed()
	dirty = true
	request_sync()

func transition(action: Callable) -> void:
	if ad_waiting:
		return
	if state.completions < 2 or native == null:
		action.call()
		return
	continuation = action
	ad_waiting = true
	ad_started = false
	ad_timeout = 3.0
	native.show_interstitial()

func _process(delta: float) -> void:
	if syncing or cloud_connecting:
		cloud_timeout -= delta
		if cloud_timeout <= 0:
			native.cancel_cloud()
			_cloud_state("failed")
			cloud_diagnostic = "connection_timeout"
			state_changed.emit()
	if ad_waiting and not ad_started:
		ad_timeout -= delta
		if ad_timeout <= 0:
			# Cancel the native request as well, preventing a late surprise ad.
			if native != null:
				native.cancel_interstitial()
			_finish_ad()

func _interstitial_state(event: String) -> void:
	if not ad_waiting:
		return
	if event == "shown":
		ad_started = true
		state.consume_ad_break()
	elif event in ["closed", "unavailable", "failed"]:
		_finish_ad()

func _finish_ad() -> void:
	ad_waiting = false
	var action := continuation
	continuation = Callable()
	if action.is_valid():
		action.call_deferred()

func _banner_size(width: int, height: int) -> void:
	banner_measured.emit(float(width), float(height))

func _privacy_state(required: bool) -> void:
	privacy_required = required
	state_changed.emit()

func show_privacy() -> void:
	if native != null:
		native.show_privacy_options()

func enable_cloud(enabled: bool) -> void:
	if state.set_cloud_enabled(enabled) != OK:
		cloud_status = "Não foi possível salvar o ajuste."
	elif not enabled:
		cloud_status = "Sincronização desativada"
		if native != null:
			native.cancel_cloud()
		syncing = false
		cloud_connected = false
		cloud_connecting = false
		cloud_diagnostic = ""
	elif cloud_available:
		_connect_cloud()
	else:
		cloud_status = "Play Games indisponível nesta versão"
	state_changed.emit()

func _connect_cloud() -> void:
	if cloud_connecting or not state.cloud_enabled or native == null:
		return
	cloud_connected = false
	cloud_connecting = true
	cloud_diagnostic = ""
	cloud_timeout = 120.0
	cloud_status = "Conectando ao Play Games"
	state_changed.emit()
	native.connect_games()

func cloud_feedback() -> String:
	var text := tr(cloud_status if cloud_available else "Play Games indisponível nesta versão")
	if cloud_debug_details and not cloud_diagnostic.is_empty():
		text += "\nPlay Games: " + cloud_diagnostic
	return text

func request_sync() -> void:
	if not state.cloud_enabled or not cloud_available or native == null:
		return
	if not cloud_connected:
		_connect_cloud()
		return
	if syncing:
		dirty = true
		return
	cloud_diagnostic = ""
	syncing = true
	cloud_timeout = 30.0
	dirty = false
	cloud_status = "Sincronizando…"
	state_changed.emit()
	native.read_cloud()

func _cloud_snapshot(first: String, second: String) -> void:
	if not state.cloud_enabled or not syncing:
		if native != null:
			native.cancel_cloud()
		return
	cloud_timeout = 30.0
	var merged := Cloud.merge(progress.export_cloud(), first)
	if merged.ok:
		merged = Cloud.merge(merged.payload, second)
	if not merged.ok or progress.merge_cloud(merged.get("payload", ""), levels) != OK:
		native.cancel_cloud()
		syncing = false
		cloud_status = "Não foi possível sincronizar. Seu progresso continua no aparelho."
		cloud_diagnostic = "snapshot_data_invalid"
		state_changed.emit()
		return
	progress_changed.emit()
	native.write_cloud(progress.export_cloud())

func _cloud_state(event: String) -> void:
	if not state.cloud_enabled:
		return
	if event == "connected":
		cloud_connecting = false
		cloud_connected = true
		cloud_diagnostic = ""
		request_sync()
		return
	if event == "saved":
		syncing = false
		cloud_diagnostic = ""
		cloud_status = "Progresso sincronizado"
		if dirty:
			request_sync.call_deferred()
	else:
		syncing = false
		cloud_connecting = false
		cloud_connected = false
		cloud_diagnostic = ""
		if native != null:
			cloud_diagnostic = native.get_cloud_diagnostic()
		cloud_status = "Não foi possível sincronizar. Seu progresso continua no aparelho."
	state_changed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_node_ready() and cloud_connected:
		request_sync()
