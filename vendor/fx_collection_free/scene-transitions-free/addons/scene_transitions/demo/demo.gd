extends Control
## Two demo scenes, meadow and dungeon. Every button changes to the other one with its style.

const ART := "res://vendor/fx_collection_free/scene-transitions-free/addons/scene_transitions/demo/art/%s.png"
const OTHER := ["res://vendor/fx_collection_free/scene-transitions-free/addons/scene_transitions/demo/demo_b.tscn", "res://vendor/fx_collection_free/scene-transitions-free/addons/scene_transitions/demo/demo.tscn"]

@export var dungeon := false
## Hides the buttons, for the store captures.
@export var scenery_only := false


func _ready() -> void:
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST  # project.godot's, for a project without it
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var size := get_viewport_rect().size
	var props := [["chest", 0.2], ["crystal", 0.42], ["ghost", 0.62], ["potion", 0.82]] if dungeon \
			else [["bush", 0.16], ["mushroom", 0.36], ["slime", 0.6], ["coin", 0.84]]
	for p in props:
		var s := TextureRect.new()
		s.texture = load(ART % p[0])
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.size = s.texture.get_size() * 4.0
		s.position = Vector2(size.x * p[1], size.y * 0.62) - Vector2(s.size.x * 0.5, s.size.y)
		add_child(s)
	var title := Label.new()
	title.text = "DUNGEON" if dungeon else "MEADOW"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	title.position = Vector2(28, 18)
	add_child(title)
	if scenery_only:
		return
	var hint := Label.new()
	hint.text = "Scene Transitions  ·  pick a style"
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	hint.position = Vector2(30, 70)
	add_child(hint)
	var styles := LabFxCollectionFreeSceneTransition.styles()
	var cols := 12 if styles.size() > 32 else 8
	var grid := GridContainer.new()
	grid.columns = cols
	grid.position = Vector2(20, size.y * 0.66)
	grid.size = Vector2(size.x - 40, size.y * 0.32)
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	for style in styles:
		var b := Button.new()
		b.text = String(style)
		b.custom_minimum_size = Vector2((size.x - 40 - (cols - 1) * 6) / cols, 50 if cols == 8 else 44)
		b.pressed.connect(_go.bind(style, b))
		grid.add_child(b)


func _go(style: StringName, from: Control) -> void:
	var center := (from.global_position + from.size * 0.5) / get_viewport_rect().size
	LabFxCollectionFreeSceneTransition.change_scene(OTHER[int(dungeon)], style, {center = center,
		color = Color(0.06, 0.05, 0.12)})


func _draw() -> void:
	var size := get_viewport_rect().size
	var top := Color(0.18, 0.13, 0.3) if dungeon else Color(0.45, 0.72, 0.95)
	var bottom := Color(0.1, 0.07, 0.16) if dungeon else Color(0.85, 0.93, 1.0)
	for y in int(size.y * 0.62):
		draw_line(Vector2(0, y), Vector2(size.x, y), top.lerp(bottom, y / (size.y * 0.62)))
	if dungeon:
		for row in 12:
			var yy := row * 36.0
			for col in range(-1, int(size.x / 72.0) + 1):
				var r := Rect2(col * 72.0 + (row % 2) * 36.0, yy, 70, 34)
				draw_rect(r, Color(1, 1, 1, 0.035 + 0.02 * ((row * 7 + col * 3) % 3)))
		draw_rect(Rect2(0, size.y * 0.62, size.x, size.y), Color(0.2, 0.16, 0.26))
		draw_rect(Rect2(0, size.y * 0.62, size.x, 8), Color(0.35, 0.3, 0.45))
	else:
		draw_circle(Vector2(size.x * 0.82, size.y * 0.18), size.y * 0.08, Color(1.0, 0.92, 0.6))
		for i in 3:
			var hill := PackedVector2Array()
			var base := size.y * (0.5 + i * 0.05)
			for x in range(0, int(size.x) + 41, 40):
				hill.append(Vector2(x, base - sin(x * 0.006 + i * 2.0) * size.y * 0.06))
			hill.append(Vector2(size.x + 40, size.y))
			hill.append(Vector2(0, size.y))
			draw_colored_polygon(hill, Color(0.35, 0.62, 0.35).darkened(0.12 * i))
		draw_rect(Rect2(0, size.y * 0.62, size.x, size.y), Color(0.3, 0.5, 0.28))
		draw_rect(Rect2(0, size.y * 0.62, size.x, 8), Color(0.45, 0.72, 0.4))
