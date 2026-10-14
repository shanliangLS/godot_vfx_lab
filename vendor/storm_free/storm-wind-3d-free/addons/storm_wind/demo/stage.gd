extends Node3D
## The ground the demo and the store scenes play on: a moor at dusk under a storm sky, rocks, a
## broken fence, and an Environment whose glow makes the lightning bloom.

const GROUND := preload("res://vendor/storm_free/storm-wind-3d-free/addons/storm_wind/demo/ground.gdshader")

@export var size := 40.0
## Rocks and the fence round the middle, this far out; 0 for none.
@export var props := 7.0
## Two standing stones for an arc to jump between, this far either side; 0 for none.
@export var pylons := 0.0


func _ready() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * size
	ground.mesh = plane
	var ground_mat := ShaderMaterial.new()
	ground_mat.shader = GROUND
	ground.material_override = ground_mat
	add_child(ground)
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color(0.3, 0.3, 0.32)
	rock.roughness = 0.9
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.28, 0.2, 0.14)
	wood.roughness = 0.9
	if props > 0.0:
		for i in 7:
			var a := TAU * (i + 0.45) / 7.0
			var s := 0.5 + fmod(i * 0.37, 0.6)
			var stone := MeshInstance3D.new()
			var ball := SphereMesh.new()
			ball.radial_segments = 7
			ball.rings = 4
			stone.mesh = ball
			stone.material_override = rock
			stone.scale = Vector3(s * 1.4, s * 0.8, s)
			stone.position = Vector3(cos(a), 0.0, sin(a)) * (props + fmod(i * 1.3, 2.0)) + Vector3(0, s * 0.2, 0)
			stone.rotation.y = i * 1.7
			add_child(stone)
		for i in 6:
			var post := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.14, 1.2 - fmod(i * 0.29, 0.35), 0.14)
			post.mesh = box
			post.material_override = wood
			post.position = Vector3(-props * 0.8 + i * 1.6, box.size.y * 0.5, -props * 0.9)
			post.rotation.z = 0.08 * sin(i * 2.3)
			add_child(post)
			if i < 5 and i != 2:
				var rail := MeshInstance3D.new()
				var bar := BoxMesh.new()
				bar.size = Vector3(1.6, 0.08, 0.06)
				rail.mesh = bar
				rail.material_override = wood
				rail.position = post.position + Vector3(0.8, 0.25, 0)
				add_child(rail)
	for x in ([-pylons, pylons] if pylons > 0.0 else []):
		var stone := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.5, 2.0, 0.5)
		stone.mesh = box
		stone.material_override = rock
		stone.position = Vector3(x, 1.0, 0)
		add_child(stone)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 40, 0)
	sun.light_color = Color(0.6, 0.66, 0.85)
	sun.light_energy = 0.35
	add_child(sun)
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.05, 0.06, 0.09)
	sky_mat.sky_horizon_color = Color(0.22, 0.24, 0.3)
	sky_mat.ground_horizon_color = Color(0.22, 0.24, 0.3)
	sky_mat.ground_bottom_color = Color(0.05, 0.05, 0.06)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.43, 0.52)
	env.ambient_light_energy = 0.55
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.16, 0.18, 0.23)
	env.fog_density = 0.02
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
