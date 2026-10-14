class_name PreviewStage extends SubViewportContainer

signal effect_changed(effect: Node3D)

var viewport: SubViewport
var world: Node3D
var mount: Node3D
var carrier: Node3D
var effect: Node3D
var target: Node3D
var camera: Camera3D
var environment: Environment
var descriptor: Dictionary = {}
var elapsed := 0.0
var playing := true
var repeat_effect := true:
	set(value):
		repeat_effect = value
		_sync_requested_loop()
var repeat_interval := 2.4
var playback_speed := 1.0
var effect_scale := 1.0
var authored_scale := Vector3.ONE
var framed_origin := Vector3.ZERO
var motion_speed := 1.0
var path_radius := 2.0
var orbit_target := true
var yaw := 0.60
var pitch := -0.24
var distance := 9.5
var focus := Vector3(0, 1.1, 0)
var grid: MeshInstance3D
var dummy: Node3D
var last_repeat := 0.0
var material_records: Array[Dictionary] = []
var paused_speeds: Dictionary = {}
var projectile_clock := 0.0
var projectile_scales: Dictionary = {}
var shader_origins: Dictionary = {}

func _ready() -> void:
	stretch = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport = SubViewport.new()
	viewport.size = Vector2i(1000, 750)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var env_node := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0b1321")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("92b9d8")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	env_node.environment = environment
	world.add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_color = Color("bed8f2")
	sun.light_energy = 1.3
	world.add_child(sun)
	grid = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 24)
	grid.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/grid.gdshader")
	grid.material_override = mat
	world.add_child(grid)
	dummy = Node3D.new()
	world.add_child(dummy)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.32
	capsule.height = 1.5
	body.mesh = capsule
	body.position.y = 0.75
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color("516984")
	body_mat.metallic = 0.5
	body_mat.roughness = 0.35
	body.material_override = body_mat
	dummy.add_child(body)
	mount = Node3D.new()
	world.add_child(mount)
	target = Node3D.new()
	target.position = Vector3(2.5, 1.2, 0)
	world.add_child(target)
	var marker := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.1
	ball.height = 0.2
	marker.mesh = ball
	var marker_mat := StandardMaterial3D.new()
	marker_mat.albedo_color = LabTheme.GOLD
	marker_mat.emission_enabled = true
	marker_mat.emission = LabTheme.GOLD
	marker.material_override = marker_mat
	target.add_child(marker)
	camera = Camera3D.new()
	camera.fov = 42
	world.add_child(camera)
	_update_camera()
	gui_input.connect(_camera_input)

func load_effect(entry: Dictionary) -> void:
	descriptor = entry
	for child in mount.get_children():
		mount.remove_child(child)
		child.queue_free()
	effect = null
	carrier = Node3D.new()
	mount.add_child(carrier)
	elapsed = 0
	last_repeat = 0
	focus = Vector3(0, 1.1, 0)
	effect_scale = 1
	framed_origin = Vector3.ZERO
	playing = true
	material_records.clear()
	paused_speeds.clear()
	projectile_scales.clear()
	shader_origins.clear()
	projectile_clock = 0.0
	dummy.visible = entry.get("mode", "") == "hit"
	target.visible = entry.get("mode", "") in ["beam", "bolt"]
	var path: String = entry.get("path", "")
	if path.is_empty():
		return
	var resource := load(path)
	if resource is PackedScene:
		var scene_root: Node = resource.instantiate()
		if entry.has("subnode"):
			effect = scene_root.get_node(entry.subnode) as Node3D
			effect.get_parent().remove_child(effect)
			scene_root.free()
			effect.position = Vector3.ZERO
		else:
			effect = scene_root as Node3D
	elif resource is Script:
		effect = resource.new() as Node3D
	if not effect:
		return
	effect.name = "Effect"
	if entry.has("visible_subnode"):
		for node in effect.get_children():
			if node is Node3D and not node is Camera3D and not node is WorldEnvironment:
				node.visible = node.name == entry.visible_subnode
				if node.visible:
					node.position = Vector3.ZERO
	if entry.get("strip_demo_stage", false):
		for node in _nodes(effect):
			if node is Camera3D or node is WorldEnvironment or node is DirectionalLight3D:
				node.get_parent().remove_child(node)
				node.queue_free()
	for path_to_remove in entry.get("strip_demo_nodes", []):
		var decoration := effect.get_node_or_null(path_to_remove)
		if decoration:
			decoration.get_parent().remove_child(decoration)
			decoration.queue_free()
	authored_scale = effect.scale
	for key in entry.get("initial", {}):
		effect.set(key, entry.initial[key])
	for key in ["auto_free", "free_on_finish", "one_shot_free"]:
		if key in effect:
			effect.set(key, false)
	effect.set_meta("vfx_lab_keep_alive", true)
	if "auto_free" in effect:
		effect.set("auto_free", false)
	if entry.get("id", "") == "motion_trail":
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color = Color.WHITE
		effect.material_override = material
	_make_local(effect)
	carrier.add_child(effect)
	_setup_requested_effect()
	if effect is GPUTrail3D:
		effect.visibility_aabb = AABB(Vector3(-15, -15, -15), Vector3(30, 30, 30))
		effect.fixed_fps = 60
		_set_trail_gradient(effect, LabTheme.ACCENT)
	_setup_beam()
	_frame_effect()
	if entry.has("preview_scale"):
		carrier.scale = Vector3.ONE * float(entry.preview_scale)
	_align_ground_model()
	_center_camera_gust()
	if _is_inspired_projectile():
		# The preview owns motion and lifetime; the source script otherwise frees itself.
		effect.set_process(false)
		effect.set_physics_process(false)
		for node_path in ["Emitters", "TrailPrefab"]:
			var node: Node3D = effect.get_node(node_path)
			projectile_scales[node_path] = node.scale
	if descriptor.get("mode") == "hit":
		_overlay_hit_materials()
	replay()
	_update_camera()
	effect_changed.emit(effect)

func _make_local(node: Node) -> void:
	if node is GeometryInstance3D:
		for material in _materials(node):
			if material is ShaderMaterial and material.shader and not material.shader.resource_path.is_empty():
				shader_origins[material.shader.code] = material.shader.resource_path.get_base_dir()
	for property in ["material_override", "material_overlay", "process_material", "mesh"]:
		if property in node and node.get(property) is Resource:
			node.set(property, node.get(property).duplicate(true))
	for property in ["preset", "palette"]:
		if property in node and node.get(property) is Resource:
			node.set(property, node.get(property).duplicate(true))
	if node is GPUParticles3D:
		for index in node.draw_passes:
			var mesh: Mesh = node.get_draw_pass_mesh(index)
			if mesh: node.set_draw_pass_mesh(index, mesh.duplicate(true))
	for child in node.get_children():
		_make_local(child)

func _frame_effect() -> void:
	carrier.position = Vector3(0, 1.1, 0)
	carrier.rotation = Vector3.ZERO
	if descriptor.get("mode") == "area":
		carrier.position = Vector3(0, 0.05, 0)
	if descriptor.get("mode") == "beam":
		carrier.position = Vector3(-2.5, 1.2, 0)
	if descriptor.get("mode") == "bolt":
		carrier.position = Vector3(-2.5, 2.5, 0)
	if descriptor.get("mode") == "slash":
		carrier.position = Vector3(0, 1.5, 0)
	if descriptor.get("preview_origin") == "feet":
		carrier.position = Vector3(0, 0.02, 0)
	if descriptor.get("pack_id") == "soygus_tornado":
		_frame_tornado()

func _ground_model_bounds() -> AABB:
	var bounds := AABB()
	if not is_instance_valid(effect) or not descriptor.has("ground_model"):
		return bounds
	var model := effect.get_node_or_null(descriptor.ground_model)
	if not model:
		return bounds
	var found := false
	for node in _nodes(model):
		if node is MeshInstance3D and node.mesh and node.is_visible_in_tree():
			var world_bounds: AABB = node.global_transform * node.get_aabb()
			bounds = bounds.merge(world_bounds) if found else world_bounds
			found = true
	return bounds

func _align_ground_model() -> void:
	var bounds := _ground_model_bounds()
	if bounds.size.y > 0.0:
		carrier.position.y += 0.02 - bounds.position.y

func _center_camera_gust() -> void:
	if not is_instance_valid(effect) or descriptor.get("preview_origin") != "camera_center":
		return
	var center := Vector3(0, float(effect.height) * 0.5, 0)
	# Keep the focus centered while fitting the vertical range above the floor.
	# Wind ribbons scatter in the shader beyond their authored mesh bounds.
	var local_center := effect.transform * center
	var lower_extent := absf(float(effect.height) * effect.scale.y) * 0.5
	var floor_margin := 0.25
	for node in _nodes(effect):
		if node is MeshInstance3D and node.mesh:
			for material in _materials(node):
				if material is ShaderMaterial and material.shader and material.shader.resource_path.ends_with("/line.gdshader"):
					var scatter: Vector3 = material.get_shader_parameter("scatter")
					var bounds: AABB = node.mesh.get_aabb()
					bounds.position -= scatter.abs()
					bounds.size += scatter.abs() * 2.0
					bounds = effect.transform * (node.transform * bounds)
					lower_extent = maxf(lower_extent, local_center.y - bounds.position.y)
				elif material is ShaderMaterial and material.shader and material.shader.resource_path.ends_with("/debris.gdshader"):
					# Dust puffs already fade at their origin in the source shader.
					if material.get_shader_parameter("shape") == 5:
						continue
					var half_size := float(material.get_shader_parameter("size")) * 1.3
					var flutter := float(material.get_shader_parameter("flutter"))
					var fall := absf(float(material.get_shader_parameter("fall")))
					var stretch := float(material.get_shader_parameter("stretch"))
					var step_x := 0.09 * flutter * absf(effect.scale.x)
					var step_y := 0.01 * (fall + 4.2 * flutter) * absf(effect.scale.y)
					var step_z := 0.032 * float(effect.radius) * absf(effect.scale.z)
					var long_side := half_size + stretch * Vector3(step_x, step_y, step_z).length()
					floor_margin = maxf(floor_margin, Vector2(half_size, long_side).length() + 0.02)
	# Leave room for the camera-facing leaves and ribbon width.
	carrier.scale.y = minf(1.0, maxf(focus.y - floor_margin, 0.01) / maxf(lower_extent, 0.001))
	carrier.position = focus - carrier.basis * (effect.transform * center)

func _frame_tornado() -> void:
	var bounds := AABB()
	var found := false
	for node in _nodes(effect):
		if node is MeshInstance3D and node.mesh and node.is_visible_in_tree():
			var relative: Transform3D = effect.global_transform.affine_inverse() * node.global_transform
			var local_bounds: AABB = relative * node.get_aabb()
			bounds = bounds.merge(local_bounds) if found else local_bounds
			found = true
	if found:
		var extent: Vector3 = bounds.size * effect.scale
		carrier.scale = Vector3.ONE * (4.5 / maxf(maxf(extent.x, extent.y), maxf(extent.z, 0.1)))
		framed_origin = Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
		effect.position = -framed_origin * effect.scale
		carrier.position = Vector3.ZERO
		focus.y = maxf(1.1, bounds.size.y * effect.scale.y * carrier.scale.y * 0.5)

func _overlay_hit_materials() -> void:
	# Only adapt this preview instance. Priority alone cannot bypass the dummy's depth.
	var shaders: Dictionary = {}
	for node in _nodes(effect):
		if not node is GeometryInstance3D:
			continue
		for material in _materials(node):
			material.render_priority = 100
			if material is BaseMaterial3D:
				material.no_depth_test = true
				material.proximity_fade_enabled = false
			elif material is ShaderMaterial and material.shader:
				var source: Shader = material.shader
				if "depth_test_disabled" not in source.code and not shaders.has(source):
					var overlay := Shader.new()
					var code := _expand_shader_includes(source.code, shader_origins.get(source.code, source.resource_path.get_base_dir()))
					if "depth_test_default" in code:
						code = code.replace("depth_test_default", "depth_test_disabled")
					else:
						code = code.replace("shader_type spatial;", "shader_type spatial;\nrender_mode depth_test_disabled;")
					overlay.code = code
					shaders[source] = overlay
				if shaders.has(source):
					material.shader = shaders[source]
				for uniform in material.shader.get_shader_uniform_list():
					if uniform.name == "proximity_fade":
						material.set_shader_parameter("proximity_fade", false if uniform.type == TYPE_BOOL else 0.0)

func _expand_shader_includes(code: String, directory: String) -> String:
	# Shader.code assignment does not run the file loader's include preprocessor.
	var includes := RegEx.new()
	includes.compile('(?m)^\\s*#include\\s+"([^"]+)"[^\\n]*')
	var expanded := code
	var matches := includes.search_all(code)
	matches.reverse()
	for found in matches:
		var path: String = found.get_string(1)
		if not path.begins_with("res://"):
			path = directory.path_join(path).simplify_path()
		var body := _expand_shader_includes(FileAccess.get_file_as_string(path), path.get_base_dir())
		expanded = expanded.substr(0, found.get_start()) + body + expanded.substr(found.get_end())
	return expanded

func _setup_beam() -> void:
	if descriptor.get("mode") not in ["beam", "bolt"] or not effect:
		return
	for node in _nodes(effect):
		for p in node.get_property_list():
			var key: String = p.name
			if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and ("target" in key.to_lower() or key == "end_point"):
				if p.type == TYPE_OBJECT:
					node.set(key, target)
				elif p.type == TYPE_NODE_PATH:
					node.set(key, node.get_path_to(target))

func _process(delta: float) -> void:
	if not is_instance_valid(effect):
		return
	# Deferred alignment follows the author's animation/bobbing updates in this frame.
	if descriptor.has("ground_model"):
		call_deferred("_align_ground_model")
	_center_camera_gust()
	if not playing:
		return
	elapsed += delta * playback_speed
	var mode: String = descriptor.get("mode", "static")
	if mode == "trail" or mode == "projectile":
		var time := elapsed * motion_speed
		if _is_inspired_projectile():
			time *= float(effect.get("speed")) / 10.0
		carrier.position = Vector3(sin(time * 1.4) * path_radius, 1.5 + sin(time * 2.1) * 0.4, cos(time * 1.4) * path_radius * 0.5)
		if mode == "projectile":
			var direction := Vector3(cos(time * 1.4), cos(time * 2.1) * 0.25, -sin(time * 1.4) * 0.5)
			carrier.look_at(carrier.global_position + direction)
	if _is_inspired_projectile():
		_update_inspired_projectile(delta * playback_speed)
	if mode == "beam":
		if orbit_target:
			target.position = Vector3(2.3, 1.2 + sin(elapsed) * 0.7, sin(elapsed * 0.7) * 1.5)
		if carrier.global_position.distance_squared_to(target.global_position) > 0.001:
			carrier.look_at(target.global_position)
	if repeat_effect and elapsed - last_repeat > repeat_interval and mode in ["hit", "slash", "area", "bolt"]:
		last_repeat = elapsed
		replay()

func replay() -> void:
	if not is_instance_valid(effect):
		return
	last_repeat = elapsed
	if _is_inspired_projectile():
		_restart_inspired_projectile()
		if not playing:
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	for node in _nodes(effect):
		if node is AnimationPlayer:
			var names: PackedStringArray = node.get_animation_list()
			for anim in ["main", "Main", "open", "Open", "default"]:
				if node.has_animation(anim):
					node.play(anim)
					break
			if not node.is_playing():
				for anim in names:
					if anim != "RESET":
						node.play(anim)
						break
		if node is GPUParticles3D or node is CPUParticles3D:
			node.restart()
			node.emitting = true
		if "open_amount" in node:
			node.set("open_amount", 1.0)
		if node.has_method("play_effect"):
			node.call("play_effect")
		elif node.get_script() and node.has_method("play") and not node is AnimationPlayer:
			node.call("play")
	if descriptor.get("mode") == "hit":
		_overlay_hit_materials()
	if not playing:
		_freeze_new_particles()
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _setup_requested_effect() -> void:
	var pack: String = descriptor.get("pack_id", "")
	if pack == "berry_hit_free":
		effect.loop = false  # The toolbar owns repeats; keep the same data-resource editors.
	if pack == "starter_lite":
		# Source manager repeats single shots itself; the laboratory owns this timing.
		effect.set_process(false)
	_sync_requested_loop()

func _sync_requested_loop() -> void:
	if not is_instance_valid(effect):
		return
	var pack: String = descriptor.get("pack_id", "")
	if "repeat_preview" in effect:
		effect.repeat_preview = repeat_effect
	if pack in ["magic_circles_free", "storm_free"]:
		effect.one_shot = not repeat_effect
	elif pack == "starter_lite" and descriptor.get("mode") == "static":
		effect.is_looping = repeat_effect

func parameter_edited(parameter: Dictionary) -> void:
	if not is_instance_valid(effect):
		return
	if descriptor.get("pack_id") == "berry_hit_free" and parameter.target is Resource:
		# This pack reads its preset when rebuilding, rather than observing Resource.changed.
		effect.play()
		_overlay_hit_materials()
		if not playing:
			_freeze_new_particles()
	if not playing:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _freeze_new_particles() -> void:
	for node in _nodes(effect):
		if node is GPUParticles3D or node is CPUParticles3D:
			var id := node.get_instance_id()
			if not paused_speeds.has(id):
				paused_speeds[id] = node.speed_scale
			node.speed_scale = 0.0

func _is_inspired_projectile() -> bool:
	return descriptor.get("pack_id") == "inspired_projectiles" and is_instance_valid(effect)

func _update_inspired_projectile(delta: float) -> void:
	projectile_clock += delta
	var lifetime := maxf(float(effect.get("lifetime")), 0.001)
	if repeat_effect and projectile_clock >= maxf(repeat_interval, lifetime + 0.5):
		_restart_inspired_projectile()
		return
	effect.set("age", projectile_clock)
	# Match the author's end-of-flight fade without queue_free or a second motion driver.
	var fade_time := minf(lifetime, maxf(float(effect.get("fade_time")), 0.001))
	var fade := clampf((projectile_clock - (lifetime - fade_time)) / fade_time, 0.0, 1.0)
	for path in ["Emitters", "TrailPrefab"]:
		effect.get_node(path).scale = projectile_scales[path] * maxf(1.0 - fade, 0.001)
	if fade > 0.0:
		for node in effect.get_node("Emitters").get_children():
			if node is GPUParticles3D or node is CPUParticles3D:
				node.emitting = false

func _restart_inspired_projectile() -> void:
	projectile_clock = 0.0
	effect.set("age", 0.0)
	effect.set("collided", false)
	for path in ["Emitters", "TrailPrefab"]:
		effect.get_node(path).scale = projectile_scales[path]
	for node in _nodes(effect.get_node("Emitters")):
		if node is GPUParticles3D or node is CPUParticles3D:
			node.visible = true
			node.restart()
			node.emitting = true
	# Impact emitters belong to collision playback, not the projectile launch.
	for node in _nodes(effect.get_node("Impact")):
		if node is GPUParticles3D or node is CPUParticles3D:
			node.restart()
			node.emitting = false
	var trail := effect.get_node("TrailPrefab")
	for key in ["points", "uvs", "widths", "age"]:
		trail.get(key).clear()
	trail.previous_position = trail.global_position
	if trail.mesh is ImmediateMesh:
		trail.mesh.clear_surfaces()

func set_playing(value: bool) -> void:
	var was_playing := playing
	playing = value
	Engine.time_scale = 1.0 if value else 0.0
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED
	if is_instance_valid(effect):
		effect.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
		for node in _nodes(effect):
			if node is GPUParticles3D or node is CPUParticles3D or node is AnimationPlayer:
				var id := node.get_instance_id()
				if not value and was_playing:
					paused_speeds[id] = node.speed_scale
					node.speed_scale = 0.0
				elif value and not was_playing:
					node.speed_scale = paused_speeds.get(id, node.speed_scale)
		if value: paused_speeds.clear()

func set_playback_speed(value: float) -> void:
	var ratio := value / maxf(playback_speed, 0.01)
	playback_speed = value
	if is_instance_valid(effect):
		for node in _nodes(effect):
			if node is GPUParticles3D or node is CPUParticles3D or node is AnimationPlayer:
				var id := node.get_instance_id()
				if playing: node.speed_scale *= ratio
				else: paused_speeds[id] = paused_speeds.get(id, node.speed_scale) * ratio

func set_effect_scale(value: float) -> void:
	effect_scale = value
	if is_instance_valid(effect):
		effect.scale = authored_scale * value
		if descriptor.get("pack_id") == "soygus_tornado":
			effect.position = -framed_origin * effect.scale
		_align_ground_model()
		_center_camera_gust()

func tint(color: Color) -> void:
	if not is_instance_valid(effect):
		return
	for node in _nodes(effect):
		for key in ["preset", "palette"]:
			if key in node and node.get(key) is Resource:
				var palette: Resource = node.get(key)
				for property in ["color_core", "color_main", "color_accent", "core_color", "glow_color", "light_color", "spark_color", "main_color", "secondary_color", "tertiary_color"]:
					if property in palette:
						palette.set(property, color)
		for p in node.get_property_list():
			if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_EDITOR and p.type == TYPE_COLOR:
				var previous: Color = node.get(p.name)
				var next := color
				next.a = previous.a
				node.set(p.name, next)
		if node is GPUTrail3D:
			_set_trail_gradient(node, color)
		if node is Light3D:
			node.light_color = color
		if node is CanvasItem and node.material is ShaderMaterial:
			_tint_shader(node.material, color)
		if node is GeometryInstance3D:
			for material in _materials(node):
				if material is ShaderMaterial:
					_tint_shader(material, color)
		if node is GPUParticles3D and node.process_material is ParticleProcessMaterial:
			node.process_material.color = color

func _tint_shader(material: ShaderMaterial, color: Color) -> void:
	for p in material.shader.get_shader_uniform_list():
		if p.type == TYPE_COLOR:
			material.set_shader_parameter(p.name, color)
		elif p.type == TYPE_VECTOR3 and "color" in p.name.to_lower():
			material.set_shader_parameter(p.name, Vector3(color.r, color.g, color.b))

func _set_trail_gradient(node: GPUTrail3D, color: Color) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color, 0.0))
	gradient.set_color(1, color)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	node.color_ramp = texture

static func _nodes(root: Node) -> Array[Node]:
	var result: Array[Node] = [root]
	for child in root.get_children(true):
		result.append_array(_nodes(child))
	return result

static func _materials(node: GeometryInstance3D) -> Array[Material]:
	var result: Array[Material] = []
	if node.material_override:
		result.append(node.material_override)
	if node.material_overlay:
		result.append(node.material_overlay)
	if node is MeshInstance3D and node.mesh:
		for i in node.mesh.get_surface_count():
			var material: Material = node.get_active_material(i)
			if material and material not in result:
				result.append(material)
	if node is GPUParticles3D:
		for i in node.draw_passes:
			var mesh: Mesh = node.get_draw_pass_mesh(i)
			if mesh:
				for index in mesh.get_surface_count():
					var material: Material = mesh.surface_get_material(index)
					if material and material not in result:
						result.append(material)
	return result

func _camera_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		yaw -= event.relative.x * 0.008
		pitch = clampf(pitch - event.relative.y * 0.006, -1.2, 0.15)
		_update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(2.0, distance * 0.90)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(35.0, distance * 1.1)
		_update_camera()

func _update_camera() -> void:
	camera.position = focus + Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * distance
	camera.look_at(focus)
	if not playing:
		# Render the changed camera without advancing effects or shader time.
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func camera_preset(id: int) -> void:
	match id:
		0: yaw = 0.6; pitch = -0.24; distance = 9.5
		1: yaw = 0; pitch = -0.08; distance = 9.5
		2: yaw = 0; pitch = -1.15; distance = 10
		3: yaw = 1.57; pitch = -0.1; distance = 9.5
	_update_camera()
