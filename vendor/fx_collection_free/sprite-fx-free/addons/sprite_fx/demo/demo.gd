extends Node2D
## Every effect in the pack on one screen. Click a sprite to hit it (LabFxCollectionFreeSpriteFX.flash).

const HEADER := 64.0
const ART := "res://vendor/fx_collection_free/sprite-fx-free/addons/sprite_fx/demo/art/%s.png"

## Effect, sprite, shader parameters: the effects installed show, in this order.
const CELLS := [
	[&"outline", "slime", {outline_color = Color.WHITE, width = 1.0}],
	[&"glow_outline", "crystal", {glow_color = Color(0.35, 0.8, 1.0), radius = 6.0, grow = 6.0}],
	[&"dissolve", "ghost", {edge_color = Color(1.0, 0.5, 0.1)}],
	[&"burn", "chest", {}],
	[&"flash", "slime", {}],
	[&"palette_swap", "slime", {}],
	[&"hologram", "ghost", {}],
	[&"freeze", "slime", {}],
	[&"wind_sway", "bush", {strength = 5.0}],
	[&"shine", "coin", {}],
	[&"glitch", "heart", {strength = 0.7}],
	[&"hue_shift", "potion", {speed = 0.35}],
	[&"stone", "mushroom", {}],
	[&"wave", "potion", {amplitude = 1.5}],
	[&"blink", "heart", {rate = 6.0}],
	[&"pulse_tint", "mushroom", {}],
	[&"jelly", "slime", {amount = 0.1}],
	[&"gradient_map", "chest", {}],
	[&"chromatic", "ghost", {offset = 2.0, wobble_speed = 3.0}],
	[&"cloak", "ghost", {}],
	[&"rim_light", "mushroom", {rim_color = Color(1.0, 0.85, 0.5), width = 2.0}],
	[&"invert", "sword", {}],
	[&"dither_fade", "potion", {}],
	[&"silhouette", "sword", {tint_color = Color(0.08, 0.08, 0.14)}],
	[&"pixelate", "heart", {}],
	[&"drop_shadow", "coin", {grow = 3.0}],
	[&"adjust", "bush", {brightness = -0.15, saturation = 0.35, tint = Color(0.6, 0.7, 1.0)}],
	[&"posterize", "coin", {monochrome = true}],
	[&"shake", "chest", {speed = 20.0}],
	[&"swirl", "ghost", {}],
	[&"electric", "slime", {grow = 2.0}],
	[&"fire_aura", "sword", {height = 6.0, grow = 6.0}],
	[&"cracks", "crystal", {}],
	[&"motion_blur", "slime", {strength = 10.0, grow = 10.0}],
	[&"teleport", "heart", {}],
	[&"metal", "mushroom", {}],
	[&"afterimage", "ghost", {spacing = 3.0, grow = 9.0}],
	[&"submerge", "bush", {}],
	[&"disintegrate", "potion", {drift = 10.0, grow = 12.0}],
	[&"cooldown", "potion", {}],
]
var cells := CELLS.filter(func(c: Array) -> bool: return LabFxCollectionFreeSpriteFX.SHADERS.has(c[0]))
var cols := 8 if cells.size() > 25 else (5 if cells.size() > 9 else 3)
var sprites: Array[Sprite2D] = []
var t := 0.0


func _ready() -> void:
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST  # project.godot's, for a project without it
	var size := get_viewport_rect().size
	var cell := _cell()
	for i in cells.size():
		var effect: StringName = cells[i][0]
		var s := Sprite2D.new()
		s.texture = load(ART % cells[i][1])
		var k := minf(3.0 * cell.y / 131.0, 88.0 * cell.y / 131.0 / s.texture.get_height())
		s.scale = Vector2(k, k)
		var center := Vector2((i % cols + 0.5) * cell.x, HEADER + (i / cols) * cell.y + cell.y * 0.43)
		s.position = center
		add_child(s)
		setup(effect, LabFxCollectionFreeSpriteFX.apply(s, effect, cells[i][2]))
		sprites.append(s)
		var label := Label.new()
		label.text = String(effect).replace("_", " ")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
		label.size = Vector2(cell.x, 20)
		label.position = Vector2(center.x - cell.x / 2, HEADER + (i / cols + 1) * cell.y - 26)
		add_child(label)
	var title := Label.new()
	title.text = "%s  ·  %d shaders for Godot 4" % [
		String(ProjectSettings.get_setting("application/config/name")).to_upper(), cells.size()]
	title.add_theme_font_size_override("font_size", 26)
	title.position = Vector2(24, 14)
	add_child(title)
	var hint := Label.new()
	hint.text = "click a sprite"
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.55, 0.58, 0.7))
	hint.position = Vector2(size.x - 130, 24)
	add_child(hint)


## The parameters a cell's effect needs that a dictionary can't give: palette_swap's colours,
## gradient_map's gradient.
static func setup(effect: StringName, mat: ShaderMaterial) -> void:
	match effect:
		&"palette_swap":
			var from := [Color8(56, 183, 100), Color8(37, 113, 121), Color8(167, 240, 112)]
			var to := [Color8(177, 62, 83), Color8(93, 39, 93), Color8(239, 125, 87)]
			from.resize(8)
			to.resize(8)
			for j in 8:
				from[j] = from[j] if from[j] != null else Color.BLACK
				to[j] = to[j] if to[j] != null else Color.BLACK
			mat.set_shader_parameter(&"count", 3)
			mat.set_shader_parameter(&"from_colors", PackedColorArray(from))
			mat.set_shader_parameter(&"to_colors", PackedColorArray(to))
		&"gradient_map":
			var g := Gradient.new()
			g.set_color(0, Color(0.1, 0.02, 0.2))
			g.set_color(1, Color(1.0, 0.95, 0.6))
			g.add_point(0.45, Color(0.9, 0.25, 0.35))
			var gt := GradientTexture1D.new()
			gt.gradient = g
			mat.set_shader_parameter(&"gradient", gt)


func _process(delta: float) -> void:
	t += delta
	for i in cells.size():
		var mat := sprites[i].material as ShaderMaterial
		if mat != null:
			drive(cells[i][0], mat, t)


## Runs the one-shot effects on a 3-second loop, as the demo shows them.
static func drive(effect: StringName, mat: ShaderMaterial, t: float) -> void:
	var loop := fmod(t, 3.0) / 3.0
	var ping := clampf(1.0 - absf(loop * 2.0 - 1.0) * 1.4, 0.0, 1.0)  # 0 → 1 → 0 with holds
	match effect:
		&"dissolve", &"burn", &"cracks", &"teleport", &"disintegrate":
			mat.set_shader_parameter(&"progress", ping)
		&"cooldown":
			mat.set_shader_parameter(&"progress", 1.0 - loop)
		&"swirl":
			mat.set_shader_parameter(&"angle", ping * 540.0)
		&"dither_fade":
			mat.set_shader_parameter(&"fade", ping)
		&"silhouette":
			mat.set_shader_parameter(&"amount", ping)
		&"invert":
			mat.set_shader_parameter(&"amount", 1.0 if fmod(t, 1.5) < 0.12 else 0.0)
		&"flash":
			mat.set_shader_parameter(&"flash_amount", maxf(0.0, 1.0 - fmod(t, 1.2) / 0.2))
		&"pixelate":
			mat.set_shader_parameter(&"pixel_size", float(1 + int(ping * 5.0)))


func _draw() -> void:
	var size := get_viewport_rect().size
	for x in range(-int(size.y), int(size.x), 24):
		draw_line(Vector2(x, size.y), Vector2(x + size.y, 0), Color(1, 1, 1, 0.025), 8.0)
	var cell := _cell()
	for i in cells.size():
		var r := Rect2(Vector2(i % cols * cell.x, HEADER + i / cols * cell.y) + Vector2(6, 6), cell - Vector2(12, 12))
		draw_rect(r, Color(0.15, 0.17, 0.27, 0.85))


func _cell() -> Vector2:
	var size := get_viewport_rect().size
	return Vector2(size.x / cols, (size.y - HEADER) / ceili(cells.size() / float(cols)))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		for s in sprites:
			if s.get_rect().has_point(s.to_local(event.position)):
				var mat := s.material
				s.material = null
				LabFxCollectionFreeSpriteFX.flash(s, Color.WHITE, 0.2).finished.connect(func() -> void: s.material = mat)
