extends Control

const CATEGORIES := ["全部效果", "攻击 / 刀光", "受击 / 冲击", "魔法 / 飞弹", "激光 / 射线", "火焰 / 火球", "电击 / 闪电", "掉落 / 拾取", "状态 / 护盾", "范围 / 魔法阵", "拖尾 / 插件", "官方 / 粒子", "资源 / 授权"]
const PRESETS := [
	{"name":"作者默认", "color":"ffffff", "scale":1.0, "speed":1.0},
	{"name":"烈焰 · Fire", "color":"ff702a", "secondary":"ffcf76", "scale":1.15, "speed":1.1},
	{"name":"冰霜 · Frost", "color":"57c9ff", "secondary":"d8f8ff", "scale":0.95, "speed":0.75},
	{"name":"奥术 · Arcane", "color":"b67aff", "secondary":"70e7ed", "scale":1.1, "speed":0.9},
	{"name":"剧毒 · Poison", "color":"79ed66", "secondary":"d3ff5c", "scale":1.0, "speed":0.8},
	{"name":"圣光 · Holy", "color":"ffdc8b", "secondary":"fff7db", "scale":1.3, "speed":0.6}
]

var catalog: Array = []
var sources: Array = []
var category := "全部效果"
var current: Dictionary = {}
var stage: PreviewStage
var inspector: PropertyInspector
var library: Tree
var library_search: LineEdit
var nav_buttons: Array[Button] = []
var title_label: Label
var subtitle: Label
var footer: Label
var stats: Label
var workspace: HBoxContainer
var source_panel: ScrollContainer
var source_list: VBoxContainer
var source_cards: VBoxContainer
var source_name_filter: LineEdit
var source_origin_filter: LineEdit
var source_result_label: Label
var preset_picker: OptionButton
var preset_name: LineEdit
var saved_picker: OptionButton
var saved: Array = []
var baselines: Dictionary = {}
var session: Dictionary = {}
var export_dialog: FileDialog
var import_dialog: FileDialog
var pause_button: Button
var speed_control: HSlider
var scale_control: HSlider
var source_link: Button
var busy := false
var built := false
var storage_path := "user://lab_presets_qa.json" if "--qa" in OS.get_cmdline_user_args() else "user://lab_presets.json"
var export_kind := "preset"

func _ready() -> void:
	theme = LabTheme.build()
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	sources = JSON.parse_string(FileAccess.get_file_as_string("res://data/sources.json"))
	_read_saved()
	_build_ui()
	built = true
	_build_library()
	if not catalog.is_empty():
		var first := 0
		for i in catalog.size():
			if catalog[i].pack_id == "binbun_beam": first = i; break
		select_entry(catalog[first])
	if "--qa" in OS.get_cmdline_user_args():
		call_deferred("_run_qa")
	elif "--smoke" in OS.get_cmdline_user_args():
		call_deferred("_run_smoke")
	elif "--interaction-qa" in OS.get_cmdline_user_args():
		call_deferred("_run_interaction_qa")
	elif "--requested-qa" in OS.get_cmdline_user_args():
		call_deferred("_run_requested_qa")

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = LabTheme.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 18)
	add_child(margin)
	var root := VBoxContainer.new()
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	brand.add_child(LabTheme.label("VFX LAB", 28, LabTheme.ACCENT))
	brand.add_child(LabTheme.label("3D 特效实验室  /  真实资源 · 实时参数 · 中文说明", 13, LabTheme.MUTED))
	stats = LabTheme.label("", 13, LabTheme.MUTED)
	header.add_child(stats)
	header.add_child(LabTheme.button("资源与授权 ↗", func(): _switch_category("资源 / 授权")))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := PanelContainer.new()
	left.custom_minimum_size.x = 252
	body.add_child(left)
	var left_column := VBoxContainer.new()
	left.add_child(left_column)
	left_column.add_child(LabTheme.label("探索资源", 18))
	var nav_scroll := ScrollContainer.new()
	nav_scroll.custom_minimum_size.y = 310
	nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_column.add_child(nav_scroll)
	var nav_column := VBoxContainer.new()
	nav_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_column.add_theme_constant_override("separation", 3)
	nav_scroll.add_child(nav_column)
	var nav_group := ButtonGroup.new()
	for text in CATEGORIES:
		var button := Button.new()
		button.text = text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_group = nav_group
		button.button_pressed = text == category
		button.pressed.connect(_switch_category.bind(text))
		button.custom_minimum_size.y = 28
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			var style: StyleBoxFlat = theme.get_stylebox(state, "Button").duplicate()
			style.content_margin_top = 4
			style.content_margin_bottom = 4
			button.add_theme_stylebox_override(state, style)
		nav_buttons.append(button)
		nav_column.add_child(button)
	left_column.add_child(HSeparator.new())
	library_search = LineEdit.new()
	library_search.placeholder_text = "查找资源 / 效果"
	library_search.text_changed.connect(func(_value: String): _build_library())
	left_column.add_child(library_search)
	library = Tree.new()
	library.hide_root = true
	library.size_flags_vertical = Control.SIZE_EXPAND_FILL
	library.custom_minimum_size.y = 160
	library.item_selected.connect(_library_selected)
	left_column.add_child(library)
	left_column.add_child(LabTheme.label("原始免费资源 + 插件\n付费与待接入项见资源页", 11, LabTheme.MUTED))
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(content)
	workspace = HBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(workspace)
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.add_child(center)
	var top := PanelContainer.new()
	center.add_child(top)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(titles)
	title_label = LabTheme.label("", 20)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titles.add_child(title_label)
	subtitle = LabTheme.label("", 12, LabTheme.MUTED)
	subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titles.add_child(subtitle)
	source_link = LabTheme.button("来源 ↗", func(): if current.has("url") and not current.url.is_empty(): OS.shell_open(current.url))
	top_row.add_child(source_link)
	var stage_panel := PanelContainer.new()
	stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_panel.clip_contents = true
	stage_panel.add_theme_stylebox_override("panel", LabTheme.box(Color("0b1321"), 10, Color("26384e")))
	center.add_child(stage_panel)
	stage = PreviewStage.new()
	stage_panel.add_child(stage)
	var toolbar := HBoxContainer.new()
	center.add_child(toolbar)
	toolbar.add_child(LabTheme.button("↻ 重播", func(): stage.replay()))
	pause_button = LabTheme.button("Ⅱ 暂停", func():
		stage.set_playing(not stage.playing)
		pause_button.text = "Ⅱ 暂停" if stage.playing else "▶ 继续")
	toolbar.add_child(pause_button)
	var repeat := CheckButton.new()
	repeat.text = "循环"
	repeat.button_pressed = true
	repeat.toggled.connect(func(value: bool): stage.repeat_effect = value)
	toolbar.add_child(repeat)
	var camera := OptionButton.new()
	for label in ["透视镜头", "正面镜头", "俯视镜头", "侧面镜头"]: camera.add_item(label)
	camera.item_selected.connect(func(index: int): stage.camera_preset(index))
	toolbar.add_child(camera)
	var options := MenuButton.new()
	options.text = "舞台设置"
	var menu := options.get_popup()
	for label in ["显示网格", "环境辉光", "目标移动"]: menu.add_check_item(label)
	for i in 3: menu.set_item_checked(i, true)
	menu.id_pressed.connect(func(index: int):
		menu.set_item_checked(index, not menu.is_item_checked(index))
		if index == 0: stage.grid.visible = menu.is_item_checked(index)
		elif index == 1: stage.environment.glow_enabled = menu.is_item_checked(index)
		elif index == 2: stage.orbit_target = menu.is_item_checked(index))
	toolbar.add_child(options)
	var tuning := PanelContainer.new()
	center.add_child(tuning)
	var tuning_col := VBoxContainer.new()
	tuning.add_child(tuning_col)
	var controls := HBoxContainer.new()
	tuning_col.add_child(controls)
	scale_control = _slider(controls, "整体缩放", 0.15, 3.0, 1.0, func(value: float): stage.set_effect_scale(value))
	speed_control = _slider(controls, "播放倍率", 0.1, 3.0, 1.0, func(value: float): stage.set_playback_speed(value))
	var motion := HBoxContainer.new()
	tuning_col.add_child(motion)
	_slider(motion, "运动速度", 0.1, 4.0, 1.0, func(value: float): stage.motion_speed = value)
	_slider(motion, "轨迹半径", 0.3, 5.0, 2.0, func(value: float): stage.path_radius = value)
	center.add_child(LabTheme.label("右键拖动旋转镜头 · 滚轮缩放 · 空格暂停 · R 重播", 11, LabTheme.MUTED))
	var right := PanelContainer.new()
	right.custom_minimum_size.x = 360
	workspace.add_child(right)
	var right_col := VBoxContainer.new()
	right.add_child(right_col)
	var parameter_header := HBoxContainer.new()
	right_col.add_child(parameter_header)
	var parameter_title := LabTheme.label("参数 / Parameters", 18)
	parameter_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameter_header.add_child(parameter_title)
	parameter_header.add_child(LabTheme.button("参数清单", func():
		if current.is_empty(): return
		export_kind = "parameters"
		export_dialog.current_file = current.path.get_file().get_basename() + "_parameters.json"
		export_dialog.popup_centered_ratio()))
	var preset_row := HBoxContainer.new()
	right_col.add_child(preset_row)
	preset_picker = OptionButton.new()
	preset_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for preset in PRESETS: preset_picker.add_item(preset.name)
	preset_picker.item_selected.connect(_apply_template)
	preset_row.add_child(preset_picker)
	preset_row.add_child(LabTheme.button("重置", _reset_current))
	inspector = PropertyInspector.new()
	inspector.preview_stage = stage
	inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(inspector)
	inspector.parameter_changed.connect(func(_key: String, _value: Variant):
		if not stage.playing: stage.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		footer.text = "已实时应用参数 · 当前实例独立于作者默认资源")
	right_col.add_child(HSeparator.new())
	var save_row := HBoxContainer.new()
	right_col.add_child(save_row)
	preset_name = LineEdit.new()
	preset_name.placeholder_text = "我的预设名称"
	preset_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_row.add_child(preset_name)
	save_row.add_child(LabTheme.button("保存", _save_preset))
	var saved_row := HBoxContainer.new()
	right_col.add_child(saved_row)
	saved_picker = OptionButton.new()
	saved_picker.fit_to_longest_item = false
	saved_picker.clip_text = true
	saved_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saved_row.add_child(saved_picker)
	saved_row.add_child(LabTheme.button("加载", _load_preset))
	saved_row.add_child(LabTheme.button("导出", _export_preset))
	_refresh_saved()
	source_panel = ScrollContainer.new()
	source_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	source_panel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(source_panel)
	source_panel.hide()
	source_list = VBoxContainer.new()
	source_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	source_panel.add_child(source_list)
	_build_source_page()
	footer = LabTheme.label("准备就绪", 12, LabTheme.MUTED)
	footer.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	root.add_child(footer)
	export_dialog = FileDialog.new()
	export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.use_native_dialog = true
	export_dialog.filters = PackedStringArray(["*.json ; VFX 预设"])
	export_dialog.file_selected.connect(_write_export)
	add_child(export_dialog)
	import_dialog = FileDialog.new()
	import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	import_dialog.use_native_dialog = true
	import_dialog.filters = PackedStringArray(["*.tscn ; 项目内 Godot 成品场景", "*.json ; 导入 VFX 预设"])
	import_dialog.file_selected.connect(_import_local)
	add_child(import_dialog)

func _slider(parent: HBoxContainer, text: String, low: float, high: float, value: float, callback: Callable) -> HSlider:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var label := LabTheme.label("%s  %.2f" % [text, value], 12, LabTheme.MUTED)
	column.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low; slider.max_value = high; slider.step = 0.01; slider.value = value
	column.add_child(slider)
	slider.value_changed.connect(func(next: float): label.text = "%s  %.2f" % [text, next]; callback.call(next))
	return slider

func _switch_category(value: String) -> void:
	category = value
	for button in nav_buttons: button.button_pressed = button.text == value
	workspace.visible = value != "资源 / 授权"
	source_panel.visible = value == "资源 / 授权"
	stage.set_playing(value != "资源 / 授权")
	_build_library()
	if value == "资源 / 授权":
		footer.text = "绿色 = 已接入可运行 · 金色 = 待导入 / 需额外工具 · 灰色 = 不适配已排除"
		return
	var filtered: Array = catalog.filter(func(entry: Dictionary): return value == "全部效果" or entry.category == value)
	if not filtered.is_empty():
		select_entry(filtered[0])
	else:
		title_label.text = value + " · 尚未持有成品资源"
		subtitle.text = "可在「资源 / 授权」查看调研结果与来源"
		current = {}
		stage.load_effect({})
		inspector.inspect(null)
		footer.text = "此分类尚未导入，不使用自制效果替代调研成品。"

func _build_library() -> void:
	library.clear()
	var root := library.create_item()
	var pack_items := {}
	for entry in catalog:
		if category not in ["全部效果", "资源 / 授权"] and entry.category != category: continue
		if not library_search.text.is_empty() and library_search.text.to_lower() not in (entry.name + entry.label).to_lower(): continue
		if not pack_items.has(entry.pack_id):
			var pack: TreeItem = library.create_item(root)
			pack.set_text(0, entry.name)
			pack.set_selectable(0, false)
			pack.set_custom_color(0, LabTheme.ACCENT)
			pack_items[entry.pack_id] = pack
		var item := library.create_item(pack_items[entry.pack_id])
		item.set_text(0, entry.label)
		item.set_metadata(0, entry)
		item.set_tooltip_text(0, entry.label + "\n" + entry.path)

func _library_selected() -> void:
	var item := library.get_selected()
	if item and item.get_metadata(0) is Dictionary:
		var entry: Dictionary = item.get_metadata(0)
		if category == "资源 / 授权": _switch_category("全部效果")
		select_entry(entry)

func select_entry(entry: Dictionary) -> void:
	if busy: return
	busy = true
	if not current.is_empty() and is_instance_valid(stage.effect): session[current.id] = inspector.snapshot()
	current = entry
	title_label.text = entry.label
	subtitle.text = "%s  ·  %s  ·  原始资源" % [entry.name, entry.license]
	preset_picker.select(0)
	stage.set_playback_speed(1.0)
	stage.load_effect(entry)
	inspector.inspect(stage.effect)
	if not baselines.has(entry.id): baselines[entry.id] = inspector.snapshot()
	if session.has(entry.id): inspector.restore(session[entry.id])
	scale_control.value = 1
	speed_control.value = 1
	pause_button.text = "Ⅱ 暂停"
	_refresh_saved()
	footer.text = "%s · %d 个参数 · %s" % [entry.category, inspector.all_parameters.size(), entry.description]
	busy = false

func _reset_current() -> void:
	if current.is_empty(): return
	var entry := current.duplicate()
	session.erase(entry.id)
	current = {}
	select_entry(entry)

func _apply_template(index: int) -> void:
	if current.is_empty(): return
	speed_control.value = 1.0
	scale_control.value = 1.0
	inspector.restore(baselines[current.id])
	var preset: Dictionary = PRESETS[index]
	scale_control.value = preset.scale
	speed_control.value = preset.speed
	if index > 0:
		stage.tint(Color(preset.color))
		inspector.set_named("secondary_color", Color(preset.secondary))
		inspector.set_named("tertiary_color", Color(preset.secondary).darkened(0.3))
		inspector.set_named("startColor", Color(preset.color))
		inspector.set_named("endColor", Color(Color(preset.secondary), 0.0))
		if current.id == "gpu_trail":
			inspector.set_named("length", [100, 90, 150, 130, 75, 180][index])
	inspector.inspect(stage.effect)
	preset_picker.select(index)
	stage.replay()
	footer.text = "已应用实验室模板「%s」· 模板基于当前免费资源，不代表付费预设" % preset.name

func _ordered_sources() -> Array:
	var ordered := sources.duplicate()
	var status_order := {"installed": 0, "pending": 1, "excluded": 2}
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_status: int = status_order.get(a.status, 3)
		var b_status: int = status_order.get(b.status, 3)
		if a_status != b_status:
			return a_status < b_status
		var author_order := str(a.get("author", "作者未注明")).naturalnocasecmp_to(str(b.get("author", "作者未注明")))
		if author_order != 0:
			return author_order < 0
		var a_title: String = str(a.name).split(" · ", true, 1)[-1]
		var b_title: String = str(b.name).split(" · ", true, 1)[-1]
		var title_order := a_title.naturalnocasecmp_to(b_title)
		if title_order != 0:
			return title_order < 0
		return str(a.id).naturalnocasecmp_to(str(b.id)) < 0
	)
	return ordered

func _build_source_page() -> void:
	source_list.add_child(LabTheme.label("资源与授权", 28))
	var tools := HBoxContainer.new()
	source_list.add_child(tools)
	tools.add_child(LabTheme.button("导入项目场景 / JSON 预设", func(): import_dialog.popup_centered_ratio()))
	tools.add_child(LabTheme.button("打开项目目录", func(): OS.shell_open(ProjectSettings.globalize_path("res://"))))
	var filters := HBoxContainer.new()
	source_list.add_child(filters)
	filters.add_child(LabTheme.label("资源名称", 13, LabTheme.MUTED))
	source_name_filter = LineEdit.new()
	source_name_filter.placeholder_text = "输入资源名称"
	source_name_filter.clear_button_enabled = true
	source_name_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(source_name_filter)
	filters.add_child(LabTheme.label("来源", 13, LabTheme.MUTED))
	source_origin_filter = LineEdit.new()
	source_origin_filter.placeholder_text = "来源名称、平台或网址"
	source_origin_filter.clear_button_enabled = true
	source_origin_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(source_origin_filter)
	source_result_label = LabTheme.label("", 12, LabTheme.MUTED)
	source_list.add_child(source_result_label)
	source_cards = VBoxContainer.new()
	source_list.add_child(source_cards)
	source_name_filter.text_changed.connect(func(_value: String): _refresh_source_cards())
	source_origin_filter.text_changed.connect(func(_value: String): _refresh_source_cards())
	_refresh_source_cards()

func _refresh_source_cards() -> void:
	for child in source_cards.get_children():
		source_cards.remove_child(child)
		child.queue_free()
	var name_query := source_name_filter.text.strip_edges().to_lower()
	var origin_query := source_origin_filter.text.strip_edges().to_lower()
	var ordered := _ordered_sources()
	ordered = ordered.filter(func(source: Dictionary) -> bool:
		var origin := str(source.get("author", "来源未注明")) + " " + str(source.url)
		return (name_query.is_empty() or name_query in str(source.name).to_lower()) and (origin_query.is_empty() or origin_query in origin.to_lower())
	)
	source_result_label.text = "显示 %d / %d 项资源" % [ordered.size(), sources.size()]
	if ordered.is_empty():
		source_cards.add_child(LabTheme.label("没有匹配的资源，请调整资源名称或来源筛选。", 16, LabTheme.MUTED))
		return
	var last_status := ""
	for source in ordered:
		if source.status != last_status:
			last_status = source.status
			var section_name: String = {"installed": "已接入", "pending": "待导入", "excluded": "不适配"}.get(last_status, last_status)
			var count := ordered.filter(func(item: Dictionary): return item.status == last_status).size()
			var section := LabTheme.label("%s · %d 项" % [section_name, count], 22)
			section.custom_minimum_size.y = 48
			source_cards.add_child(section)
		var card := PanelContainer.new()
		card.set_meta("source_id", source.id)
		source_cards.add_child(card)
		var column := VBoxContainer.new()
		card.add_child(column)
		var row := HBoxContainer.new()
		column.add_child(row)
		var label := LabTheme.label(source.name, 19)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var status_text: String = {"installed": "已接入 · 可运行", "pending": "待导入 · 未持有", "excluded": "不适配 · 已排除"}.get(source.status, source.status)
		row.add_child(LabTheme.label(status_text, 12, LabTheme.ACCENT if source.status == "installed" else (LabTheme.MUTED if source.status == "excluded" else LabTheme.GOLD)))
		row.add_child(LabTheme.button("原始来源 ↗", func(): OS.shell_open(source.url)))
		column.add_child(LabTheme.label("来源：%s" % source.get("author", "来源未注明"), 13, LabTheme.ACCENT))
		var description := LabTheme.label(source.description, 14, LabTheme.MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(description)
		column.add_child(LabTheme.label("分类：%s   /   授权：%s" % [source.category, source.license], 12, LabTheme.MUTED))
		if source.status == "installed":
			column.add_child(LabTheme.button("查看效果", func(): _show_source(source.id)))
		elif source.status == "excluded":
			column.add_child(LabTheme.label("未加入效果目录；当前交付不适配 Godot。", 12, LabTheme.MUTED))
		else:
			column.add_child(LabTheme.label("购买或下载后保留完整目录，用 tools/import_pack.py 接入再启动项目。", 12, LabTheme.MUTED))

func _show_source(id: String) -> void:
	for entry in catalog:
		if entry.pack_id == id:
			_switch_category(entry.category)
			select_entry(entry)
			return

func _read_saved() -> void:
	if FileAccess.file_exists(storage_path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(storage_path))
		if data is Array: saved = data

func _refresh_saved() -> void:
	if not saved_picker: return
	saved_picker.clear()
	for preset in saved:
		if not current.is_empty() and preset.effect_id == current.id:
			saved_picker.add_item(preset.name)
			saved_picker.set_item_metadata(saved_picker.item_count - 1, preset)
	if saved_picker.item_count == 0:
		saved_picker.add_item("尚无已保存预设")
		saved_picker.set_item_disabled(0, true)

func _preset_record() -> Dictionary:
	return {"format": "godot-vfx-lab/1", "name": preset_name.text.strip_edges() if not preset_name.text.strip_edges().is_empty() else "自定义 · " + current.label, "effect_id": current.id, "effect_path": current.path, "source_url": current.url, "created": Time.get_datetime_string_from_system(), "parameters": inspector.snapshot(), "stage": {"scale": stage.effect_scale, "speed": stage.playback_speed, "motion_speed": stage.motion_speed, "path_radius": stage.path_radius}}

func _save_preset() -> void:
	if current.is_empty(): return
	var record := _preset_record()
	saved = saved.filter(func(item: Dictionary): return not (item.effect_id == record.effect_id and item.name == record.name))
	saved.append(record)
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(saved, "\t"))
	_refresh_saved()
	footer.text = "预设已保存；重新启动后仍可加载。"

func _load_preset() -> void:
	if saved_picker.selected < 0: return
	var record: Variant = saved_picker.get_item_metadata(saved_picker.selected)
	if record is Dictionary: _restore_record(record)

func _restore_record(record: Dictionary) -> void:
	if record.has("stage"):
		scale_control.value = float(record.stage.scale)
		speed_control.value = float(record.stage.speed)
		stage.motion_speed = float(record.stage.motion_speed)
		stage.path_radius = float(record.stage.path_radius)
	inspector.restore(record.parameters)
	footer.text = "已加载「%s」" % record.name

func _export_preset() -> void:
	if current.is_empty(): return
	export_kind = "preset"
	export_dialog.current_file = current.path.get_file().get_basename() + "_preset.json"
	export_dialog.popup_centered_ratio()

func _write_export(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		footer.text = "无法写入预设：" + error_string(FileAccess.get_open_error())
		return
	var data: Dictionary
	if export_kind == "parameters":
		var parameters: Array[Dictionary] = []
		for p in inspector.all_parameters:
			parameters.append({"id":p.id, "english":p.key, "chinese":ParameterDictionary.translate(p.key), "description":ParameterDictionary.describe(p.key), "value":var_to_str(inspector.read(p)) if not inspector.read(p) is Object else str(inspector.read(p)), "type":type_string(p.type), "hint":p.hint_string})
		data = {"effect":current.label, "source":current.url, "parameters":parameters}
	else:
		data = _preset_record()
	file.store_string(JSON.stringify(data, "\t"))
	footer.text = "已导出 JSON 预设：" + path

func _import_local(path: String) -> void:
	if path.get_extension().to_lower() == "json":
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary or data.get("format") != "godot-vfx-lab/1":
			footer.text = "不是 VFX LAB 的有效 JSON 预设。"
			return
		for entry in catalog:
			if entry.id == data.effect_id:
				_switch_category(entry.category)
				select_entry(entry)
				saved.append(data)
				_save_imported()
				_restore_record(data)
				return
		footer.text = "预设对应的成品资源尚未安装。"
		return
	var local := ProjectSettings.localize_path(path)
	if not local.begins_with("res://"):
		footer.text = "请先用 tools/import_pack.py 导入完整资源包；单独复制场景会丢失依赖。"
		return
	var entry := {"id": local, "pack_id": "local", "name": "本地成品资源", "category": "综合资源", "mode": "static", "label": path.get_file(), "path": local, "url": "", "license": "以原始资源为准", "description": "从项目目录载入的用户资源"}
	catalog.append(entry)
	_switch_category("全部效果")
	select_entry(entry)

func _save_imported() -> void:
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(saved, "\t"))
	_refresh_saved()

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if not focused is LineEdit and not focused is TextEdit:
		return
	var field: Control = focused
	if focused.get_parent() is SpinBox:
		field = focused.get_parent()
	if not field.get_global_rect().has_point(event.position):
		focused.release_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if get_viewport().gui_get_focus_owner() is LineEdit: return
		if event.keycode == KEY_SPACE:
			stage.set_playing(not stage.playing)
			pause_button.text = "Ⅱ 暂停" if stage.playing else "▶ 继续"
		if event.keycode == KEY_R: stage.replay()

func _process(_delta: float) -> void:
	if built:
		stats.text = "%d 个效果 · %d 来源 · %d FPS · %s" % [catalog.size(), sources.size(), Engine.get_frames_per_second(), RenderingServer.get_current_rendering_method()]

func _run_qa() -> void:
	await get_tree().process_frame
	var qa: Node = load("res://tools/qa.gd").new()
	add_child(qa)
	qa.run(self)

func _run_smoke() -> void:
	var smoke: Node = load("res://tools/smoke.gd").new()
	add_child(smoke)
	smoke.run(self)

func _run_interaction_qa() -> void:
	var qa: Node = load("res://tools/interaction_regression.gd").new()
	add_child(qa)
	qa.run(self)

func _run_requested_qa() -> void:
	var qa: Node = load("res://tools/requested_qa.gd").new()
	add_child(qa)
	qa.run(self)
