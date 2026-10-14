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
var repeat_effect := true
var repeat_interval := 2.4
var playback_speed := 1.0
var effect_scale := 1.0
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
	effect_scale = 1
	playing = true
	material_records.clear()
	paused_speeds.clear()
	dummy.visible = entry.get("mode", "") == "hit"
	target.visible = entry.get("mode", "") == "beam"
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
	if effect is GPUTrail3D:
		effect.visibility_aabb = AABB(Vector3(-15, -15, -15), Vector3(30, 30, 30))
		effect.fixed_fps = 60
		_set_trail_gradient(effect, LabTheme.ACCENT)
	_setup_beam()
	_frame_effect()
	replay()
	effect_changed.emit(effect)

func _make_local(node: Node) -> void:
	for property in ["material_override", "material_overlay", "process_material", "mesh"]:
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
	if descriptor.get("mode") == "slash":
		carrier.position = Vector3(0, 1.5, 0)

func _setup_beam() -> void:
	if descriptor.get("mode") != "beam" or not effect:
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
	if not playing:
		return
	elapsed += delta * playback_speed
	var mode: String = descriptor.get("mode", "static")
	if mode == "trail" or mode == "projectile":
		var time := elapsed * motion_speed
		carrier.position = Vector3(sin(time * 1.4) * path_radius, 1.5 + sin(time * 2.1) * 0.4, cos(time * 1.4) * path_radius * 0.5)
		if mode == "projectile":
			var direction := Vector3(cos(time * 1.4), cos(time * 2.1) * 0.25, -sin(time * 1.4) * 0.5)
			carrier.look_at(carrier.global_position + direction)
	if mode == "beam":
		if orbit_target:
			target.position = Vector3(2.3, 1.2 + sin(elapsed) * 0.7, sin(elapsed * 0.7) * 1.5)
		if carrier.global_position.distance_squared_to(target.global_position) > 0.001:
			carrier.look_at(target.global_position)
	if repeat_effect and elapsed - last_repeat > repeat_interval and mode in ["hit", "slash", "area"]:
		last_repeat = elapsed
		replay()

func replay() -> void:
	if not is_instance_valid(effect):
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
		effect.scale = Vector3.ONE * value

func tint(color: Color) -> void:
	if not is_instance_valid(effect):
		return
	for node in _nodes(effect):
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
		if node is GeometryInstance3D:
			for material in _materials(node):
				if material is ShaderMaterial:
					for p in material.shader.get_shader_uniform_list():
						if p.type == TYPE_COLOR or (p.type == TYPE_VECTOR3 and "color" in p.name.to_lower()):
							material.set_shader_parameter(p.name, color if p.type == TYPE_COLOR else Vector3(color.r, color.g, color.b))
		if node is GPUParticles3D and node.process_material is ParticleProcessMaterial:
			node.process_material.color = color

func _set_trail_gradient(node: GPUTrail3D, color: Color) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color, 0.0))
	gradient.set_color(1, color)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	node.color_ramp = texture

static func _nodes(root: Node) -> Array[Node]:
	var result: Array[Node] = [root]
	for child in root.get_children():
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

func camera_preset(id: int) -> void:
	match id:
		0: yaw = 0.6; pitch = -0.24; distance = 9.5
		1: yaw = 0; pitch = -0.08; distance = 9.5
		2: yaw = 0; pitch = -1.15; distance = 10
		3: yaw = 1.57; pitch = -0.1; distance = 9.5
	_update_camera()
