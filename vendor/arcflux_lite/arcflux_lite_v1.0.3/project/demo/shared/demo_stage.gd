extends Node3D
## Dark demo stage: floor, a few props, glow environment and a camera.
## Every showcase scene instances this so all effects are shown under the same conditions.

@export var glow_enabled: bool = true
@export var show_props: bool = true
@export var camera_position: Vector3 = Vector3(0.0, 3.2, 9.0)
@export var camera_target: Vector3 = Vector3(0.0, 1.6, 0.0)
@export_range(20.0, 100.0, 0.1) var camera_fov: float = 55.0

var camera: Camera3D
var environment: Environment

const GROUND_SHADER: Shader = preload("res://vendor/arcflux_lite/arcflux_lite_v1.0.3/project/demo/shared/demo_ground.gdshader")


func _ready() -> void:
	_build_environment()
	_build_floor()
	if show_props:
		_build_props()
	camera = Camera3D.new()
	camera.fov = camera_fov
	add_child(camera)
	camera.look_at_from_position(camera_position, camera_target)
	camera.current = true


func set_view(pos: Vector3, look: Vector3, fov: float = 55.0) -> void:
	camera.fov = fov
	camera.look_at_from_position(pos, look)


func _build_environment() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.012, 0.014, 0.022)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.32, 0.36, 0.46)
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_white = 6.0
	environment.glow_enabled = glow_enabled
	environment.glow_intensity = 0.55
	environment.glow_strength = 1.0
	environment.glow_bloom = 0.0
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.glow_hdr_threshold = 1.0
	environment.set_glow_level(0, 0.0)
	environment.set_glow_level(1, 0.6)
	environment.set_glow_level(2, 0.8)
	environment.set_glow_level(3, 0.8)
	environment.set_glow_level(4, 0.6)
	environment.set_glow_level(5, 0.4)
	environment.set_glow_level(6, 0.2)
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.03, 0.035, 0.05)
	environment.fog_density = 0.012
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = environment
	add_child(we)
	var moon: DirectionalLight3D = DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.62, 0.85)
	moon.light_energy = 0.12
	moon.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	add_child(moon)


func _build_floor() -> void:
	var body: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	col.shape = box
	col.position = Vector3(0.0, -0.5, 0.0)
	body.add_child(col)
	var mi: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(80.0, 80.0)
	mi.mesh = plane
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mi.material_override = mat
	body.add_child(mi)
	add_child(body)


func _build_props() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.09, 0.1, 0.12)
	mat.roughness = 0.45
	mat.metallic = 0.3
	for x: float in [-7.0, 7.0]:
		for z: float in [-6.0, -2.0]:
			var p: MeshInstance3D = MeshInstance3D.new()
			var b: BoxMesh = BoxMesh.new()
			b.size = Vector3(0.8, 4.5, 0.8)
			p.mesh = b
			p.material_override = mat
			p.position = Vector3(x, 2.25, z)
			add_child(p)
