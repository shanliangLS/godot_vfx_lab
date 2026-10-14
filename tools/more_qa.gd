extends Node
const PACKS := ["fx_collection_free", "rain_free", "soygus_chest", "storm_free", "glyph_free", "soygus_hologram", "christmas_assets", "brackeys_bundle", "binbun_grass", "soygus_card"]
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error("MORE_QA: " + message)
func run(app: Control) -> void:
	var count := 0
	var photographed := {}
	for entry in app.catalog:
		if entry.pack_id not in PACKS:
			continue
		app.select_entry(entry)
		await get_tree().process_frame
		await get_tree().process_frame
		check(is_instance_valid(app.stage.effect), "Load " + entry.id)
		if not is_instance_valid(app.stage.effect):
			continue
		check(PreviewStage._nodes(app.stage.effect).size() > 1, "Visible carrier " + entry.id)
		check(not app.inspector.all_parameters.is_empty(), "Editable " + entry.id)
		var original: Dictionary = app.inspector.snapshot()
		if entry.pack_id not in ["christmas_assets", "brackeys_bundle"]:
			app._apply_template(2)
			app._apply_template(3)
			app.inspector.restore(original)
			app.stage.replay()
			await get_tree().process_frame
			for parameter in app.inspector.all_parameters:
				if parameter.type in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_COLOR, TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4]:
					check(app.inspector.read(parameter) != null, "Live binding " + entry.id + "/" + parameter.key)
		app.stage.set_playing(false)
		var clock: float = app.stage.elapsed
		await get_tree().process_frame
		check(clock == app.stage.elapsed, "Pause " + entry.id)
		app.stage.set_playing(true)
		var image_key: String = entry.pack_id
		if entry.pack_id == "fx_collection_free":
			image_key += "-" + entry.initial.sampler
		if not photographed.has(image_key) and DisplayServer.get_name() != "headless":
			await get_tree().create_timer(0.4).timeout
			RenderingServer.force_draw()
			app.get_viewport().get_texture().get_image().save_png("res://artifacts/more-" + image_key + ".png")
			photographed[image_key] = true
		count += 1
		print("MORE_EFFECT ", entry.id, " ", app.inspector.all_parameters.size())
	for source in app.sources:
		if source.status == "excluded":
			check(not app.catalog.any(func(entry: Dictionary): return entry.pack_id == source.id), "Excluded resource imported")
	app._show_source("storm_free")
	app.inspector.set_named("radius", 2.3)
	app.inspector.set_named("amount", 42)
	check(app.stage.effect._sparks.amount == 42, "Rebuilt storm particle binding")
	app.stage.repeat_effect = false
	app.stage.effect.duration = 0.1
	app.stage.effect.appear = 0.0
	app.stage.replay()
	await get_tree().create_timer(1.1).timeout
	check(is_instance_valid(app.stage.effect), "Single-shot storm retained its instance")
	app.stage.replay()
	check(app.stage.effect._phase != app.stage.effect.IDLE, "Single-shot storm replay")
	app.stage.repeat_effect = true
	var flipbook: Dictionary = app.catalog.filter(func(entry: Dictionary): return entry.pack_id == "brackeys_bundle" and entry.initial.get("columns", 1) > 1)[0]
	app.select_entry(flipbook)
	app.stage.repeat_effect = false
	check(not app.stage.effect.repeat_preview, "Flipbook follows loop toggle")
	app.stage.effect._clock = 100.0
	app.stage.effect._process(0.0)
	var frame_offset: Vector3 = app.stage.effect._material.uv1_offset
	app.stage.effect._process(1.0)
	check(frame_offset == app.stage.effect._material.uv1_offset, "Single-shot flipbook holds its last frame")
	app.stage.replay()
	check(app.stage.effect._clock == 0.0, "Flipbook replays from its first frame")
	app.stage.repeat_effect = true
	check(app.stage.effect.repeat_preview, "Flipbook loop restored")
	app._switch_category("资源 / 授权")
	app.source_origin_filter.text = "soygus"
	app.source_origin_filter.text_changed.emit("soygus")
	app.source_name_filter.text = "holographic"
	app.source_name_filter.text_changed.emit("holographic")
	var cards := 0
	for child in app.source_cards.get_children():
		if child.has_meta("source_id"):
			cards += 1
			check(child.get_meta("source_id") == "soygus_card", "Combined resource filter")
	check(cards == 1, "Filtered source card count")
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await get_tree().process_frame
		RenderingServer.force_draw()
		app.get_viewport().get_texture().get_image().save_png("res://artifacts/more-source-filter.png")
	var report := {"entries": count, "failures": failures, "screenshots": photographed.keys()}
	FileAccess.open("res://artifacts/more-qa-report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("MORE_QA_DONE: ", count, " entries, ", failures.size(), " failures")
	get_tree().quit(0 if failures.is_empty() else 1)
