extends RefCounted
## Approved outline/pastel direction. Theme selection/persistence belongs to the UI phase.
const SAND := {"coral": Color("ebc4bc"), "aqua": Color("bbdadd"), "gold": Color("e8d9b1"), "lilac": Color("d9d0e9"),
	"sky": Color("a2c7e7"), "sage": Color("9dbda3"), "rose": Color("d9a5c0"),
	"peach": Color("efcba4"), "indigo": Color("aaa9d9"), "mint": Color("c5dfbe")}
const SAND_DARK := {"coral": Color("b8796c"), "aqua": Color("5d9e9b"), "gold": Color("b49b58"), "lilac": Color("9880b2"),
	"sky": Color("6694bb"), "sage": Color("6d9274"), "rose": Color("aa718e"),
	"peach": Color("bd8b60"), "indigo": Color("7d7caf"), "mint": Color("8aa77e")}

static func sand_palette(dark := false) -> Dictionary:
	return SAND_DARK if dark else SAND

static func sand_color(id: String, dark := false) -> Color:
	return sand_palette(dark).get(id, colors(dark).hidden)

static func sand_symbol_color(dark := false) -> Color:
	return Color("081013") if dark else Color("17282b")

static func colors(dark := false) -> Dictionary:
	if dark:
		return {"background": Color("202e33"), "surface": Color("29393e"), "text": Color("e3ece5"),
			"muted": Color("adbfba"), "border": Color("49615e"), "control": Color("7d9892"),
			"accent": Color("354f47"), "hidden": Color("43555a")}
	return {"background": Color("f8f7f2"), "surface": Color("fffefa"), "text": Color("354e50"),
		"muted": Color("60736f"), "border": Color("ccd8d1"), "control": Color("7d9188"),
		"accent": Color("dceae1"), "hidden": Color("dce1db")}

static func font(weight := 500) -> Font:
	var variation := FontVariation.new()
	variation.base_font = load("res://assets/fonts/Manrope-Variable.ttf")
	variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	variation.fallbacks = [ThemeDB.fallback_font]
	return variation

static func make_theme(dark := false) -> Theme:
	var palette := colors(dark)
	var theme := Theme.new()
	theme.default_font = font()
	theme.default_font_size = 20
	theme.set_color("font_color", "Label", palette.text)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = palette.accent if state in ["hover", "pressed", "hover_pressed"] else palette.surface
		box.border_color = palette.control
		box.set_border_width_all(1)
		box.set_corner_radius_all(14)
		box.content_margin_left = 14
		box.content_margin_right = 14
		box.content_margin_top = 12
		box.content_margin_bottom = 12
		if state == "focus":
			box.bg_color = Color.TRANSPARENT
			box.border_color = palette.text
			box.set_border_width_all(2)
		elif state == "disabled":
			box.bg_color = palette.background
			box.border_color = palette.border
		theme.set_stylebox(state, "Button", box)
		theme.set_stylebox(state, "CheckButton", box)
		theme.set_stylebox(state, "OptionButton", box)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var color: Color = palette.muted if state == "disabled" else palette.text
		theme.set_color("font_color" if state == "normal" else "font_" + state + "_color", "Button", color)
		theme.set_color("font_color" if state == "normal" else "font_" + state + "_color", "CheckButton", color)
		theme.set_color("font_color" if state == "normal" else "font_" + state + "_color", "OptionButton", color)
		theme.set_color("icon_" + state + "_color", "Button", color)
		theme.set_color("icon_" + state + "_color", "CheckButton", color)
		theme.set_color("icon_" + state + "_color", "OptionButton", color)
	var popup := StyleBoxFlat.new()
	popup.bg_color = palette.surface
	popup.border_color = palette.control
	popup.set_border_width_all(1)
	popup.set_corner_radius_all(12)
	theme.set_stylebox("panel", "PopupMenu", popup)
	var popup_hover := StyleBoxFlat.new()
	popup_hover.bg_color = palette.accent
	theme.set_stylebox("hover", "PopupMenu", popup_hover)
	theme.set_color("font_color", "PopupMenu", palette.text)
	theme.set_color("font_hover_color", "PopupMenu", palette.text)
	theme.set_constant("icon_max_width", "Button", 22)
	theme.set_constant("h_separation", "Button", 10)
	var track := StyleBoxFlat.new()
	track.bg_color = Color.TRANSPARENT
	track.content_margin_right = 4
	theme.set_stylebox("scroll", "VScrollBar", track)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var thumb := StyleBoxFlat.new()
		thumb.bg_color = Color(palette.control, .40 if state == "grabber" else .7)
		thumb.content_margin_right = 4
		thumb.content_margin_top = 28
		thumb.set_corner_radius_all(2)
		theme.set_stylebox(state, "VScrollBar", thumb)
	return theme
