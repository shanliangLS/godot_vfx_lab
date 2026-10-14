extends Node3D
## The demo level, built in plain StandardMaterial3Ds as any project's would be: an island at noon
## with a cottage, a windmill, trees, rocks, flowers, a lamp and the sea. The camera circles it,
## or walks with WASD or the arrow keys and looks with the mouse held down. dress() sets what a
## StandardMaterial3D has no setting for, once LabFxCollectionFreeToon.convert has run.

## Seconds into the tour; store scenes pin it for a still.
@export var t := 0.0
@export var touring := true

var cam := Camera3D.new()
var env := Environment.new()
var sun := DirectionalLight3D.new()
var sea: MeshInstance3D
var blades := Node3D.new()
var lamp := Node3D.new()
var coin: MeshInstance3D
## Meshes whose hard edges want the outline pushed out from their origin.
var boxy: Array[MeshInstance3D] = []
var tufts: Array[MeshInstance3D] = []
## The ground and the sea, which a rim light would catch where they run out flat to the horizon.
var floors: Array[MeshInstance3D] = []
var _look := Vector2(0.0, -0.2)
var _seed := 0


func _ready() -> void:
	_environment()
	_island()
	_cottage(Vector3(-3.0, 0, -1.5))
	_windmill(Vector3(4.5, 0, -4.0))
	for p in [Vector3(-7.5, 0, -5.0), Vector3(-8.5, 0, 2.5), Vector3(1.0, 0, -8.5), Vector3(8.5, 0, 2.0),
			Vector3(-4.5, 0, 6.5)]:
		_tree(p, 0.8 + fmod(absf(p.x * 0.37 + p.z * 0.21), 0.5))
	for r in [[Vector3(6.0, 0, 6.0), 1.0], [Vector3(7.2, 0, 5.2), 0.6], [Vector3(-9.5, 0, -1.0), 0.8],
			[Vector3(2.5, 0, 9.5), 0.7], [Vector3(-1.0, 0, -10.0), 0.9]]:
		_rock(r[0], r[1])
	for m in [Vector3(1.5, 0, 3.5), Vector3(2.1, 0, 4.1), Vector3(-6.2, 0, -3.4), Vector3(6.8, 0, -0.6)]:
		_mushroom(m)
	_lamp(Vector3(-0.2, 0, 1.2))
	_fence()
	coin = _add(_cylinder(0.45, 0.45, 0.1, 32), _mat(Color(1.0, 0.78, 0.2), 0.15, 1.0), Vector3(2.5, 1.0, 1.0))
	coin.rotation.x = PI / 2
	for c in [Vector3(-6, 10, -12), Vector3(7, 11, -14), Vector3(14, 9, 2), Vector3(-14, 10.5, 4)]:
		_cloud(c)
	_flowers()
	add_child(cam)
	cam.current = true
	cam.fov = 60
	_process(0.0)


func _process(delta: float) -> void:
	var move := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	for k in [[KEY_A, Vector2.LEFT], [KEY_D, Vector2.RIGHT], [KEY_W, Vector2.UP], [KEY_S, Vector2.DOWN]]:
		if Input.is_physical_key_pressed(k[0]):
			move += k[1]
	if move and touring:
		touring = false
		_look = Vector2(cam.rotation.y, cam.rotation.x)
	t += delta
	if touring:
		var a := t * 0.12 + 0.6
		cam.position = Vector3(sin(a) * 15.0, 5.0 + sin(t * 0.4) * 0.8, cos(a) * 15.0)
		cam.look_at(Vector3(0, 1.4, -1.0))
	else:
		cam.rotation = Vector3(_look.y, _look.x, 0)
		var dir := cam.basis * Vector3(move.x, 0, move.y)
		cam.position += Vector3(dir.x, 0, dir.z).normalized() * delta * 5.0 if move else Vector3.ZERO
		cam.position.y = 1.7
	blades.rotation.z = t * 0.8
	coin.rotation.y = t * 2.0
	coin.position.y = 1.0 + sin(t * 2.2) * 0.12


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if touring:
			touring = false
			_look = Vector2(cam.rotation.y, cam.rotation.x)
		_look += Vector2(-event.relative.x, -event.relative.y) * 0.005
		_look.y = clampf(_look.y, -1.2, 1.2)


func _environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.3, 0.55, 0.92)
	sky_mat.sky_horizon_color = Color(0.72, 0.86, 0.98)
	sky_mat.ground_horizon_color = Color(0.72, 0.86, 0.98)
	sky_mat.ground_bottom_color = Color(0.3, 0.5, 0.75)
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = sky_mat
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.8)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.72, 0.86, 0.98)
	env.fog_depth_begin = 30.0
	env.fog_depth_end = 70.0
	env.fog_sky_affect = 0.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)


func _island() -> void:
	floors.append(_add(_cylinder(12.0, 12.6, 0.6, 64), _mat(Color(0.47, 0.78, 0.36)), Vector3(0, -0.3, 0)))
	_add(_cylinder(12.6, 10.5, 2.0, 64), _mat(Color(0.86, 0.75, 0.52)), Vector3(0, -1.6, 0))
	var path := _mat(Color(0.9, 0.8, 0.58))
	for i in 6:
		var p := _add(_cylinder(0.55, 0.55, 0.06, 20), path, Vector3(-1.6 + i * 0.35, 0.0, 0.9 + i * 1.5))
		p.scale = Vector3(1.0, 1.0, 0.75)
		floors.append(p)
	var water := _mat(Color(0.2, 0.62, 0.86, 0.85))
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 160)
	plane.subdivide_width = 60
	plane.subdivide_depth = 60
	sea = _add(plane, water, Vector3(0, -0.9, 0))
	floors.append(sea)


func _cottage(p: Vector3) -> void:
	var house := Node3D.new()
	house.position = p
	house.rotation.y = 0.35
	add_child(house)
	boxy.append(_add(_box(Vector3(4.0, 2.6, 3.4)), _mat(Color(0.96, 0.9, 0.76)), Vector3(0, 1.3, 0), house))
	var roof := PrismMesh.new()
	roof.size = Vector3(4.6, 1.8, 3.9)
	boxy.append(_add(roof, _mat(Color(0.86, 0.3, 0.26)), Vector3(0, 3.5, 0), house))
	boxy.append(_add(_box(Vector3(0.6, 1.4, 0.6)), _mat(Color(0.62, 0.5, 0.46)), Vector3(1.2, 3.9, -0.5), house))
	boxy.append(_add(_box(Vector3(0.9, 1.6, 0.12)), _mat(Color(0.5, 0.3, 0.18)), Vector3(0.6, 0.8, 1.72), house))
	var glass := _mat(Color(0.55, 0.82, 0.95), 0.1)
	boxy.append(_add(_box(Vector3(0.9, 0.8, 0.1)), glass, Vector3(-1.1, 1.5, 1.72), house))
	for z in [-0.6, 0.7]:
		boxy.append(_add(_box(Vector3(0.1, 0.8, 0.8)), glass, Vector3(2.02, 1.5, z), house))


func _windmill(p: Vector3) -> void:
	_add(_cylinder(0.9, 1.4, 5.0, 24), _mat(Color(0.95, 0.95, 0.92)), p + Vector3.UP * 2.5)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.0
	cap.bottom_radius = 1.15
	cap.height = 1.2
	_add(cap, _mat(Color(0.3, 0.45, 0.75)), p + Vector3.UP * 5.6)
	blades.position = p + Vector3(0, 4.8, 1.05)
	add_child(blades)
	_add(SphereMesh.new(), _mat(Color(0.4, 0.3, 0.22)), Vector3.ZERO, blades).scale = Vector3.ONE * 0.4
	var wood := _mat(Color(0.74, 0.56, 0.38))
	var sail := _mat(Color(0.98, 0.95, 0.88))
	for i in 4:
		var arm := Node3D.new()
		arm.rotation.z = i * PI / 2
		blades.add_child(arm)
		boxy.append(_add(_box(Vector3(0.14, 3.0, 0.1)), wood, Vector3(0, 1.6, 0), arm))
		boxy.append(_add(_box(Vector3(0.7, 2.2, 0.04)), sail, Vector3(0.42, 1.9, 0.02), arm))


func _tree(p: Vector3, size: float) -> void:
	_add(_cylinder(0.18 * size, 0.28 * size, 2.0 * size, 12), _mat(Color(0.55, 0.36, 0.22)), p + Vector3.UP * size)
	var leaf := _mat(Color(0.3, 0.64, 0.3))
	for b in [[Vector3(0, 2.6, 0), 1.3], [Vector3(0.6, 2.1, 0.3), 0.9], [Vector3(-0.5, 2.2, -0.3), 0.95],
			[Vector3(0.1, 3.3, 0.1), 0.85]]:
		_add(_sphere(b[1] * size), leaf, p + b[0] * size)


func _rock(p: Vector3, size: float) -> void:
	_add(_sphere(size), _mat(Color(0.62, 0.62, 0.68)), p + Vector3.UP * size * 0.3).scale = Vector3(1.2, 0.7, 1.0)


func _mushroom(p: Vector3) -> void:
	_add(_cylinder(0.1, 0.13, 0.5, 12), _mat(Color(0.97, 0.94, 0.86)), p + Vector3.UP * 0.25)
	var cap := SphereMesh.new()
	cap.radius = 0.3
	cap.height = 0.3
	cap.is_hemisphere = true
	_add(cap, _mat(Color(0.9, 0.22, 0.2), 0.3), p + Vector3.UP * 0.48)


func _lamp(p: Vector3) -> void:
	lamp.position = p
	add_child(lamp)
	var iron := _mat(Color(0.2, 0.2, 0.26), 0.3)
	_add(_cylinder(0.07, 0.1, 2.4, 10), iron, Vector3.UP * 1.2, lamp)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.86, 0.5)
	_add(_sphere(0.22), glow, Vector3.UP * 2.55, lamp)
	var light := OmniLight3D.new()
	light.position = Vector3.UP * 2.55
	light.light_color = Color(1.0, 0.75, 0.4)
	light.light_energy = 0.8
	light.omni_range = 6.0
	lamp.add_child(light)


func _fence() -> void:
	var wood := _mat(Color(0.8, 0.64, 0.44))
	for i in 7:
		var x := -9.0 + i * 1.2
		boxy.append(_add(_box(Vector3(0.16, 0.9, 0.16)), wood, Vector3(x, 0.45, 6.0 + i * 0.5)))
		if i < 6:
			var rail := _add(_box(Vector3(1.3, 0.1, 0.08)), wood, Vector3(x + 0.6, 0.65, 6.25 + i * 0.5))
			rail.rotation.y = -atan2(0.5, 1.2)
			boxy.append(rail)


func _cloud(p: Vector3) -> void:
	var white := _mat(Color(1, 1, 1))
	for b in [[Vector3.ZERO, 1.6], [Vector3(1.5, -0.3, 0.2), 1.2], [Vector3(-1.5, -0.4, 0), 1.1], [Vector3(0.4, 0.7, -0.3), 1.1]]:
		var s := _add(_sphere(b[1]), white, p + b[0])
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Grass tufts and flowers about the meadow, each a frame of one sheet on two crossed quads: a
## cutout, which the free sampler goes without.
func _flowers() -> void:
	if not LabFxCollectionFreeToon.has(&"cutout"):
		return
	var sheet: Texture2D = load("res://vendor/fx_collection_free/toon-look-free/addons/toon_look/demo/art/tufts.png")
	var kinds: Array[StandardMaterial3D] = []
	for k in 4:
		var m := StandardMaterial3D.new()
		m.albedo_texture = sheet
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.uv1_scale = Vector3(0.25, 1, 1)
		m.uv1_offset = Vector3(k * 0.25, 0, 0)
		kinds.append(m)
	_seed = 11
	var placed := 0
	while placed < 70:
		var p := Vector3(_rand(-10.5, 10.5), 0, _rand(-10.5, 10.5))
		if p.length() > 10.8 or Vector2(p.x + 3.0, p.z + 1.5).length() < 3.0 or Vector2(p.x - 4.5, p.z + 4.0).length() < 1.8:
			continue  # off the island, the cottage and the windmill
		var size := _rand(0.6, 1.0)
		var tuft := _add(_cross(size), kinds[int(_rand(0.0, 4.0))], p)
		tuft.rotation.y = _rand(0.0, PI)
		tuft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tufts.append(tuft)
		placed += 1


## An LCG, so that the Unity demo's flowers grow where this one's do.
func _rand(lo: float, hi: float) -> float:
	_seed = (_seed * 1103515245 + 12345) % 2147483648
	return lo + (hi - lo) * _seed / 2147483648.0


## After LabFxCollectionFreeToon.convert: the sea becomes toon water, the boxes' outlines close at the corners, the
## flowers sway from their feet and the clouds go without outlines.
func dress() -> void:
	if LabFxCollectionFreeToon.has(&"water"):
		var water := LabFxCollectionFreeToon.make(&"water", null, Color(0.2, 0.62, 0.86, 0.85))
		water.set_shader_parameter(&"foam_color", Color(0.85, 0.95, 1.0))
		water.set_shader_parameter(&"foam_width", 0.04)
		water.set_shader_parameter(&"foam_scale", 0.3)
		water.set_shader_parameter(&"specular", 0.7)
		water.set_shader_parameter(&"glossiness", 80.0)
		sea.material_override = water
	LabFxCollectionFreeToon.set_param(sea, &"wave_height", 0.08)
	LabFxCollectionFreeToon.set_param(sea, &"wave_length", 4.0)
	for b in boxy:
		LabFxCollectionFreeToon.set_param(b, &"outline_smooth", 1.0)
	for f in tufts:
		LabFxCollectionFreeToon.set_param(f, &"wave_height", 0.08)
		LabFxCollectionFreeToon.set_param(f, &"wave_length", 3.0)
		LabFxCollectionFreeToon.set_param(f, &"wave_speed", 0.4)
		LabFxCollectionFreeToon.set_param(f, &"wave_pinned", 2)
	unrim_floors()


## Takes the rim off the floors, after a preset has put it on everything.
func unrim_floors() -> void:
	for f in floors:
		LabFxCollectionFreeToon.set_param(f, &"rim", 0.0)


func _mat(color: Color, roughness := 1.0, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _sphere(radius: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	return s


func _cylinder(top: float, bottom: float, height: float, sides: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = sides
	return c


## Two quads crossed, standing on their foot, for a tuft: lit from above, as a lawn is.
func _cross(size: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in [0.0, PI / 2]:
		var r := Vector3(cos(a), 0, sin(a)) * size * 0.5
		var corners := [[-r, Vector2(0, 1)], [r, Vector2(1, 1)], [r + Vector3.UP * size, Vector2(1, 0)],
				[-r + Vector3.UP * size, Vector2(0, 0)]]
		for i in [0, 2, 1, 0, 3, 2]:
			st.set_normal(Vector3.UP)
			st.set_uv(corners[i][1])
			st.add_vertex(corners[i][0])
	return st.commit()


func _add(mesh: Mesh, mat: Material, pos: Vector3, parent: Node = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
