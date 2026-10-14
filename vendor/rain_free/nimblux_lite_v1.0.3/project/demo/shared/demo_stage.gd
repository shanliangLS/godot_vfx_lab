extends Node3D
## Demo village used by every 3D demo: sky, sun, ground with a road, houses, trees,
## street lamps, grass and a bus stop. Lite: no shelter under the bus stop roof.

const GROUND_SHADER: Shader = preload("res://vendor/rain_free/nimblux_lite_v1.0.3/project/demo/shared/demo_ground.gdshader")
const GRASS_SHADER: Shader = preload("res://vendor/rain_free/nimblux_lite_v1.0.3/project/demo/shared/demo_grass.gdshader")

@export var camera_position: Vector3 = Vector3(0.0, 2.2, 12.0)
@export var camera_target: Vector3 = Vector3(0.0, 1.6, 0.0)
@export_range(20.0, 100.0, 0.1) var camera_fov: float = 60.0

## Ground wetness 0..1 (darker, glossier road).
var wetness: float = -1.0
var snow_cover: float = 0.0
var camera: Camera3D
var environment: Environment
var sun: DirectionalLight3D
var sky_material: ProceduralSkyMaterial
var lamps: Array[OmniLight3D] = []
var _ground_mat: ShaderMaterial
var _grass_mat: ShaderMaterial
var _lamp_mat: StandardMaterial3D
var _time: float = 0.0
var _wet_smooth: float = 0.0

const MOODS: Dictionary = {
	"day": {"top": Color(0.32, 0.5, 0.78), "horizon": Color(0.7, 0.78, 0.86), "ground": Color(0.25, 0.24, 0.22), "sun": 1.4, "sun_color": Color(1.0, 0.95, 0.88), "ambient": 0.9, "lamps": false, "sky_energy": 1.0},
	"overcast": {"top": Color(0.42, 0.46, 0.52), "horizon": Color(0.62, 0.65, 0.69), "ground": Color(0.2, 0.2, 0.21), "sun": 0.45, "sun_color": Color(0.9, 0.92, 0.96), "ambient": 1.0, "lamps": false, "sky_energy": 0.9},
	"storm": {"top": Color(0.1, 0.11, 0.14), "horizon": Color(0.24, 0.26, 0.3), "ground": Color(0.08, 0.08, 0.09), "sun": 0.12, "sun_color": Color(0.7, 0.78, 0.95), "ambient": 0.7, "lamps": true, "sky_energy": 0.6},
	"dusk": {"top": Color(0.16, 0.18, 0.32), "horizon": Color(0.85, 0.5, 0.32), "ground": Color(0.12, 0.1, 0.1), "sun": 0.5, "sun_color": Color(1.0, 0.62, 0.38), "ambient": 0.55, "lamps": true, "sky_energy": 0.8},
	"dawn": {"top": Color(0.34, 0.38, 0.47), "horizon": Color(0.6, 0.63, 0.68), "ground": Color(0.16, 0.16, 0.17), "sun": 0.35, "sun_color": Color(0.95, 0.85, 0.75), "ambient": 0.8, "lamps": true, "sky_energy": 0.85},
	"blue_hour": {"top": Color(0.05, 0.08, 0.17), "horizon": Color(0.2, 0.23, 0.34), "ground": Color(0.03, 0.03, 0.05), "sun": 0.1, "sun_color": Color(0.55, 0.65, 0.95), "ambient": 0.6, "lamps": true, "sky_energy": 0.7},
	"night": {"top": Color(0.02, 0.03, 0.06), "horizon": Color(0.07, 0.09, 0.14), "ground": Color(0.02, 0.02, 0.03), "sun": 0.06, "sun_color": Color(0.55, 0.65, 0.9), "ambient": 0.45, "lamps": true, "sky_energy": 0.5},
	"desert": {"top": Color(0.45, 0.55, 0.7), "horizon": Color(0.85, 0.72, 0.55), "ground": Color(0.4, 0.3, 0.2), "sun": 1.3, "sun_color": Color(1.0, 0.88, 0.7), "ambient": 0.8, "lamps": false, "sky_energy": 1.0},
}


func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_village()
	_build_grass()
	camera = Camera3D.new()
	camera.fov = camera_fov
	camera.far = 400.0
	add_child(camera)
	camera.look_at_from_position(camera_position, camera_target)
	camera.current = true
	set_mood("overcast")


func _process(delta: float) -> void:
	_time += delta
	var w: float = maxf(wetness, 0.0)
	_wet_smooth = move_toward(_wet_smooth, w, delta * 0.25)
	_ground_mat.set_shader_parameter("wetness", _wet_smooth)
	_ground_mat.set_shader_parameter("snow_cover", snow_cover)
	_grass_mat.set_shader_parameter("wind", Vector3(1.2, 0.0, 0.4))
	_grass_mat.set_shader_parameter("time", _time)
	_grass_mat.set_shader_parameter("snow_cover", snow_cover)


func set_view(pos: Vector3, look: Vector3, fov: float = 60.0) -> void:
	camera.fov = fov
	camera.look_at_from_position(pos, look)


func set_mood(name: String) -> void:
	var m: Dictionary = MOODS[name]
	sky_material.sky_top_color = m["top"]
	sky_material.sky_horizon_color = m["horizon"]
	sky_material.ground_horizon_color = m["horizon"]
	sky_material.ground_bottom_color = m["ground"]
	sky_material.energy_multiplier = m["sky_energy"]
	sun.light_energy = m["sun"]
	sun.light_color = m["sun_color"]
	environment.ambient_light_energy = m["ambient"]
	# Compatibility renders sky ambient a bit stronger and has no sky reflections, which
	# makes the grass dark and green. Swap some ambient for a flat sky sheen there.
	var compat: bool = RenderingServer.get_current_rendering_method() == "gl_compatibility"
	var horizon: Color = m["horizon"]
	var top: Color = m["top"]
	var sky_energy: float = m["sky_energy"]
	var ambient: float = m["ambient"]
	var lamps_on: bool = m["lamps"]
	var sheen: Color = horizon.lerp(top, 0.4)
	var sheen_v: Vector3 = Vector3(sheen.r, sheen.g, sheen.b) * 0.3 * sky_energy if compat else Vector3.ZERO
	_ground_mat.set_shader_parameter("compat_sheen", sheen_v)
	_grass_mat.set_shader_parameter("compat_sheen", sheen_v)
	if compat:
		environment.ambient_light_energy = ambient * 0.45
		sky_material.energy_multiplier = sky_energy * 1.12
	set_lamps(lamps_on)


func set_lamps(on: bool) -> void:
	for l in lamps:
		l.visible = on
	_lamp_mat.emission_energy_multiplier = 3.0 if on else 0.0


func _build_environment() -> void:
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sun_angle_max = 20.0
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_white = 6.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.4
	environment.glow_hdr_threshold = 1.2
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	var we: WorldEnvironment = WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = environment
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38.0, -35.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)


func _build_ground() -> void:
	var body: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(300.0, 1.0, 300.0)
	col.shape = box
	col.position = Vector3(0.0, -0.5, 0.0)
	body.add_child(col)
	var mi: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(300.0, 300.0)
	mi.mesh = plane
	_ground_mat = ShaderMaterial.new()
	_ground_mat.shader = GROUND_SHADER
	mi.material_override = _ground_mat
	body.add_child(mi)
	add_child(body)


func _mat(c: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _mesh(mesh: Mesh, mat: Material, pos: Vector3, rot_y: float = 0.0, parent: Node3D = null) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
	(parent if parent else self).add_child(mi)
	return mi


func _solid(size: Vector3, mat: Material, pos: Vector3, rot_y: float = 0.0) -> MeshInstance3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	return _mesh(bm, mat, Vector3.ZERO, 0.0, body)


func _house(pos: Vector3, rot_y: float, size: Vector3, wall: Color, roof: Color) -> void:
	_solid(size, _mat(wall), pos + Vector3(0.0, size.y * 0.5, 0.0), rot_y)
	var pm: PrismMesh = PrismMesh.new()
	pm.size = Vector3(size.x + 0.5, size.y * 0.55, size.z + 0.5)
	_mesh(pm, _mat(roof, 0.7), pos + Vector3(0.0, size.y + size.y * 0.275, 0.0), rot_y)
	var win: StandardMaterial3D = _mat(Color(0.18, 0.2, 0.24), 0.2)
	win.emission_enabled = true
	win.emission = Color(1.0, 0.75, 0.45)
	win.emission_energy_multiplier = 0.6
	var wb: BoxMesh = BoxMesh.new()
	wb.size = Vector3(0.7, 0.8, 0.05)
	var basis: Basis = Basis(Vector3.UP, rot_y)
	for sx: float in [-0.28, 0.28]:
		_mesh(wb, win, pos + basis * Vector3(size.x * sx, size.y * 0.55, size.z * 0.5 + 0.03), rot_y)


func _tree(pos: Vector3, h: float) -> void:
	var trunk: CylinderMesh = CylinderMesh.new()
	trunk.top_radius = 0.12 * h
	trunk.bottom_radius = 0.18 * h
	trunk.height = h
	_mesh(trunk, _mat(Color(0.25, 0.18, 0.12)), pos + Vector3(0.0, h * 0.5, 0.0))
	var crown: SphereMesh = SphereMesh.new()
	crown.radius = 0.9 * h
	crown.height = 1.5 * h
	crown.radial_segments = 10
	crown.rings = 6
	_mesh(crown, _mat(Color(0.14, 0.24, 0.1)), pos + Vector3(0.0, h * 1.35, 0.0))


func _lamp(pos: Vector3) -> void:
	var pole: CylinderMesh = CylinderMesh.new()
	pole.top_radius = 0.05
	pole.bottom_radius = 0.07
	pole.height = 3.6
	_mesh(pole, _mat(Color(0.12, 0.12, 0.13), 0.5), pos + Vector3(0.0, 1.8, 0.0))
	var head: SphereMesh = SphereMesh.new()
	head.radius = 0.16
	head.height = 0.32
	_mesh(head, _lamp_mat, pos + Vector3(0.0, 3.65, 0.0))
	var l: OmniLight3D = OmniLight3D.new()
	l.light_color = Color(1.0, 0.78, 0.5)
	l.light_energy = 2.2
	l.omni_range = 9.0
	l.position = pos + Vector3(0.0, 3.5, 0.0)
	add_child(l)
	lamps.append(l)


func _build_village() -> void:
	_lamp_mat = _mat(Color(1.0, 0.9, 0.7), 0.3)
	_lamp_mat.emission_enabled = true
	_lamp_mat.emission = Color(1.0, 0.8, 0.5)
	_house(Vector3(-7.5, 0.0, -4.0), 0.1, Vector3(5.0, 3.2, 4.2), Color(0.55, 0.5, 0.44), Color(0.35, 0.16, 0.12))
	_house(Vector3(7.8, 0.0, -6.0), -0.15, Vector3(4.6, 3.6, 4.8), Color(0.62, 0.6, 0.55), Color(0.16, 0.22, 0.3))
	_house(Vector3(-8.5, 0.0, -16.0), 0.25, Vector3(6.0, 4.0, 5.0), Color(0.5, 0.46, 0.42), Color(0.25, 0.25, 0.27))
	_house(Vector3(9.0, 0.0, -19.0), -0.3, Vector3(5.0, 3.0, 4.0), Color(0.58, 0.52, 0.4), Color(0.32, 0.14, 0.1))
	_house(Vector3(-6.0, 0.0, -30.0), 0.0, Vector3(5.5, 3.4, 4.6), Color(0.6, 0.57, 0.5), Color(0.2, 0.2, 0.22))
	for p: Vector3 in [Vector3(-13.0, 0.0, 2.0), Vector3(13.5, 0.0, 1.0), Vector3(-14.0, 0.0, -10.0), Vector3(15.0, 0.0, -12.0), Vector3(4.5, 0.0, -28.0), Vector3(-15.0, 0.0, -24.0), Vector3(16.0, 0.0, -30.0), Vector3(-3.5, 0.0, -42.0), Vector3(6.0, 0.0, -45.0)]:
		_tree(p, 2.2 + fmod(absf(p.x * 0.37 + p.z * 0.11), 1.2))
	for z: float in [4.0, -8.0, -20.0, -32.0]:
		_lamp(Vector3(2.9, 0.0, z))
	# Bus stop: a roof on posts. The full version puts a NimbluxShelter3D under it.
	var post: CylinderMesh = CylinderMesh.new()
	post.top_radius = 0.05
	post.bottom_radius = 0.05
	post.height = 2.4
	var metal: StandardMaterial3D = _mat(Color(0.2, 0.22, 0.25), 0.4)
	for p: Vector3 in [Vector3(-4.6, 1.2, 1.3), Vector3(-2.8, 1.2, 1.3), Vector3(-4.6, 1.2, 2.7), Vector3(-2.8, 1.2, 2.7)]:
		_mesh(post, metal, p)
	_solid(Vector3(2.4, 0.08, 1.9), _mat(Color(0.3, 0.33, 0.36), 0.3), Vector3(-3.7, 2.42, 2.0))
	_solid(Vector3(1.8, 0.08, 0.5), _mat(Color(0.35, 0.25, 0.18)), Vector3(-3.7, 0.55, 2.4))


func _build_grass() -> void:
	var verts: PackedVector3Array = PackedVector3Array([Vector3(-0.04, 0.0, 0.0), Vector3(0.04, 0.0, 0.0), Vector3(0.04, 1.0, 0.0), Vector3(-0.04, 1.0, 0.0)])
	var uvs: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)])
	var normals: PackedVector3Array = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var blade: ArrayMesh = ArrayMesh.new()
	blade.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_grass_mat = ShaderMaterial.new()
	_grass_mat.shader = GRASS_SHADER
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	var count: int = 9000
	mm.instance_count = count
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = 7
	var placed: int = 0
	while placed < count:
		var x: float = r.randf_range(-22.0, 22.0)
		var z: float = r.randf_range(-26.0, 12.0)
		if absf(x) < 2.8:
			continue
		var b: Basis = Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(1.0, r.randf_range(0.25, 0.6), 1.0))
		mm.set_instance_transform(placed, Transform3D(b, Vector3(x, 0.0, z)))
		placed += 1
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _grass_mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
