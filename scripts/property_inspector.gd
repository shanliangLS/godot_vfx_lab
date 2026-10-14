class_name PropertyInspector extends VBoxContainer

signal parameter_changed(key: String, value: Variant)

var root_effect: Node3D
var groups: Array[Dictionary] = []
var all_parameters: Array[Dictionary] = []
var selected := 0
var selector: OptionButton
var search: LineEdit
var list: VBoxContainer
var count_label: Label
var picker: FileDialog
var pending_resource: Dictionary = {}

func _ready() -> void:
	selector = OptionButton.new()
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.item_selected.connect(func(index: int): selected = index; _render())
	add_child(selector)
	search = LineEdit.new()
	search.placeholder_text = "搜索中文 / English 参数"
	search.text_changed.connect(func(_text: String): _render())
	add_child(search)
	count_label = LabTheme.label("", 12, LabTheme.MUTED)
	add_child(count_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	picker = FileDialog.new()
	picker.access = FileDialog.ACCESS_FILESYSTEM
	picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	picker.use_native_dialog = true
	picker.filters = PackedStringArray(["*.png, *.jpg, *.webp, *.svg ; 纹理", "*.wav, *.ogg, *.mp3 ; 音频", "*.tres ; Godot 资源"])
	picker.file_selected.connect(_resource_selected)
	add_child(picker)

func inspect(effect: Node3D) -> void:
	root_effect = effect
	groups.clear()
	all_parameters.clear()
	selector.clear()
	selected = 0
	search.text = ""
	if not is_instance_valid(effect):
		_render()
		return
	for node in PreviewStage._nodes(effect):
		var relative := String(effect.get_path_to(node))
		var fields: Array[Dictionary] = []
		for property in node.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_EDITOR:
				if property.type != TYPE_NIL:
					fields.append(_descriptor(node, property, relative + ":" + property.name))
		if node is GPUParticles3D or node is CPUParticles3D:
			for key in ["amount", "lifetime", "one_shot", "emitting", "preprocess", "explosiveness", "randomness", "speed_scale", "fixed_fps", "local_coords", "trail_enabled", "trail_lifetime"]:
				_add_builtin(node, key, relative, fields)
		if node is Light3D:
			for key in ["light_color", "light_energy", "light_indirect_energy", "shadow_enabled", "omni_range"]:
				_add_builtin(node, key, relative, fields)
		if not fields.is_empty():
			_add_group(("主控制器" if node == effect else relative) + " · " + node.get_class(), fields)
		if node is GPUParticles3D and node.process_material is ParticleProcessMaterial:
			_add_resource(node.process_material, relative + "/粒子材质", relative + ":process", 0)
		if node is GeometryInstance3D:
			var index := 0
			for material in PreviewStage._materials(node):
				_add_resource(material, relative + "/材质 " + str(index), relative + ":material" + str(index), 0)
				index += 1
		for p in fields:
			var value: Variant = read(p)
			if value is Resource and not value is Material and not value is Mesh and not value is Script:
				_add_resource(value, relative + "/" + ParameterDictionary.translate(p.key), p.id + ":resource", 0)
	for group in groups:
		selector.add_item(group.name)
	selector.tooltip_text = "查看主控制器、子节点、粒子材质和 Shader 的实际参数。资源对象也有独立参数页。"
	_render()

func _add_builtin(object: Object, key: String, relative: String, fields: Array[Dictionary]) -> void:
	for p in object.get_property_list():
		if p.name == key and not fields.any(func(item: Dictionary): return item.key == key):
			fields.append(_descriptor(object, p, relative + ":" + key))
			return

func _descriptor(object: Object, p: Dictionary, id: String, shader := false) -> Dictionary:
	return {"target": object, "key": String(p.name), "type": p.type, "hint": p.get("hint", 0), "hint_string": p.get("hint_string", ""), "id": id, "shader": shader}

func _add_group(title: String, fields: Array[Dictionary]) -> void:
	groups.append({"name": title, "fields": fields})
	all_parameters.append_array(fields)

func _add_resource(resource: Resource, title: String, id: String, depth: int) -> void:
	if depth > 2 or resource == null:
		return
	var fields: Array[Dictionary] = []
	if resource is ShaderMaterial and resource.shader:
		for p in resource.shader.get_shader_uniform_list():
			if p.type != TYPE_NIL:
				fields.append(_descriptor(resource, p, id + ":" + p.name, true))
	elif resource is GradientTexture1D or resource is GradientTexture2D or resource is CurveTexture:
		var key := "gradient" if "gradient" in resource else "curve"
		for p in resource.get_property_list():
			if p.name == key:
				fields.append(_descriptor(resource, p, id + ":" + key))
	else:
		for p in resource.get_property_list():
			if p.usage & PROPERTY_USAGE_EDITOR and p.name not in ["resource_local_to_scene", "resource_name", "script"] and not String(p.name).begins_with("resource_"):
				fields.append(_descriptor(resource, p, id + ":" + p.name))
	if fields.is_empty():
		return
	_add_group(title + " · " + resource.get_class(), fields)
	for p in fields:
		var value: Variant = read(p)
		if value is Resource and not value is Material and not value is Mesh and not value is Script:
			_add_resource(value, title + "/" + ParameterDictionary.translate(p.key), p.id + ":resource", depth + 1)

func read(p: Dictionary) -> Variant:
	if not is_instance_valid(p.target):
		return null
	return p.target.get_shader_parameter(p.key) if p.shader else p.target.get(p.key)

func write(p: Dictionary, value: Variant) -> void:
	if not is_instance_valid(p.target):
		return
	if p.shader:
		p.target.set_shader_parameter(p.key, value)
	else:
		p.target.set(p.key, value)
	parameter_changed.emit(p.id, value)

func _render() -> void:
	if list == null:
		return
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	if groups.is_empty():
		count_label.text = "当前资源没有可编辑参数"
		return
	var fields: Array = groups[selected].fields
	if not search.text.is_empty():
		fields = all_parameters.filter(func(p: Dictionary): return search.text.to_lower() in (p.key + ParameterDictionary.translate(p.key)).to_lower())
	count_label.text = "当前 %d 项 / 共 %d 项 · 悬停查看中文说明" % [fields.size(), all_parameters.size()]
	for p in fields:
		_add_editor(p)

func _add_editor(p: Dictionary) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", LabTheme.box(Color("172237"), 7))
	card.tooltip_text = ParameterDictionary.describe(p.key) + "\n" + p.id
	list.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	card.add_child(column)
	column.add_child(LabTheme.label(ParameterDictionary.translate(p.key), 14))
	var english := LabTheme.label(p.key, 11, LabTheme.MUTED)
	english.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(english)
	var value: Variant = read(p)
	match p.type:
		TYPE_BOOL:
			var check := CheckButton.new()
			check.text = "启用 / 禁用"
			check.button_pressed = bool(value)
			check.toggled.connect(func(next: bool): write(p, next))
			column.add_child(check)
		TYPE_INT, TYPE_FLOAT:
			if p.hint == PROPERTY_HINT_ENUM:
				var options := OptionButton.new()
				var idx := 0
				for choice in String(p.hint_string).split(","):
					var parts := choice.split(":")
					var choice_id := int(parts[1]) if parts.size() > 1 else idx
					options.add_item(ParameterDictionary.translate(parts[0]) + " · " + parts[0], choice_id)
					if choice_id == int(value): options.select(idx)
					idx += 1
				options.item_selected.connect(func(next: int): write(p, options.get_item_id(next)))
				column.add_child(options)
			else:
				column.add_child(_spin(p, float(value) if value != null else 0.0, func(next: float): write(p, int(next) if p.type == TYPE_INT else next)))
		TYPE_COLOR:
			var color := ColorPickerButton.new()
			color.custom_minimum_size.y = 30
			color.color = value if value is Color else Color.WHITE
			color.color_changed.connect(func(next: Color): write(p, next))
			column.add_child(color)
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var row := HBoxContainer.new()
			column.add_child(row)
			var count := 2 if p.type == TYPE_VECTOR2 else (3 if p.type == TYPE_VECTOR3 else 4)
			for axis in count:
				var cell := VBoxContainer.new()
				cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(cell)
				cell.add_child(LabTheme.label(["X", "Y", "Z", "W"][axis], 10, LabTheme.MUTED))
				cell.add_child(_spin(p, value[axis] if value != null else 0.0, func(next: float):
					var vector: Variant = read(p)
					if vector == null: vector = Vector2.ZERO if count == 2 else (Vector3.ZERO if count == 3 else Vector4.ZERO)
					vector[axis] = next
					write(p, vector)))
		TYPE_STRING, TYPE_STRING_NAME:
			var input := LineEdit.new()
			input.text = str(value)
			input.text_submitted.connect(func(next: String): write(p, StringName(next) if p.type == TYPE_STRING_NAME else next))
			column.add_child(input)
		TYPE_OBJECT:
			_resource_editor(column, p, value)
		TYPE_CALLABLE:
			column.add_child(LabTheme.button("执行 · " + ParameterDictionary.translate(p.key), func(): if value is Callable and value.is_valid(): value.call()))
		_:
			var info := LabTheme.label(str(value).left(100), 12, LabTheme.MUTED)
			info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			column.add_child(info)

func _spin(p: Dictionary, value: float, callback: Callable) -> SpinBox:
	var input := SpinBox.new()
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.min_value = -10000
	input.max_value = 10000
	input.step = 1 if p.type == TYPE_INT else 0.01
	input.update_on_text_changed = true
	var positive := ["amount", "particles_amount", "particle_amount", "start_amount", "end_amount", "length", "mesh_resolutions", "max_polyphony"]
	var nonnegative := ["radius", "beam_radius", "start_radius", "lifetime", "lifespan", "length_seconds", "speed_scale", "emission", "light_energy", "beam_length", "flame_density", "motionDelta", "motion_threshold", "noise_shape", "color_curve", "duration"]
	if p.key in positive: input.min_value = 1; input.max_value = 2048
	if p.key in nonnegative: input.min_value = 0.01; input.max_value = 100
	if p.key == "fixed_fps": input.min_value = 1
	if p.hint == PROPERTY_HINT_RANGE:
		var hints: PackedStringArray = String(p.hint_string).split(",")
		if hints.size() >= 2:
			input.min_value = float(hints[0])
			input.max_value = float(hints[1])
		if hints.size() >= 3 and hints[2].is_valid_float(): input.step = float(hints[2])
		input.allow_greater = "or_greater" in hints
		input.allow_lesser = "or_less" in hints
	input.value = value
	input.value_changed.connect(callback)
	return input

func _resource_editor(column: VBoxContainer, p: Dictionary, value: Variant) -> void:
	if value is Gradient:
		var row := HBoxContainer.new()
		column.add_child(row)
		for index in value.get_point_count():
			var button := ColorPickerButton.new()
			button.custom_minimum_size = Vector2(40, 28)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.color = value.get_color(index)
			button.tooltip_text = "渐变点 %.2f" % value.get_offset(index)
			button.color_changed.connect(func(next: Color): value.set_color(index, next); parameter_changed.emit(p.id, value))
			row.add_child(button)
		return
	if value is Curve:
		for index in value.point_count:
			var row := HBoxContainer.new()
			row.add_child(LabTheme.label("点 %.2f" % value.get_point_position(index).x, 12, LabTheme.MUTED))
			row.add_child(_spin({"type": TYPE_FLOAT, "key": "curve_value", "hint": PROPERTY_HINT_RANGE, "hint_string": "%s,%s,0.01" % [value.min_value, value.max_value]}, value.get_point_position(index).y, func(next: float): value.set_point_value(index, next); parameter_changed.emit(p.id, value)))
			column.add_child(row)
		return
	var description: String = "未指定 · " + p.hint_string if value == null else value.get_class()
	if value is Resource and not value.resource_path.is_empty(): description += " · " + value.resource_path.get_file()
	var info := LabTheme.label(description, 11, LabTheme.MUTED)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(info)
	if value is Texture2D or "Texture" in p.hint_string or p.key in ["noise_texture", "texture", "mask"]:
		if value is Texture2D:
			var preview := TextureRect.new()
			preview.texture = value
			preview.custom_minimum_size = Vector2(0, 56)
			preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			column.add_child(preview)
		var choices := OptionButton.new()
		for text in ["程序纹理…", "细密噪声", "流动噪声", "高对比噪声", "导入本地纹理"]: choices.add_item(text)
		choices.item_selected.connect(func(index: int):
			if index == 4: pending_resource = p; picker.popup_centered_ratio(); return
			if index == 0: return
			var noise := FastNoiseLite.new()
			noise.frequency = [0.04, 0.012, 0.065][index - 1]
			noise.fractal_octaves = 4
			var texture := NoiseTexture2D.new()
			texture.width = 256; texture.height = 256
			texture.seamless = true
			texture.noise = noise
			write(p, texture)
			call_deferred("inspect", root_effect))
		column.add_child(choices)
	elif "AudioStream" in p.hint_string:
		column.add_child(LabTheme.button("选择本地音频", func(): pending_resource = p; picker.popup_centered_ratio()))
	elif value is Node3D or "Node3D" in p.hint_string:
		column.add_child(LabTheme.label("已绑定预览舞台目标", 11, LabTheme.ACCENT))

func _resource_selected(path: String) -> void:
	if pending_resource.is_empty(): return
	var value: Resource
	if path.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp", "svg"]:
		var image := Image.load_from_file(path)
		if image: value = ImageTexture.create_from_image(image)
	elif path.get_extension().to_lower() == "wav": value = AudioStreamWAV.load_from_file(path)
	elif path.get_extension().to_lower() == "ogg": value = AudioStreamOggVorbis.load_from_file(path)
	elif path.get_extension().to_lower() == "mp3": value = AudioStreamMP3.load_from_file(path)
	elif path.begins_with(ProjectSettings.globalize_path("res://")): value = load(ProjectSettings.localize_path(path))
	if value:
		write(pending_resource, value)
		inspect(root_effect)
	pending_resource.clear()

func snapshot() -> Dictionary:
	var result := {}
	for p in all_parameters:
		var value: Variant = read(p)
		if value is Gradient:
			result[p.id] = {"kind": "gradient", "colors": var_to_str(value.colors), "offsets": var_to_str(value.offsets)}
		elif value is Curve:
			var points: Array = []
			for index in value.point_count: points.append(var_to_str(value.get_point_position(index)))
			result[p.id] = {"kind": "curve", "points": points}
		elif p.type in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_COLOR, TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4, TYPE_STRING, TYPE_STRING_NAME]:
			result[p.id] = {"kind": "value", "value": var_to_str(value)}
	return result

func restore(snapshot_data: Dictionary) -> void:
	for p in all_parameters:
		if not snapshot_data.has(p.id): continue
		var saved: Dictionary = snapshot_data[p.id]
		var value: Variant = read(p)
		if saved.kind == "value": write(p, str_to_var(saved.value))
		elif saved.kind == "gradient" and value is Gradient:
			value.colors = str_to_var(saved.colors)
			value.offsets = str_to_var(saved.offsets)
		elif saved.kind == "curve" and value is Curve:
			for index in mini(value.point_count, saved.points.size()):
				var point: Vector2 = str_to_var(saved.points[index])
				value.set_point_value(index, point.y)
	_render()

func set_named(key: String, value: Variant) -> void:
	for p in all_parameters:
		if p.key == key:
			write(p, value)
