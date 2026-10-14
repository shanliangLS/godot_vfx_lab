extends Node3D
## REEBOO Stylized VFX showcase.
## Left / Right: switch effect   Space: replay   A: auto-advance on/off   Esc: quit
##
## Recording mode (used for the store previews): pass "++ --fx=explosion" on the command line
## to show a single effect on repeat with no UI.

const EFFECT_DIR := "res://vendor/reeboo_free/REEBOO_Stylized_VFX_Free_Sample/addons/reeboo_vfx/effects/"
const GROUND_SHADER := preload("res://vendor/reeboo_free/REEBOO_Stylized_VFX_Free_Sample/demo/ground.gdshader")
## The free sample shows a link to the full pack (hidden when every effect is present).
const FULL_PACK_EFFECTS := 25
const FULL_PACK_URL := "https://reebo0.itch.io/stylized-vfx-godot"

## Camera framing per effect: [look-at height, distance, camera height].
const FRAMING := {
	"explosion": [1.4, 7.5, 2.8], "lightning_strike": [3.2, 12.0, 3.0], "level_up": [2.2, 9.0, 2.6],
	"muzzle_flash": [1.2, 3.6, 1.6], "pickup_sparkle": [0.6, 3.6, 1.4], "slash": [0.9, 5.0, 3.4],
	"fireball": [1.2, 8.0, 3.2], "fire_impact": [0.4, 4.5, 1.8], "portal": [1.7, 7.0, 2.2], "ground_slam": [0.4, 8.0, 3.0],
	"hit_spark": [1.0, 4.5, 1.8], "campfire": [0.8, 5.0, 2.0], "burning": [1.0, 5.0, 2.0],
	"smoke_poof": [0.8, 5.0, 2.0], "collect_burst": [0.8, 4.5, 1.8], "electric_hit": [1.0, 4.5, 1.8],
	"arcane_missile": [1.2, 8.0, 3.2], "water_splash": [0.8, 6.5, 2.8], "power_aura": [0.8, 5.5, 2.4],
}
const DEFAULT_FRAMING := [1.0, 7.0, 2.6]

var effects: Array[String] = []
var index := 0
var current: VFXEffect
var camera: Camera3D
var title: Label
var counter: Label
var auto_advance := true
var record := ""
var orbit := 0.6
var since_play := 0.0
var plays := 0
var clock := 0.0
var next_event := 0.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fx="):
			record = arg.trim_prefix("--fx=")
	for file in ResourceLoader.list_directory(EFFECT_DIR):
		if file.ends_with(".tscn"):
			effects.append(file.get_basename())
	effects.sort()
	_build_world()
	if record.is_empty():
		_build_ui()
	else:
		index = maxi(effects.find(record), 0)
		auto_advance = false
	_show(index)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		_show((index + 1) % effects.size())
	elif event.is_action_pressed("ui_left"):
		_show((index - 1 + effects.size()) % effects.size())
	elif event.is_action_pressed("ui_accept"):
		_replay()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_A:
		auto_advance = not auto_advance
		_update_counter()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _process(delta: float) -> void:
	clock += delta
	since_play += delta
	orbit += delta * 0.12
	var frame: Array = FRAMING.get(effects[index], DEFAULT_FRAMING)
	camera.position = Vector3(sin(orbit) * frame[1], frame[2], cos(orbit) * frame[1])
	camera.look_at(Vector3(0, frame[0], 0))

	match effects[index]:
		"fireball", "arcane_missile":
			# Fly in a circle so the trail shows.
			var t := clock * 1.6
			current.position = Vector3(cos(t) * 2.2, 1.2 + sin(t * 2.0) * 0.2, sin(t) * 2.2)
		"shield":
			if clock > next_event:
				next_event = clock + 1.1
				var dir := Vector3(randf_range(-1, 1), randf_range(0.1, 1), randf_range(-1, 1)).normalized()
				current.impact(current.global_position + Vector3(0, 0.2, 0) + dir * 1.6)
		"muzzle_flash":
			# Rapid fire: each shot is its own instance that frees itself.
			if clock > next_event:
				next_event = clock + (0.12 if fmod(clock, 2.0) < 1.2 else 0.6)
				_spawn_shot()

	if not current.is_looping() and effects[index] != "muzzle_flash":
		if since_play > current.get_duration() + 0.7:
			plays += 1
			if auto_advance and plays >= 2:
				_show((index + 1) % effects.size())
			else:
				_replay()
	elif auto_advance and since_play > 6.0:
		_show((index + 1) % effects.size())


func _show(i: int) -> void:
	index = i
	if current:
		current.queue_free()
	current = load(EFFECT_DIR + effects[index] + ".tscn").instantiate()
	current.auto_free = false
	match effects[index]:
		"hit_spark":
			current.position = Vector3(0, 1.0, 0)
		"muzzle_flash":
			current.autoplay = false
			current.position = Vector3(-0.8, 1.2, 0)
			current.rotation_degrees = Vector3(0, -90, 0)
	add_child(current)
	plays = 0
	since_play = 0.0
	next_event = 0.0
	if title:
		title.text = effects[index].capitalize()
		_update_counter()


func _replay() -> void:
	since_play = 0.0
	current.play()


func _spawn_shot() -> void:
	var shot := load(EFFECT_DIR + "muzzle_flash.tscn").instantiate() as VFXEffect
	add_child(shot)
	shot.global_transform = current.global_transform


func _update_counter() -> void:
	counter.text = "%d / %d    ← →  switch    Space  replay    A  auto %s" % [
		index + 1, effects.size(), "on" if auto_advance else "off"]


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.035, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.4, 0.55)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	# Small and medium blur levels only: tight halos instead of a haze over the whole frame.
	var levels := [0.0, 1.0, 1.0, 0.7, 0.3, 0.0, 0.0]
	for level in 7:
		env.set_glow_level(level, levels[level])
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.6, 0.7, 1.0)
	moon.light_energy = 0.35
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-55, 35, 0)
	add_child(moon)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	ground.mesh = plane
	var ground_mat := ShaderMaterial.new()
	ground_mat.shader = GROUND_SHADER
	ground.material_override = ground_mat
	add_child(ground)

	# A ring of low stone blocks catches the effects' light.
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.11, 0.115, 0.13)
	stone.roughness = 0.85
	for k in 8:
		var block := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.6 + 1.4 * fmod(k * 0.37, 1.0), 1.2)
		block.mesh = box
		block.material_override = stone
		var a := TAU * k / 8.0 + 0.3
		block.position = Vector3(cos(a) * 7.5, box.size.y * 0.5, sin(a) * 7.5)
		block.rotation.y = a
		add_child(block)

	camera = Camera3D.new()
	camera.fov = 50.0
	add_child(camera)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var big := LabelSettings.new()
	big.font_size = 34
	big.outline_size = 10
	big.outline_color = Color(0, 0, 0, 0.6)
	title = Label.new()
	title.label_settings = big
	title.position = Vector2(32, 24)
	ui.add_child(title)
	var small := LabelSettings.new()
	small.font_size = 16
	small.font_color = Color(1, 1, 1, 0.7)
	small.outline_size = 6
	small.outline_color = Color(0, 0, 0, 0.6)
	counter = Label.new()
	counter.label_settings = small
	counter.position = Vector2(34, 72)
	ui.add_child(counter)
	var brand := Label.new()
	brand.text = "REEBOO Labs · Stylized VFX"
	brand.label_settings = small
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(brand)
	brand.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	brand.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	brand.offset_left = -360
	brand.offset_right = -32
	brand.offset_top = 28
	if effects.size() < FULL_PACK_EFFECTS:
		var upsell := LinkButton.new()
		upsell.text = "Free sample: %d of %d effects.  Get the full pack: %s" % [effects.size(), FULL_PACK_EFFECTS, FULL_PACK_URL.trim_prefix("https://")]
		upsell.uri = FULL_PACK_URL
		upsell.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
		upsell.add_theme_font_size_override("font_size", 18)
		upsell.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		upsell.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		upsell.add_theme_constant_override("outline_size", 6)
		ui.add_child(upsell)
		upsell.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		upsell.offset_left = 34
		upsell.offset_top = -52
		upsell.offset_bottom = -24
