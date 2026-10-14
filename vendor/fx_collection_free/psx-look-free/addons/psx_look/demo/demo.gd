extends Node
## The level through LabFxCollectionFreePSXScreen with its materials converted by LabFxCollectionFreePSX.convert, the presets to step
## through, and a switch for every part of the look.

const World := preload("res://vendor/fx_collection_free/psx-look-free/addons/psx_look/demo/world.gd")
## Loaded by path: the free sampler goes without presets.
const PRESET := "res://vendor/fx_collection_free/psx-look-free/addons/psx_look/psx_preset.gd"
const RESOLUTIONS := [240, 480, 1080]

## Hides the panel, for the store captures.
@export var no_ui := false

var psx := LabFxCollectionFreePSXScreen.new()
var world := World.new()
var _fog: Environment
var _res: Button
var _toggles := {}
var _preset := 0


func _ready() -> void:
	add_child(psx)
	psx.viewport.add_child(world)
	LabFxCollectionFreePSX.convert(world)
	world.dress()
	_fog = world.env.duplicate()
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
	title.text = "LabFxCollectionFreePSX LOOK"
	box.add_child(title)
	if ResourceLoader.exists(PRESET):
		var presets: Array = load(PRESET).PRESETS.keys()
		var preset := Button.new()
		preset.text = "Preset: PS1"
		preset.pressed.connect(func() -> void:
			_preset = (_preset + 1) % presets.size()
			_apply(load(PRESET).named(presets[_preset]))
			preset.text = "Preset: " + load(PRESET).PRESETS[presets[_preset]].title)
		box.add_child(preset)
	_res = Button.new()
	_res.pressed.connect(func() -> void:
		var i := RESOLUTIONS.find(psx.lines)
		psx.lines = RESOLUTIONS[(i + 1) % RESOLUTIONS.size()]
		_res_text())
	_res_text()
	box.add_child(_res)
	_toggle(box, "Vertex snap", func(on: bool) -> void: LabFxCollectionFreePSX.set_param(world, &"snap_pixels", 1.0 if on else 0.0))
	_toggle(box, "Affine textures", func(on: bool) -> void: LabFxCollectionFreePSX.set_param(world, &"affine", 1.0 if on else 0.0))
	if psx.material:
		_toggle(box, "Dither", func(on: bool) -> void: psx.dither = on)
		_toggle(box, "15-bit colour", func(on: bool) -> void: psx.color_bits = 5 if on else 8)
	_toggle(box, "Fog", func(on: bool) -> void: world.env.fog_enabled = on)
	var hint := Label.new()
	hint.text = "WASD / arrows to walk\ndrag to look"
	hint.add_theme_font_size_override("font_size", 13)
	box.add_child(hint)


## Applies `preset` over the level's own fog and sets the switches to match.
func _apply(preset) -> void:
	for p in [&"fog_light_color", &"fog_light_energy", &"fog_depth_begin", &"fog_depth_end", &"fog_sky_affect"]:
		world.env.set(p, _fog.get(p))
	world.env.fog_enabled = true
	preset.apply(psx, world, world.env)
	_res_text()
	for t: Array in [["Vertex snap", preset.snap_pixels > 0.0], ["Affine textures", preset.affine > 0.0],
			["Dither", preset.dither], ["15-bit colour", preset.color_bits < 8], ["Fog", true]]:
		if t[0] in _toggles:
			_toggles[t[0]].set_pressed_no_signal(t[1])


func _res_text() -> void:
	_res.text = "Resolution: " + ("Native" if psx.lines >= 1080 else "%dp" % psx.lines)


func _toggle(box: Container, text: String, apply: Callable) -> void:
	var b := CheckButton.new()
	b.text = text
	b.button_pressed = true
	b.focus_mode = Control.FOCUS_NONE
	b.toggled.connect(apply)
	box.add_child(b)
	_toggles[text] = b
