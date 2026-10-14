class_name LabFxCollectionFreeSpriteFX
## One-line effects for any CanvasItem (Sprite2D, AnimatedSprite2D, TextureRect, ...).
##
## [codeblock]
## LabFxCollectionFreeSpriteFX.flash($Sprite2D)                      # hit flash, then the old material is back
## await LabFxCollectionFreeSpriteFX.dissolve_out($Enemy).finished   # then queue_free()
## LabFxCollectionFreeSpriteFX.apply($Chest, &"glow_outline", {glow_color = Color.GOLD})
## LabFxCollectionFreeSpriteFX.clear($Chest)
## [/codeblock]

## Every effect, by its shader's name.
const ALL_EFFECTS: Array[StringName] = [&"flash", &"outline", &"glow_outline", &"dissolve", &"burn",
	&"palette_swap", &"silhouette", &"pixelate", &"wind_sway", &"shine", &"hologram", &"freeze", &"glitch",
	&"hue_shift", &"stone", &"wave", &"blink", &"pulse_tint", &"jelly", &"gradient_map", &"chromatic",
	&"cloak", &"rim_light", &"invert", &"dither_fade", &"drop_shadow", &"adjust", &"posterize", &"shake",
	&"swirl", &"electric", &"fire_aura", &"cracks", &"motion_blur", &"teleport", &"metal", &"afterimage",
	&"submerge", &"disintegrate", &"cooldown"]
const _PATH := "res://vendor/fx_collection_free/sprite-fx-free/addons/sprite_fx/shaders/%s.gdshader"
## The installed effects' shaders, by name.
static var SHADERS := _shaders()

const _PREV := &"_sprite_fx_prev"
const _TWEEN := &"_sprite_fx_tween"


## Puts an effect on [param node] and returns its material. The node's own material is kept and
## comes back with [method clear].
static func apply(node: CanvasItem, effect: StringName, params := {}) -> ShaderMaterial:
	if not SHADERS.has(effect):
		push_error("LabFxCollectionFreeSpriteFX: no effect '%s', pick one of %s" % [effect, effects()])
		return null
	_stop(node)
	if not node.has_meta(_PREV):
		node.set_meta(_PREV, node.material)
	var mat := ShaderMaterial.new()
	mat.shader = SHADERS[effect]
	for key in params:
		mat.set_shader_parameter(key, params[key])
	node.material = mat
	return mat


## Removes the effect and gives the node its own material back.
static func clear(node: CanvasItem) -> void:
	_stop(node)
	if node.has_meta(_PREV):
		node.material = node.get_meta(_PREV)
		node.remove_meta(_PREV)


## Animates one shader parameter of [param effect] from [param from] to [param to].
## With [param restore], the node's own material comes back when the tween ends.
static func animate(node: CanvasItem, effect: StringName, param: StringName, from: Variant, to: Variant,
		duration: float, params := {}, restore := true) -> Tween:
	var mat := apply(node, effect, params)
	if mat == null:
		return null
	mat.set_shader_parameter(param, from)
	var tween := node.create_tween()
	tween.tween_method(func(v: Variant) -> void: mat.set_shader_parameter(param, v), from, to, duration)
	if restore:
		tween.tween_callback(clear.bind(node))
	node.set_meta(_TWEEN, tween)
	return tween


static func flash(node: CanvasItem, color := Color.WHITE, duration := 0.15) -> Tween:
	return animate(node, &"flash", &"flash_amount", 1.0, 0.0, duration, {flash_color = color})


static func blink(node: CanvasItem, duration := 1.0, rate := 10.0) -> Tween:
	if apply(node, &"blink", {rate = rate}) == null:
		return null
	var tween := node.create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(clear.bind(node))
	node.set_meta(_TWEEN, tween)
	return tween


## Leaves the node invisible (progress 1) when done; free it or call [method clear].
static func dissolve_out(node: CanvasItem, duration := 0.8, edge_color := Color(1.0, 0.55, 0.1)) -> Tween:
	return animate(node, &"dissolve", &"progress", 0.0, 1.0, duration, {edge_color = edge_color}, false)


static func dissolve_in(node: CanvasItem, duration := 0.8, edge_color := Color(0.4, 0.8, 1.0)) -> Tween:
	return animate(node, &"dissolve", &"progress", 1.0, 0.0, duration, {edge_color = edge_color})


static func burn_out(node: CanvasItem, duration := 1.2, origin := Vector2(0.5, 1.0)) -> Tween:
	return animate(node, &"burn", &"progress", 0.0, 1.0, duration, {origin = origin}, false)


static func dither_out(node: CanvasItem, duration := 0.5) -> Tween:
	return animate(node, &"dither_fade", &"fade", 0.0, 1.0, duration, {}, false)


static func dither_in(node: CanvasItem, duration := 0.5) -> Tween:
	return animate(node, &"dither_fade", &"fade", 1.0, 0.0, duration)


static func shake(node: CanvasItem, duration := 0.3, amount := 2.0) -> Tween:
	return animate(node, &"shake", &"amount", amount, 0.0, duration)


## Leaves the node invisible (progress 1) when done; free it or call [method clear].
static func teleport_out(node: CanvasItem, duration := 0.6, beam_color := Color(0.5, 0.9, 1.0)) -> Tween:
	return animate(node, &"teleport", &"progress", 0.0, 1.0, duration, {beam_color = beam_color}, false)


static func teleport_in(node: CanvasItem, duration := 0.6, beam_color := Color(0.5, 0.9, 1.0)) -> Tween:
	return animate(node, &"teleport", &"progress", 1.0, 0.0, duration, {beam_color = beam_color})


## Leaves the node invisible (progress 1) when done; free it or call [method clear]. The dust needs
## room to drift: transparent pixels round the art, or [code]grow[/code] in [param params].
static func disintegrate(node: CanvasItem, duration := 1.2, params := {}) -> Tween:
	return animate(node, &"disintegrate", &"progress", 0.0, 1.0, duration, params, false)


## The clock wipe from covered to ready over [param duration].
static func cooldown(node: CanvasItem, duration: float) -> Tween:
	return animate(node, &"cooldown", &"progress", 1.0, 0.0, duration)


## The effects whose shader is installed.
static func effects() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(SHADERS.keys())
	return out


static func _shaders() -> Dictionary:
	var out := {}
	for e in ALL_EFFECTS:
		if ResourceLoader.exists(_PATH % e):
			out[e] = load(_PATH % e)
	return out


static func _stop(node: CanvasItem) -> void:
	if node.has_meta(_TWEEN):
		var tween: Tween = node.get_meta(_TWEEN)
		if tween and tween.is_valid():
			tween.kill()
		node.remove_meta(_TWEEN)
