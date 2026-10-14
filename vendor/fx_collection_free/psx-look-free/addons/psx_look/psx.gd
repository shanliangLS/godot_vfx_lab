class_name LabFxCollectionFreePSX
## PS1-style materials: make one, or turn a whole scene's StandardMaterial3Ds into them.
##
##     LabFxCollectionFreePSX.convert(level)                         # every mesh under level
##     mesh.material_override = LabFxCollectionFreePSX.make(&"lit", preload("res://vendor/fx_collection_free/psx-look-free/crate.png"))
##     LabFxCollectionFreePSX.set_param(level, &"affine", 0.0)       # on every LabFxCollectionFreePSX material under level
##     add_child(LabFxCollectionFreePSX.sprite(preload("res://vendor/fx_collection_free/psx-look-free/imp.png"), Vector2i(4, 1), 8.0))  # an upright flipbook

## Material kinds, each a shaders/psx_<kind>.gdshader.
const KINDS: Array[StringName] = [&"lit", &"unlit", &"cutout", &"transparent", &"chrome", &"glow"]


static func has(kind: StringName) -> bool:
	return ResourceLoader.exists(_path(kind))


## A LabFxCollectionFreePSX material of `kind`, or lit where that kind isn't installed.
static func make(kind: StringName = &"lit", texture: Texture2D = null, color := Color.WHITE) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(_path(kind if has(kind) else &"lit"))
	m.set_shader_parameter(&"albedo", color)
	if texture:
		m.set_shader_parameter(&"albedo_texture", texture)
	if m.shader.resource_path == _path(&"chrome"):
		m.set_shader_parameter(&"reflection_texture", load("res://vendor/fx_collection_free/psx-look-free/addons/psx_look/chrome.png"))
	return m


## The LabFxCollectionFreePSX material closest to a BaseMaterial3D: additive blending becomes glow, alpha scissor
## cutout, alpha transparent, opaque unshaded unlit, metallic chrome. Unshaded sources stay unlit. Albedo colour, texture, UV1 scale and
## offset and the billboard mode carry over (a particle billboard's animation frames too).
static func from_material(source: BaseMaterial3D) -> ShaderMaterial:
	var kind := &"lit"
	if source.blend_mode == BaseMaterial3D.BLEND_MODE_ADD:
		kind = &"glow"
	elif source.transparency in [BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH]:
		kind = &"cutout"
	elif source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		kind = &"transparent"
	elif source.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		kind = &"unlit"
	elif source.metallic > 0.5:
		kind = &"chrome"
	var m := make(kind, source.albedo_texture, source.albedo_color)
	m.set_shader_parameter(&"unlit", source.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED)
	m.set_shader_parameter(&"uv_scale", Vector2(source.uv1_scale.x, source.uv1_scale.y))
	m.set_shader_parameter(&"uv_offset", Vector2(source.uv1_offset.x, source.uv1_offset.y))
	m.set_shader_parameter(&"vertex_colors", source.vertex_color_use_as_albedo)
	if kind == &"cutout":
		m.set_shader_parameter(&"alpha_cut", source.alpha_scissor_threshold)
	m.set_shader_parameter(&"billboard", {BaseMaterial3D.BILLBOARD_ENABLED: 1, BaseMaterial3D.BILLBOARD_FIXED_Y: 2,
			BaseMaterial3D.BILLBOARD_PARTICLES: 1}.get(source.billboard_mode, 0))
	if source.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES:
		m.set_shader_parameter(&"frames", Vector2(source.particles_anim_h_frames, source.particles_anim_v_frames))
	return m


## A sprite: a quad the size of one of `texture`'s `frames` at `pixel_size` metres a pixel, turned
## to the camera upright about its foot (or all the way, about its middle), the frames played at
## `fps`. A cutout, or any other kind: glow for a flame or a spark.
static func sprite(texture: Texture2D, frames := Vector2i.ONE, fps := 0.0, pixel_size := 1.0 / 32.0,
		kind := &"cutout", upright := true) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = texture.get_size() / Vector2(frames) * pixel_size
	if upright:
		quad.center_offset = Vector3(0.0, quad.size.y * 0.5, 0.0)
	var m := make(kind, texture)
	m.set_shader_parameter(&"billboard", 2 if upright else 1)
	m.set_shader_parameter(&"frames", Vector2(frames))
	m.set_shader_parameter(&"fps", fps)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = m
	return mi


## Swaps every BaseMaterial3D on the meshes under `root` (overrides and surface materials) for
## its LabFxCollectionFreePSX material, sharing one per source material. Returns how many it made.
static func convert(root: Node) -> int:
	var made := {}
	for node in _meshes(root):
		var mi := node as MeshInstance3D
		if mi.material_override is BaseMaterial3D:
			mi.material_override = _swap(mi.material_override, made)
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var source: Material = mi.get_surface_override_material(s)
				if not source:
					source = mi.mesh.surface_get_material(s)
				if source is BaseMaterial3D:
					mi.set_surface_override_material(s, _swap(source, made))
	return made.size()


## Sets a shader parameter on every LabFxCollectionFreePSX material under `root`, for an options menu say.
static func set_param(root: Node, param: StringName, value: Variant) -> void:
	for node in _meshes(root):
		var mi := node as MeshInstance3D
		var mats: Array[Material] = [mi.material_override]
		for s in mi.get_surface_override_material_count():
			mats.append(mi.get_surface_override_material(s))
		for m in mats:
			if m is ShaderMaterial and m.shader and m.shader.resource_path.begins_with("res://vendor/fx_collection_free/psx-look-free/addons/psx_look/"):
				m.set_shader_parameter(param, value)


static func _swap(source: BaseMaterial3D, made: Dictionary) -> ShaderMaterial:
	if source not in made:
		made[source] = from_material(source)
	return made[source]


static func _meshes(root: Node) -> Array[Node]:
	var out: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		out.append(root)
	return out


static func _path(kind: StringName) -> String:
	return "res://vendor/fx_collection_free/psx-look-free/addons/psx_look/shaders/psx_%s.gdshader" % kind
