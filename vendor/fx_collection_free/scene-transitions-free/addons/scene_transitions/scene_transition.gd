class_name LabFxCollectionFreeSceneTransition
extends CanvasLayer
## Full-screen transitions with nothing to set up: the layer adds itself to the tree on first use.
##
##     await LabFxCollectionFreeSceneTransition.change_scene("res://vendor/fx_collection_free/scene-transitions-free/level_2.tscn", &"diamonds")
##     await LabFxCollectionFreeSceneTransition.cover(&"iris", {center = $Player})   # then do anything, then
##     await LabFxCollectionFreeSceneTransition.reveal(&"iris")
##
## A style is a name from styles() or any greyscale Texture2D (black covers first). Options are
## duration, color, ease, trans, reveal_style, center (UV, or a 2D or 3D node to close on) and any
## uniform of the style's shader.

const TRANSITION := preload("res://vendor/fx_collection_free/scene-transitions-free/addons/scene_transitions/transition.gdshader")
const SCREEN_PATH := "res://vendor/fx_collection_free/scene-transitions-free/addons/scene_transitions/screen.gdshader"
const MASK_PATH := "res://vendor/fx_collection_free/scene-transitions-free/addons/scene_transitions/masks/%s.png"

## Order matches the `style` enum of each shader; 17 is the transition shader's mask style.
const PATTERNS: Array[StringName] = [&"fade", &"dither", &"wipe", &"diamonds", &"circles", &"iris",
	&"clock", &"blinds", &"checker", &"noise", &"spiral", &"curtain", &"zigzag", &"shards", &"bars",
	&"hexagons", &"tiles", &"mask", &"triangles", &"waves", &"rays", &"box", &"interlace", &"rings",
	&"bubbles", &"pinwheel"]
const MASK_STYLE := 17
const SCREEN_STYLES: Array[StringName] = [&"pixelate", &"swirl", &"ripple", &"zoom", &"slice", &"melt", &"tv",
	&"wave", &"blur"]
const MASK_NAMES: Array[StringName] = [&"bricks", &"burst", &"clouds", &"cracks", &"drip", &"fan", &"flames",
	&"heart", &"moon", &"paw", &"shatter", &"spots", &"star", &"whirl"]
const DEFAULTS := {duration = 0.45, color = Color.BLACK, ease = Tween.EASE_IN_OUT,
	trans = Tween.TRANS_SINE}
const NOT_UNIFORMS: Array[StringName] = [&"duration", &"ease", &"trans", &"reveal_style"]

static var _instance: LabFxCollectionFreeSceneTransition
static var _screen: Shader
static var _masks := {}
static var _patterns: Array[StringName] = []

var rect := ColorRect.new()
var _tween: Tween


static func styles() -> Array[StringName]:
	var all := patterns()
	if screen_shader():
		all.append_array(SCREEN_STYLES)
	all.append_array(masks().keys())
	return all


## The patterns the transition shader has: a sampler's has fewer.
static func patterns() -> Array[StringName]:
	if _patterns.is_empty():
		for i in PATTERNS.size():
			if i == MASK_STYLE:
				continue
			if i == 0 or RegEx.create_from_string("style == %d\\b" % i).search(TRANSITION.code):
				_patterns.append(PATTERNS[i])
	return _patterns.duplicate()


static func screen_shader() -> Shader:
	if _screen == null and ResourceLoader.exists(SCREEN_PATH):
		_screen = load(SCREEN_PATH)
	return _screen


static func masks() -> Dictionary:
	if _masks.is_empty():
		for m in MASK_NAMES:
			if ResourceLoader.exists(MASK_PATH % m):
				_masks[m] = load(MASK_PATH % m)
	return _masks


static func instance() -> LabFxCollectionFreeSceneTransition:
	if not is_instance_valid(_instance):
		_instance = LabFxCollectionFreeSceneTransition.new()
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_instance)
	return _instance


## Covers the screen. The cover stays until reveal().
static func cover(style: Variant = &"fade", options := {}) -> void:
	await instance()._play(style, options, 0.0, 1.0)


## Uncovers the screen, playing the style backwards.
static func reveal(style: Variant = &"fade", options := {}) -> void:
	await instance()._play(style, options, 1.0, 0.0)


## Covers, swaps the current scene for `scene` (path or PackedScene), reveals. A path loads on a
## thread while the cover plays.
static func change_scene(scene: Variant, style: Variant = &"fade", options := {}) -> void:
	var t := instance()
	options = t._resolved(options)
	if scene is String:
		ResourceLoader.load_threaded_request(scene)
	await cover(style, options)
	var packed: PackedScene = scene if scene is PackedScene else null
	if scene is String:
		while ResourceLoader.load_threaded_get_status(scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await t.get_tree().process_frame
		packed = ResourceLoader.load_threaded_get(scene)
	t.get_tree().change_scene_to_packed(packed)
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	await reveal(options.get(&"reveal_style", style), options)


static func is_playing() -> bool:
	return is_instance_valid(_instance) and _instance._tween != null and _instance._tween.is_running()


## Material for a style with options applied, for driving `progress` yourself (AnimationPlayer etc.).
static func make_material(style: Variant, options := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	if style is String:
		style = StringName(style)
	if style is Texture2D:
		m.shader = TRANSITION
		m.set_shader_parameter(&"style", MASK_STYLE)
		m.set_shader_parameter(&"mask", style)
	elif style in SCREEN_STYLES and screen_shader():
		m.shader = screen_shader()
		m.set_shader_parameter(&"style", SCREEN_STYLES.find(style))
	elif style in masks():
		m.shader = TRANSITION
		m.set_shader_parameter(&"style", MASK_STYLE)
		m.set_shader_parameter(&"mask", masks()[style])
		m.set_shader_parameter(&"softness", 0.08)
	else:
		if style not in patterns():
			push_error("LabFxCollectionFreeSceneTransition: unknown style %s, using fade" % style)
		m.shader = TRANSITION
		m.set_shader_parameter(&"style", maxi(PATTERNS.find(style), 0) if style in patterns() else 0)
	for key in options:
		if StringName(key) not in NOT_UNIFORMS:
			m.set_shader_parameter(key, options[key])
	return m


func _init() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(rect)


func _play(style: Variant, options: Dictionary, from: float, to: float) -> void:
	if not is_inside_tree():
		await tree_entered
	options = _resolved(options)
	var o := DEFAULTS.merged(options, true)
	rect.material = make_material(style, o)
	rect.material.set_shader_parameter(&"progress", from)
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ease(o.ease).set_trans(o.trans)
	_tween.tween_property(rect.material, ^"shader_parameter/progress", to, o.duration)
	await _tween.finished
	if to == 0.0:
		visible = false


## Turns a node `center` into screen UV, so it survives the scene it points into.
func _resolved(options: Dictionary) -> Dictionary:
	var c: Variant = options.get(&"center")
	var screen: Vector2
	if c is CanvasItem:
		screen = c.get_global_transform_with_canvas().origin
	elif c is Node3D and c.get_viewport().get_camera_3d():
		screen = c.get_viewport().get_camera_3d().unproject_position(c.global_position)
	else:
		return options
	options = options.duplicate()
	options[&"center"] = screen / c.get_viewport().get_visible_rect().size
	return options
