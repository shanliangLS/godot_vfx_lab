extends Node
## Every preset over a 3D or a 2D scene. The buttons sit on a layer above the effect.

const SCENE_3D := preload("res://vendor/fx_collection_free/retro-screen-fx-free/addons/retro_screen/demo/scene_3d.gd")
const SCENE_2D := preload("res://vendor/fx_collection_free/retro-screen-fx-free/addons/retro_screen/demo/scene_2d.gd")

@export var preset := LabFxCollectionFreeRetroScreen.Preset.CRT
@export var three_d := true
## Hides the buttons, for the store captures.
@export var no_ui := false

var world: Node
var retro := LabFxCollectionFreeRetroScreen.new()


func _ready() -> void:
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST  # project.godot's, for a project without it
	retro.preset = preset
	add_child(retro)
	show_world(three_d)
	if no_ui:
		return
	var ui := CanvasLayer.new()
	ui.layer = 101
	add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	ui.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "RETRO SCREEN FX"
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
	for p in LabFxCollectionFreeRetroScreen.Preset.values():
		var b := Button.new()
		b.text = LabFxCollectionFreeRetroScreen.Preset.find_key(p).replace("_", " ")
		b.pressed.connect(func() -> void: retro.preset = p)
		grid.add_child(b)
	var toggle := Button.new()
	toggle.text = "Switch 2D / 3D"
	toggle.pressed.connect(func() -> void: show_world(not three_d))
	box.add_child(toggle)


func show_world(is_3d: bool) -> void:
	three_d = is_3d
	if world:
		world.queue_free()
	world = SCENE_3D.new() if is_3d else SCENE_2D.new()
	add_child(world)
	move_child(world, 0)
