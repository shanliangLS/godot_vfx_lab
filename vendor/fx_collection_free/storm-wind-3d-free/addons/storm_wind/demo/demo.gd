extends Node3D
## Pick a kind and a style for the effect in the middle of the moor; click the ground to cast it
## there as a one-shot (an arc jumps there from the left stone). Drag to turn the camera, scroll to
## zoom.

const STAGE := preload("res://vendor/fx_collection_free/storm-wind-3d-free/addons/storm_wind/demo/stage.gd")
const START := ["storm_cloud", "storm_strike"]   # the first installed is on
const PYLON := Vector3(-2.6, 2.05, 0)
## Each kind's options in the middle, and as a one-shot where the ground is clicked.
var placing := {
	"strike": [{radius = 1.6, height = 7.0, interval = 1.4}, {radius = 1.2, height = 6.0}],
	"arc": [{position = PYLON, targets = PackedVector3Array([Vector3(5.2, 0, 0)])}, {duration = 0.6}],
	"orb": [{position = Vector3(0, 1.7, 0), radius = 1.6}, {radius = 1.1, lift = 1.3}],
	"nova": [{radius = 3.2, interval = 1.6}, {radius = 2.2}],
	"cloud": [{radius = 4.0, height = 6.5, interval = 0.9}, {radius = 2.5, height = 5.5, interval = 0.5, duration = 2.0}],
	"gust": [{radius = 3.0, height = 3.0, rotation = Vector3(0, PI / 2, 0)}, {radius = 1.6, height = 2.0}],
	"swirl": [{radius = 1.8, height = 3.0}, {radius = 1.3, height = 2.5}],
	"tornado": [{radius = 2.2, height = 6.5}, {radius = 1.4, height = 4.5, duration = 3.0}],
	"burst": [{radius = 3.5, interval = 1.6}, {radius = 2.5}],
}

var kind := ""
var style := ""
var fx: LabFxCollectionFreeStormFX
var cam := Camera3D.new()
var turn := 0.5
var distance := 13.0
var dragging := false
var dragged := 0.0
var ui := CanvasLayer.new()
var styles_row: HBoxContainer
var box := VBoxContainer.new()


func _ready() -> void:
	var stage := STAGE.new()
	stage.pylons = 2.6
	add_child(stage)
	cam.fov = 55
	add_child(cam)
	var first: String = START.filter(func(p: String) -> bool: return p in LabFxCollectionFreeStormFX.presets())[0]
	style = first.get_slice("_", 0)
	kind = first.get_slice("_", 1)
	add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	ui.add_child(panel)
	panel.add_child(box)
	box.add_child(_row("Kind", LabFxCollectionFreeStormFX.kinds(), func(k: String) -> void:
		var family := LabFxCollectionFreeStormFX.styles(kind)
		kind = k
		if LabFxCollectionFreeStormFX.styles(k) != family:
			style = LabFxCollectionFreeStormFX.styles(k)[0]
			_styles()
		_place()))
	_styles()
	var look := OptionButton.new()
	for t in ["smooth", "dither (PS1)", "cutout"]:
		look.add_item(t)
	look.item_selected.connect(func(i: int) -> void:
		LabFxCollectionFreeStormFX.default_transparency = i
		_place())
	var line := HBoxContainer.new()
	line.add_child(_caption("Transparency"))
	line.add_child(look)
	box.add_child(line)
	box.add_child(_caption("Click the ground to cast it. Drag to turn, scroll to zoom."))
	_place()


## The style buttons for the picked kind's family.
func _styles() -> void:
	var row := _row("Style", LabFxCollectionFreeStormFX.styles(kind), func(s: String) -> void:
		style = s
		_place())
	if styles_row:
		box.remove_child(styles_row)
		styles_row.queue_free()
	styles_row = row
	box.add_child(row)
	box.move_child(row, 1)


func _row(title: String, names: PackedStringArray, pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_child(_caption(title))
	var group := ButtonGroup.new()
	for n in names:
		var b := Button.new()
		b.text = n
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = n == kind or n == style
		if n in LabFxCollectionFreeStormFX.BOLT_STYLES:
			b.add_theme_color_override("font_color", LabFxCollectionFreeStormFX.BOLT_STYLES[n].edge_color.lerp(Color.WHITE, 0.4))
		elif n in LabFxCollectionFreeStormFX.WIND_STYLES:
			b.add_theme_color_override("font_color", LabFxCollectionFreeStormFX.WIND_STYLES[n].tint_a.lerp(Color.WHITE, 0.4))
		b.pressed.connect(pick.bind(n))
		row.add_child(b)
	return row


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 104
	return l


## The effect in the middle, again with the picked kind, style and transparency.
func _place() -> void:
	if fx:
		fx.free()
	fx = LabFxCollectionFreeStormFX.add(self, "%s_%s" % [style, kind], placing[kind][0])


func _process(delta: float) -> void:
	if not dragging:
		turn += delta * 0.08
	cam.position = Vector3(sin(turn), 0.42, cos(turn)) * distance
	cam.look_at(Vector3(0, 1.8, 0))


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.pressed:
		match button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				distance = maxf(distance * 0.9, 5.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				distance = minf(distance * 1.1, 22.0)
			MOUSE_BUTTON_LEFT:
				dragged = 0.0
	elif button and button.button_index == MOUSE_BUTTON_LEFT and dragged < 6.0:
		_cast(button.position)
	var motion := event as InputEventMouseMotion
	dragging = motion != null and motion.button_mask != 0
	if dragging:
		dragged += motion.relative.length()
		turn -= motion.relative.x * 0.006


## The picked effect as a one-shot where the click meets the ground.
func _cast(at: Vector2) -> void:
	var from := cam.project_ray_origin(at)
	var dir := cam.project_ray_normal(at)
	if dir.y >= -0.01:
		return
	var ground := from + dir * (-from.y / dir.y)
	var options: Dictionary = placing[kind][1].duplicate()
	options.one_shot = true
	if kind == "arc":
		options.position = PYLON
		options.targets = PackedVector3Array([ground - PYLON])
	else:
		options.position = ground + Vector3(0, options.get("lift", 0.0), 0)
	options.erase("lift")
	LabFxCollectionFreeStormFX.add(self, "%s_%s" % [style, kind], options)
