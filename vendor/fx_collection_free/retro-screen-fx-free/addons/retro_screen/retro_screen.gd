class_name LabFxCollectionFreeRetroScreen
extends CanvasLayer
## Retro post-processing over everything on lower layers, 2D and 3D. Add it to a scene, pick a
## preset, then tweak any parameter:
##
##     $LabFxCollectionFreeRetroScreen.preset = LabFxCollectionFreeRetroScreen.Preset.VHS
##     $LabFxCollectionFreeRetroScreen.set_param(&"noise", 0.6)
##
## Put UI on a layer above this one (default 100) to keep it crisp.

## Numbered as in the full pack, Retro Screen FX, so a scene saved with one keeps its preset when
## the full pack is installed over this one.
enum Preset { NONE = 0, CRT = 1, ARCADE = 2, VHS = 3, FILM = 11 }

const SHADER := preload("res://vendor/fx_collection_free/retro-screen-fx-free/addons/retro_screen/retro_screen.gdshader")
## Shader parameters per preset; everything else stays at the shader default (off).
const PRESETS := {
	Preset.NONE: {},
	Preset.CRT: {curvature = 0.1, corner_radius = 0.04, scanlines = 0.55, mask = 0.3, glow = 0.35,
		chromatic = 1.0, vignette = 0.45},
	Preset.ARCADE: {pixel_size = 3.0, curvature = 0.06, corner_radius = 0.03, scanlines = 0.7,
		glow = 0.5, saturation = 1.25, vignette = 0.3},
	Preset.VHS: {jitter = 0.5, color_bleed = 0.7, tracking = 0.7, noise = 0.35, chromatic = 2.0,
		saturation = 0.85, scanlines = 0.2, vignette = 0.3},
	Preset.FILM: {noise = 0.3, vignette = 0.6, saturation = 0.7, contrast = 1.15,
		tint = Color(1.0, 0.93, 0.82)},
}

@export var preset := Preset.CRT:
	set(value):
		preset = value
		apply_preset(shader_material, value)

var shader_material := ShaderMaterial.new()
var rect := ColorRect.new()


## Resets `material` to the shader defaults, then applies the preset.
static func apply_preset(material: ShaderMaterial, which: Preset) -> void:
	for u in SHADER.get_shader_uniform_list():
		material.set_shader_parameter(u.name, null)
	for key in PRESETS[which]:
		material.set_shader_parameter(key, PRESETS[which][key])


static func make_material(which: Preset) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	apply_preset(m, which)
	return m


func _init() -> void:
	layer = 100
	shader_material.shader = SHADER
	apply_preset(shader_material, preset)
	rect.material = shader_material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(rect)


func set_param(param: StringName, value: Variant) -> void:
	shader_material.set_shader_parameter(param, value)


func get_param(param: StringName) -> Variant:
	return shader_material.get_shader_parameter(param)
