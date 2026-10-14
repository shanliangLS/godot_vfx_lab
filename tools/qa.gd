extends Node

var failures: Array[String] = []
var report: Array[Dictionary] = []
var screenshots: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("QA: " + message)

func run(app: Control) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var photographed := {}
	for entry in app.catalog:
		app.select_entry(entry)
		await get_tree().process_frame
		await get_tree().process_frame
		check(is_instance_valid(app.stage.effect), "Instantiate " + entry.id)
		if not is_instance_valid(app.stage.effect): continue
		var before: Dictionary = app.inspector.snapshot()
		check(not app.inspector.all_parameters.is_empty(), "Parameters " + entry.id)
		app._apply_template(2)
		await get_tree().process_frame
		check(is_equal_approx(app.scale_control.value, 0.95), "Preset scale " + entry.id)
		app.inspector.restore(before)
		app.stage.set_playing(false)
		var time: float = app.stage.elapsed
		await get_tree().process_frame
		check(is_equal_approx(app.stage.elapsed, time), "Pause " + entry.id)
		app.stage.set_playing(true)
		app._apply_template(3)
		app.stage.replay()
		app.inspector.search.text = "颜色"
		check(app.inspector.count_label.text.contains("当前"), "Search " + entry.id)
		app.inspector.search.text = ""
		for group_index in app.inspector.groups.size():
			app.inspector.selected = group_index
			app.inspector._render()
		app.inspector.selected = 0
		app.inspector._render()
		var record: Dictionary = app._preset_record()
		var restored: Variant = JSON.parse_string(JSON.stringify(record))
		check(restored is Dictionary and restored.parameters.size() > 0, "Serialize " + entry.id)
		app._restore_record(restored)
		if not photographed.has(entry.category) and DisplayServer.get_name() != "headless":
			app._switch_category(entry.category)
			app.select_entry(entry)
			app._apply_template(3)
			await get_tree().create_timer(0.35).timeout
			await RenderingServer.frame_post_draw
			var path: String = "res://artifacts/" + entry.pack_id + ".png"
			var image: Image = app.get_viewport().get_texture().get_image()
			check(image.save_png(path) == OK, "Screenshot " + entry.id)
			photographed[entry.category] = true
			screenshots.append(path)
		report.append({"id": entry.id, "parameters": app.inspector.all_parameters.size(), "groups": app.inspector.groups.size()})
		print("QA_EFFECT ", entry.id, " ", app.inspector.all_parameters.size(), " params")
	app._switch_category("资源 / 授权")
	await get_tree().process_frame
	check(app.source_panel.visible and not app.workspace.visible, "Source page navigation")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		app.get_viewport().get_texture().get_image().save_png("res://artifacts/sources.png")
	var file := FileAccess.open("res://artifacts/qa_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"effects": report, "failures": failures, "screenshots": screenshots, "engine": Engine.get_version_info(), "renderer": RenderingServer.get_current_rendering_method()}, "\t"))
	print("QA_DONE: ", report.size(), " effects, ", failures.size(), " failures")
	get_tree().quit(0 if failures.is_empty() else 1)
