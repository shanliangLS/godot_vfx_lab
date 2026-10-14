class_name LabTheme extends RefCounted

const BG := Color("0c1220")
const PANEL := Color("131d2d")
const TEXT := Color("e4edf8")
const MUTED := Color("8da2be")
const ACCENT := Color("5de2d3")
const GOLD := Color("ffc786")

static func box(color: Color, radius: int = 10, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.set_corner_radius_all(radius)
	result.set_content_margin_all(12)
	if border.a > 0:
		result.border_color = border
		result.set_border_width_all(1)
	return result

static func build() -> Theme:
	var result := Theme.new()
	result.default_font_size = 15
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC"])
	result.default_font = font
	for cls in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit", "SpinBox", "Tree", "ItemList"]:
		result.set_color("font_color", cls, TEXT)
		result.set_color("font_hover_color", cls, Color.WHITE)
		result.set_color("font_pressed_color", cls, ACCENT)
	for cls in ["Button", "OptionButton"]:
		result.set_stylebox("normal", cls, box(Color("1b2940"), 7))
		result.set_stylebox("hover", cls, box(Color("243a53"), 7, Color("40627b")))
		result.set_stylebox("pressed", cls, box(Color("1b4449"), 7, ACCENT))
		result.set_stylebox("focus", cls, box(Color.TRANSPARENT, 7, ACCENT))
	result.set_stylebox("panel", "PanelContainer", box(PANEL))
	result.set_stylebox("panel", "PopupPanel", box(PANEL, 10, Color("40627b")))
	result.set_stylebox("normal", "LineEdit", box(Color("0e1727"), 6))
	result.set_stylebox("focus", "LineEdit", box(Color("0e1727"), 6, ACCENT))
	result.set_stylebox("panel", "Tree", box(Color("0f1828"), 7))
	result.set_stylebox("selected", "Tree", box(Color("23414b"), 4))
	result.set_stylebox("selected_focus", "Tree", box(Color("23414b"), 4))
	result.set_constant("separation", "VBoxContainer", 10)
	result.set_constant("separation", "HBoxContainer", 10)
	return result

static func configure_color_picker(button: ColorPickerButton) -> void:
	# Popup windows need their own opaque panel, including gradient point pickers.
	var popup := button.get_popup()
	popup.transparent_bg = false
	popup.add_theme_stylebox_override("panel", box(PANEL, 10, Color("40627b")))

static func label(text: String, size: int = 15, color: Color = TEXT) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

static func button(text: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.pressed.connect(callback)
	return result
