extends Node
## The island with its materials converted by LabFxCollectionFreeToon.convert, the presets to step through, and a
## control for each part of the look.

const World := preload("res://vendor/fx_collection_free/toon-look-free/addons/toon_look/demo/world.gd")
## Loaded by path: the free sampler goes without presets.
const PRESET := "res://vendor/fx_collection_free/toon-look-free/addons/toon_look/toon_preset.gd"
const BANDS := [1, 2, 3, 4]

## Hides the panel, for the store captures.
@export var no_ui := false

var world := World.new()
var _style := 0
var _band_count := 1
## Each material's own highlight, for the switch to put back.
var _shine := {}
var _bands: Button
var _style_button: Button
var _toggles := {}


func _ready() -> void:
	add_child(world)
	LabFxCollectionFreeToon.convert(world)
	world.dress()
	if no_ui:
		return
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	ui.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "TOON LOOK"
	box.add_child(title)
	if ResourceLoader.exists(PRESET):
		var presets: Array = load(PRESET).PRESETS.keys()
		var preset := Button.new()
		preset.text = "Preset: -"
		var at := [-1]
		preset.pressed.connect(func() -> void:
			at[0] = (at[0] + 1) % presets.size()
			_apply(load(PRESET).named(presets[at[0]]))
			preset.text = "Preset: " + load(PRESET).PRESETS[presets[at[0]]].title)
		box.add_child(preset)
	var styles := LabFxCollectionFreeToon.SOLID.filter(func(k: StringName) -> bool: return LabFxCollectionFreeToon.has(k))
	if styles.size() > 1:
		_style_button = Button.new()
		_style_button.text = "Shading: cel"
		_style_button.pressed.connect(func() -> void:
			_style = (_style + 1) % styles.size()
			LabFxCollectionFreeToon.restyle(world, styles[_style])
			_style_button.text = "Shading: " + styles[_style])
		box.add_child(_style_button)
	_bands = Button.new()
	_bands.text = "Bands: 1"
	_bands.pressed.connect(func() -> void:
		_band_count = BANDS[(BANDS.find(_band_count) + 1) % BANDS.size()]
		LabFxCollectionFreeToon.set_param(world, &"bands", _band_count)
		_bands.text = "Bands: %d" % _band_count)
	box.add_child(_bands)
	_toggle(box, "Outline", func(on: bool) -> void: LabFxCollectionFreeToon.set_param(world, &"outline_width", 3.0 if on else 0.0))
	_toggle(box, "Highlights", func(on: bool) -> void:
		for m in LabFxCollectionFreeToon.materials(world):
			if m not in _shine:
				_shine[m] = m.get_shader_parameter(&"specular")
			m.set_shader_parameter(&"specular", _shine[m] if on else 0.0))
	_toggle(box, "Rim light", func(on: bool) -> void:
		LabFxCollectionFreeToon.set_param(world, &"rim", 0.35 if on else 0.0)
		world.unrim_floors(), false)
	_toggle(box, "Shadows", func(on: bool) -> void: world.sun.shadow_enabled = on)
	var hint := Label.new()
	hint.text = "WASD / arrows to walk\ndrag to look"
	hint.add_theme_font_size_override("font_size", 13)
	box.add_child(hint)


## Applies `preset` and sets the controls to match.
func _apply(preset) -> void:
	preset.apply(world, world.env)
	world.unrim_floors()
	_band_count = preset.bands
	_bands.text = "Bands: %d" % _band_count
	if _style_button:
		_style = maxi(LabFxCollectionFreeToon.SOLID.find(preset.kind), 0)
		_style_button.text = "Shading: " + preset.kind
	_toggles["Outline"].set_pressed_no_signal(preset.outline_width > 0.0)
	_toggles["Rim light"].set_pressed_no_signal(preset.rim > 0.0)


func _toggle(box: Container, text: String, apply: Callable, on := true) -> void:
	var b := CheckButton.new()
	b.text = text
	b.button_pressed = on
	b.focus_mode = Control.FOCUS_NONE
	b.toggled.connect(apply)
	box.add_child(b)
	_toggles[text] = b
