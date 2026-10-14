extends Node
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error("LAYOUT_QA: " + message)

func capture(app: Control, name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw()
	app.get_viewport().get_texture().get_image().save_png("res://artifacts/layout-" + name + ".png")

func run(app: Control) -> void:
	await get_tree().process_frame
	var hint: Control = app.stage.get_node("CameraHintAnchor/CameraHint")
	check(hint.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Hint must pass camera input through")
	var rect: Rect2 = app.stage.get_global_rect()
	check(rect.encloses(hint.get_global_rect()), "Hint stays inside preview")
	check(hint.get_global_rect().end.distance_to(rect.end) < 25.0, "Hint sits at bottom right")
	check(hint.size.is_equal_approx(hint.get_combined_minimum_size()), "Hint background fits text")
	var hint_style := hint.get_theme_stylebox("panel")
	check(hint_style.content_margin_top == 3 and hint_style.content_margin_bottom == 3, "Compact hint vertical padding")
	var hint_label: Label = hint.get_child(0)
	var original_hint := hint_label.text
	var original_size := hint.size
	hint_label.text = "镜头提示"
	await get_tree().process_frame
	await get_tree().process_frame
	check(hint.size.x < original_size.x and hint.size.is_equal_approx(hint.get_combined_minimum_size()), "Hint shrinks with shorter text")
	hint_label.text = "镜头提示\n第二行操作"
	await get_tree().process_frame
	await get_tree().process_frame
	check(hint.size.y > original_size.y and hint.size.is_equal_approx(hint.get_combined_minimum_size()), "Hint grows with multiline text")
	hint_label.text = original_hint
	await get_tree().process_frame
	await get_tree().process_frame
	check(hint.size.is_equal_approx(original_size), "Hint restores text-sized background")
	var labels := PreviewStage._nodes(app).filter(func(node: Node): return node is Label)
	var brand: Label
	var title: Label
	var hint_count := 0
	for label in labels:
		if label.text == "VFX LAB": brand = label
		if label.text == "3D 特效实验室": title = label
		if label.text.begins_with("右键拖动旋转镜头"): hint_count += 1
		check("真实资源 · 实时参数 · 中文说明" not in label.text, "Old tagline removed")
	check(brand != null and title != null and title.global_position.x > brand.get_global_rect().end.x, "Brand and title share one row")
	check(hint_count == 1, "Only one camera hint")

	var rarities := ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
	for prefix in ["loot_vfx_", "ground_loot_vfx_"]:
		var ids: Array = app.catalog.filter(func(entry: Dictionary): return entry.pack_id == "binbun_loot" and entry.id.get_file().begins_with(prefix)).map(func(entry: Dictionary): return entry.id.get_file())
		check(ids == rarities.map(func(rarity: String): return prefix + rarity), "Loot rarity order " + prefix)

	for entry in app.catalog:
		if not entry.has("ground_model"):
			continue
		app.select_entry(entry)
		for scale in [0.6, 1.0, 2.0]:
			app.stage.set_effect_scale(scale)
			await get_tree().create_timer(0.12).timeout
			var bounds: AABB = app.stage._ground_model_bounds()
			check(bounds.size.y > 0 and absf(bounds.position.y - 0.02) < 0.006, "Ground contact " + entry.id + " at " + str(scale))
		app.stage.set_effect_scale(1.0)
		await get_tree().create_timer(0.15).timeout
		if "Violet" not in entry.id and "Gold" not in entry.id and "Red" not in entry.id:
			await capture(app, entry.id.get_file().replace(" ", "_"))

	for entry in app.catalog:
		if entry.get("preview_origin") == "feet":
			app.select_entry(entry)
			check(app.stage.dummy.visible and app.stage.carrier.position.y < 0.04, "Movement dust at dummy feet")
			await get_tree().create_timer(0.25).timeout
			await capture(app, entry.id.get_file())
		elif entry.get("preview_origin") == "camera_center":
			app.select_entry(entry)
			app.stage.effect.height = 6.0
			app.stage.set_effect_scale(1.6)
			await get_tree().process_frame
			var center: Vector3 = app.stage.effect.to_global(Vector3(0, app.stage.effect.height * 0.5, 0))
			check(center.distance_to(app.stage.focus) < 0.001, "Gust volume centered on camera focus " + entry.id)
			app.stage.set_playing(false)
			app.stage.camera_preset(1)
			await get_tree().process_frame
			center = app.stage.effect.to_global(Vector3(0, app.stage.effect.height * 0.5, 0))
			check(center.distance_to(app.stage.focus) < 0.001, "Paused gust stays at camera focus")
			var rotation := InputEventMouseMotion.new()
			rotation.button_mask = MOUSE_BUTTON_MASK_RIGHT
			rotation.relative = Vector2(50, -20)
			app.stage._camera_input(rotation)
			var zoom := InputEventMouseButton.new()
			zoom.button_index = MOUSE_BUTTON_WHEEL_UP
			zoom.pressed = true
			app.stage._camera_input(zoom)
			await get_tree().process_frame
			center = app.stage.effect.to_global(Vector3(0, app.stage.effect.height * 0.5, 0))
			check(center.distance_to(app.stage.focus) < 0.001, "Paused rotation and zoom preserve gust focus")
			app.stage.set_playing(true)
			if entry.initial.style == "leaves":
				await get_tree().create_timer(0.5).timeout
				await capture(app, "gust")

	app._switch_category("资源 / 授权")
	await get_tree().process_frame
	await get_tree().process_frame
	check(is_equal_approx(app.source_name_filter.size.x, 180.0) and is_equal_approx(app.source_origin_filter.size.x, 180.0), "Fixed search widths")
	var row: Control = app.source_name_filter.get_parent()
	var tools: Control = row.get_child(row.get_child_count() - 1)
	check(tools.global_position.x > app.source_origin_filter.get_global_rect().end.x, "Actions to right of searches")
	check(absf(tools.get_global_rect().end.x - row.get_global_rect().end.x) < 1.0, "Actions right aligned")
	for i in range(1, app.source_cards.get_child_count() - 1):
		var section: Control = app.source_cards.get_child(i)
		if section is Label and section.text.ends_with("项"):
			var previous: Control = app.source_cards.get_child(i - 1)
			var next: Control = app.source_cards.get_child(i + 1)
			var above: float = section.position.y - (previous.position.y + previous.size.y)
			var below: float = next.position.y - (section.position.y + section.size.y)
			check(is_equal_approx(above, below), "Equal section gaps " + section.text)
	for source in app.sources:
		check("按用户要求" not in source.description and "按要求" not in source.description, "Neutral source description " + source.id)
	await capture(app, "sources")
	FileAccess.open("res://artifacts/layout-qa-report.json", FileAccess.WRITE).store_string(JSON.stringify({"failures": failures}, "\t"))
	print("LAYOUT_QA_DONE: ", failures.size(), " failures")
	get_tree().quit(0 if failures.is_empty() else 1)
