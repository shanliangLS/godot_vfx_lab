extends Node2D
## Turn effects on and off over a pixel-art landscape; they stack. Pick a weather state for a
## LabFxCollectionFreeWeatherSystem to cross-fade to. Click to strike lightning.

const LANDSCAPE := preload("res://vendor/fx_collection_free/weather-fx-free/addons/weather_fx/demo/landscape.gd")
const ZOOM := 4
const GROUND := 0.66
const LAKE := 0.69
const START := ["water", "fog", "god_rays", "snow"]   # the first three installed are on
const RESHAPE := ["waterfall", "sun", "moon"]          # the landscape changes under them

var land: Node2D
var mood := "dusk"
var active := {}
var buttons := {}
var weather := CanvasLayer.new()
var states := CanvasLayer.new()
var system := LabFxCollectionFreeWeatherSystem.new()
var haze := CanvasLayer.new()
var glass := CanvasLayer.new()


func _ready() -> void:
	# Water, heat haze and rain_window read the screen as it was when the first of them drew on
	# their layer: the landscape goes below them, heat haze and rain_window on layers of their own,
	# to see the water and then all the weather.
	weather.layer = 1
	add_child(weather)
	states.layer = 2
	add_child(states)
	system.ground = GROUND
	states.add_child(system)
	system.weather_changed.connect(func(_s: String) -> void: _build_land())
	haze.layer = 3
	add_child(haze)
	glass.layer = 4
	add_child(glass)
	var ui := CanvasLayer.new()
	ui.layer = 10      # above the weather, so day_night doesn't tint it
	add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	ui.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var moods := OptionButton.new()
	for m in LANDSCAPE.MOODS:
		moods.add_item(m)
	moods.select(LANDSCAPE.MOODS.keys().find(mood))
	moods.item_selected.connect(func(i: int) -> void:
		mood = moods.get_item_text(i)
		_build_land())
	box.add_child(moods)
	var row := HBoxContainer.new()
	box.add_child(row)
	var title := Label.new()
	title.text = "Weather"
	row.add_child(title)
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for s in LabFxCollectionFreeWeatherSystem.states():
		picker.add_item(s)
	picker.item_selected.connect(func(i: int) -> void: system.change(picker.get_item_text(i), 2.0))
	row.add_child(picker)
	var grid := GridContainer.new()
	grid.columns = 2 if LabFxCollectionFreeWeatherFX.effects().size() > 10 else 1
	grid.add_theme_constant_override("v_separation", 0)
	box.add_child(grid)
	for name in LabFxCollectionFreeWeatherFX.effects():
		var b := CheckButton.new()
		b.text = name
		b.custom_minimum_size = Vector2(170, 0)
		b.toggled.connect(func(on: bool) -> void: _toggle(name, on))
		grid.add_child(b)
		buttons[name] = b
	var pixel := CheckBox.new()
	pixel.text = "pixel art"
	pixel.toggled.connect(func(on: bool) -> void: LabFxCollectionFreeWeatherFX.default_pixel_size = ZOOM if on else 0)
	box.add_child(pixel)
	if "lightning" in LabFxCollectionFreeWeatherFX.effects():
		var hint := Label.new()
		hint.text = "Click to strike lightning."
		hint.position = Vector2(panel.get_combined_minimum_size().x + 40, 16)
		hint.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.12))
		hint.add_theme_constant_override("outline_size", 8)
		ui.add_child(hint)
	_build_land()
	for name in START.filter(func(e: String) -> bool: return e in buttons).slice(0, 3):
		buttons[name].button_pressed = true


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and "lightning" in buttons:
		if system.get_effect("lightning"):
			system.get_effect("lightning").strike()
			return
		buttons["lightning"].button_pressed = true
		active["lightning"].strike()


func _build_land() -> void:
	if land:
		land.queue_free()
	land = LANDSCAPE.new()
	land.mood = mood
	land.art_size = Vector2i(get_viewport_rect().size) / ZOOM
	land.zoom = ZOOM
	land.ground = GROUND
	land.lake = LAKE if "water" in buttons or "ripples" in buttons else 0.0   # no bare lake without water
	land.cliff = 0.2 if "waterfall" in active else 0.0
	land.body = not ("sun" in active or "moon" in active or system.get_effect("sun"))   # one sun or moon in the sky
	land.sprites = [["bush", 0.36], ["mushroom", 0.5], ["slime", 0.66], ["chest", 0.88]]
	add_child(land)
	move_child(land, 0)


func _toggle(name: String, on: bool) -> void:
	if not on:
		if name in active:
			active[name].stop(0.4)
			active.erase(name)
		if name in RESHAPE:
			_build_land()
		return
	var size := get_viewport_rect().size
	var options := {}
	match name:
		"water", "ripples":
			options = {position = Vector2(0, land.lake_y()), size = Vector2(size.x, size.y - land.lake_y())}
		"waterfall":
			var top := int(land.art_size.y * 0.2) * ZOOM - 4.0
			options = {position = Vector2(size.x * 0.5 - 48, top), size = Vector2(96, land.lake_y() - top + 24)}
		"lightning", "tornado":
			options = {ground = GROUND}
		"rain", "hail":
			options = {ground = 1.0 if land.lake > 0.0 else GROUND + 0.01}
	var layer := {heat_haze = haze, rain_window = glass}.get(name, weather) as CanvasLayer
	active[name] = LabFxCollectionFreeWeatherFX.add(layer, name, options).fade_in(0.4)
	if name in RESHAPE:
		_build_land()
	# Keep the drawing order of LabFxCollectionFreeWeatherFX.EFFECTS: water under the rain, day_night over all.
	var i := 0
	for e in LabFxCollectionFreeWeatherFX.EFFECTS:
		if e in active and active[e].get_parent() == weather:
			weather.move_child(active[e], i)
			i += 1
