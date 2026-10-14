class_name LabFxCollectionFreeToon
## LabFxCollectionFreeToon materials: make one, or turn a whole scene's StandardMaterial3Ds into them, outlined.
##
##     LabFxCollectionFreeToon.convert(level)                          # every mesh under level
##     mesh.material_override = LabFxCollectionFreeToon.make(&"cel", null, Color.TOMATO)
##     LabFxCollectionFreeToon.set_param(level, &"bands", 3)           # on every toon material under level
##     LabFxCollectionFreeToon.set_param(level, &"outline_width", 5.0) # and their outlines
##     LabFxCollectionFreeToon.restyle(level, &"halftone")             # the shade in comic dots

## Material kinds, each a shaders/toon_<kind>.gdshader.
const KINDS: Array[StringName] = [&"cel", &"hatch", &"halftone", &"cutout", &"transparent", &"water"]
## The kinds that take an outline, and restyle swaps between.
const SOLID: Array[StringName] = [&"cel", &"hatch", &"halftone"]
const DIR := "res://vendor/fx_collection_free/toon-look-free/addons/toon_look/"
const OUTLINE := DIR + "shaders/toon_outline.gdshader"


static func has(kind: StringName) -> bool:
	return ResourceLoader.exists(_path(kind))


## A toon material of `kind`, or cel where that kind isn't installed; a solid kind outlined
## unless `outline` is off.
static func make(kind: StringName = &"cel", texture: Texture2D = null, color := Color.WHITE, outline := true) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	if not has(kind):
		kind = &"cel"
	m.shader = load(_path(kind))
	m.set_shader_parameter(&"albedo", color)
	if texture:
		m.set_shader_parameter(&"albedo_texture", texture)
	if outline and kind in SOLID:
		m.next_pass = make_outline()
	return m


## An outline on its own, for a next_pass of your own material.
static func make_outline(width := 3.0, color := Color(0.1, 0.07, 0.12)) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(OUTLINE)
	m.set_shader_parameter(&"outline_width", width)
	m.set_shader_parameter(&"outline_color", color)
	return m


## The toon material closest to a BaseMaterial3D: alpha scissor becomes cutout, alpha transparent,
## anything else cel. Albedo colour, texture, UV1 scale and offset, vertex colours and emission
## carry over; a smooth or metallic surface gets the highlight. Opaque ones are outlined.
static func from_material(source: BaseMaterial3D, outline := true) -> ShaderMaterial:
	var kind := &"cel"
	if source.transparency in [BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH]:
		kind = &"cutout"
	elif source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		kind = &"transparent"
	var m := make(kind, source.albedo_texture, source.albedo_color, outline)
	m.set_shader_parameter(&"uv_scale", Vector2(source.uv1_scale.x, source.uv1_scale.y))
	m.set_shader_parameter(&"uv_offset", Vector2(source.uv1_offset.x, source.uv1_offset.y))
	m.set_shader_parameter(&"vertex_colors", source.vertex_color_use_as_albedo)
	if source.emission_enabled:
		m.set_shader_parameter(&"emission", source.emission * source.emission_energy_multiplier)
	var shine := maxf(clampf((0.7 - source.roughness) / 0.5, 0.0, 1.0), source.metallic)
	if shine > 0.0:
		m.set_shader_parameter(&"specular", shine)
		m.set_shader_parameter(&"glossiness", lerpf(16.0, 96.0, 1.0 - source.roughness))
	if kind == &"cutout":
		m.set_shader_parameter(&"alpha_cut", source.alpha_scissor_threshold)
	return m


## Swaps every BaseMaterial3D on the meshes under `root` (overrides and surface materials) for
## its toon material, one per source material, and returns how many it made. Unshaded and
## additive materials (lamps, glows, UI in 3D) are left as they are.
static func convert(root: Node, outline := true) -> int:
	var made := {}
	for node in _meshes(root):
		var mi := node as MeshInstance3D
		if _takes(mi.material_override):
			mi.material_override = _swap(mi.material_override, made, outline)
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var source: Material = mi.get_surface_override_material(s)
				if not source:
					source = mi.mesh.surface_get_material(s)
				if _takes(source):
					mi.set_surface_override_material(s, _swap(source, made, outline))
	return made.size()


## Sets a shader parameter on every toon material under `root` and on their outlines, for an
## options menu say.
static func set_param(root: Node, param: StringName, value: Variant) -> void:
	for m in materials(root):
		m.set_shader_parameter(param, value)
		if m.next_pass is ShaderMaterial and m.next_pass.shader and m.next_pass.shader.resource_path == OUTLINE:
			m.next_pass.set_shader_parameter(param, value)


## Turns the solid toon materials under `root` (cel, hatch, halftone) into `kind`, keeping their
## settings: the whole level drawn in hatching, say. Returns how many changed.
static func restyle(root: Node, kind: StringName) -> int:
	if kind not in SOLID or not has(kind):
		return 0
	var n := 0
	for m in materials(root):
		if kind_of(m) in SOLID and kind_of(m) != kind:
			m.shader = load(_path(kind))
			n += 1
	return n


## The toon kind of a material, or &"" if it isn't one.
static func kind_of(m: Material) -> StringName:
	if m is ShaderMaterial and m.shader:
		var file: String = m.shader.resource_path.get_file()
		if m.shader.resource_path.begins_with(DIR + "shaders/toon_") and file != OUTLINE.get_file():
			return StringName(file.trim_prefix("toon_").trim_suffix(".gdshader"))
	return &""


## Every toon material on the meshes under `root`, once each.
static func materials(root: Node) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	for node in _meshes(root):
		var mi := node as MeshInstance3D
		var mats: Array[Material] = [mi.material_override]
		for s in mi.get_surface_override_material_count():
			mats.append(mi.get_surface_override_material(s))
		for m in mats:
			if kind_of(m) != &"" and m not in out:
				out.append(m)
	return out


static func _takes(m: Material) -> bool:
	return m is BaseMaterial3D and m.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED \
			and m.blend_mode != BaseMaterial3D.BLEND_MODE_ADD


static func _swap(source: BaseMaterial3D, made: Dictionary, outline: bool) -> ShaderMaterial:
	if source not in made:
		made[source] = from_material(source, outline)
	return made[source]


static func _meshes(root: Node) -> Array[Node]:
	var out: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		out.append(root)
	return out


static func _path(kind: StringName) -> String:
	return DIR + "shaders/toon_%s.gdshader" % kind
