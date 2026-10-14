extends Node3D
## Laboratory carrier for original PNG/FBX materials, not an upstream finished effect.
@export_file("*.png", "*.tga", "*.fbx") var source_asset := ""
@export var color := Color.WHITE:
	set(value):
		color = value
		_sync()
@export_range(0.0, 8.0, 0.05) var intensity := 1.0:
	set(value):
		intensity = value
		_sync()
@export var additive := false:
	set(value):
		additive = value
		_sync()
@export var billboard := true:
	set(value):
		billboard = value
		_sync()
@export_range(1, 32, 1) var columns := 1:
	set(value):
		columns = value
		_sync()
@export_range(1, 32, 1) var rows := 1:
	set(value):
		rows = value
		_sync()
@export_range(0.0, 60.0, 0.5) var frames_per_second := 12.0
@export_range(0, 1023, 1) var frame := 0
@export var animate := true
var _material: StandardMaterial3D
var _model_materials: Array[BaseMaterial3D] = []
var _clock := 0.0
var repeat_preview := true

func _ready() -> void:
	var asset := load(source_asset)
	if asset is PackedScene:
		var model: Node3D = asset.instantiate()
		add_child(model)
		var bounds := AABB()
		var found := false
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			var local_bounds: AABB = model.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
			bounds = bounds.merge(local_bounds) if found else local_bounds
			found = true
		if found:
			var size: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
			model.scale = Vector3.ONE * 3.0 / maxf(size, 0.01)
			model.position = -bounds.get_center() * model.scale
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			for index in mesh.mesh.get_surface_count():
				var original: Material = mesh.get_active_material(index)
				var material: BaseMaterial3D = original.duplicate(true) if original is BaseMaterial3D else StandardMaterial3D.new()
				mesh.set_surface_override_material(index, material)
				_model_materials.append(material)
		_sync()
		return
	if not asset is Texture2D:
		return
	var mesh := MeshInstance3D.new()
	mesh.mesh = QuadMesh.new()
	mesh.mesh.size = Vector2(3, 3)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_texture = asset
	mesh.material_override = _material
	add_child(mesh)
	_sync()

func _process(delta: float) -> void:
	if not _material:
		return
	_clock += delta
	var total := maxi(1, columns * rows)
	var animated_frame := int(_clock * frames_per_second)
	var index := (animated_frame % total if repeat_preview else mini(animated_frame, total - 1)) if animate else frame % total
	_material.uv1_offset = Vector3(float(index % columns) / columns, float(index / columns) / rows, 0)

func _sync() -> void:
	for material in _model_materials:
		material.albedo_color = color
		material.emission_enabled = intensity > 1.0
		material.emission = color
		material.emission_energy_multiplier = maxf(0.0, intensity - 1.0)
	if not _material:
		return
	_material.albedo_color = Color(color.r * intensity, color.g * intensity, color.b * intensity, color.a)
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	_material.uv1_scale = Vector3(1.0 / columns, 1.0 / rows, 1)

func play() -> void:
	_clock = 0.0
