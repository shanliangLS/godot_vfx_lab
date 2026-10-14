extends Node

const PACKS := ["binbun_electric", "binbun_loot", "binbun_status", "binbun_elemental", "binbun_dark", "berry_hit_free", "soygus_tornado", "starter_lite", "magic_circles_free", "arcflux_lite", "soygus_shield"]
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error("REQUESTED_QA: " + message)

func image_of(app: Control, name: String) -> void:
	await RenderingServer.frame_post_draw
	app.get_viewport().get_texture().get_image().save_png("res://artifacts/requested-" + name + ".png")

func run(app: Control) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var seen := {}
	var count := 0
	for entry in app.catalog:
		if entry.pack_id not in PACKS:
			continue
		app.select_entry(entry)
		await get_tree().process_frame
		await get_tree().process_frame
		check(is_instance_valid(app.stage.effect), "Load " + entry.id)
		check(not app.inspector.all_parameters.is_empty(), "Editable parameters " + entry.id)
		var original: Dictionary = app.inspector.snapshot()
		app._apply_template(2)
		app._apply_template(3)
		app.inspector.restore(original)
		app.stage.replay()
		await get_tree().process_frame
		await get_tree().process_frame
		app.stage.set_playing(false)
		var clock: float = app.stage.elapsed
		var snapshot: Dictionary = app.inspector.snapshot()
		await get_tree().process_frame
		check(clock == app.stage.elapsed, "Pause " + entry.id)
		app.stage.set_playing(true)
		check(snapshot == app.inspector.snapshot(), "Pause preserved values " + entry.id)
		for index in app.inspector.groups.size():
			app.inspector.selected = index
			app.inspector._render()
		for parameter in app.inspector.all_parameters:
			if parameter.type in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_COLOR, TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4]:
				check(app.inspector.read(parameter) != null, "Stale editor binding " + parameter.id + " in " + entry.id)
		app.inspector.selected = 0
		app.inspector._render()
		await get_tree().create_timer(0.35).timeout
		if not seen.has(entry.pack_id):
			await image_of(app, entry.pack_id)
			app._show_source(entry.pack_id)
			check(app.current.pack_id == entry.pack_id, "Source card selected a different pack")
			seen[entry.pack_id] = true
		count += 1
		print("REQUESTED_EFFECT ", entry.id, " ", app.inspector.all_parameters.size(), " parameters")
	check(count == 55 and seen.size() == 11, "Requested entries / pack count")
	for source in app.sources:
		if source.status == "excluded":
			check(not app.catalog.any(func(entry: Dictionary): return entry.pack_id == source.id), "Excluded Unity asset was imported")

	# Persistent preset editors must rebuild live visuals without destroying resource bindings.
	app._show_source("berry_hit_free")
	var fx: Node3D = app.stage.effect
	check(app.inspector.groups.any(func(group: Dictionary): return "纹理层" in group.name), "Hit layer resources not editable")
	app.inspector.set_named("color_main", Color("42d4ff"))
	check(fx.preset.color_main.is_equal_approx(Color("42d4ff")), "Live hit preset edit")
	check(not fx._bursts.is_empty(), "Hit preset did not rebuild its visible layers")
	var layer: Dictionary = fx._bursts[0]
	check("depth_test_disabled" in layer.mat.shader.code, "Rebuilt hit lost overlay rendering")
	var original_scene: PackedScene = load(app.current.path)
	var isolated: Node3D = original_scene.instantiate()
	check(not isolated.preset.color_main.is_equal_approx(Color("42d4ff")), "Preset edit leaked into cached author resource")
	isolated.free()
	app.stage.repeat_effect = false
	await get_tree().create_timer(1.8).timeout
	check(is_instance_valid(fx) and not fx._playing, "Hit single shot did not finish safely")
	app.stage.replay()
	check(fx._playing, "Finished hit could not replay")
	await image_of(app, "hit-live-edit")
	app.stage.repeat_effect = true

	app._show_source("magic_circles_free")
	fx = app.stage.effect
	app.inspector.set_named("radius", 2.0)
	await get_tree().process_frame
	check(fx.radius == 2.0, "Circle radius edit")
	app.inspector.set_named("amount", 30)
	check(fx._sparks.amount == 30, "Particle editor did not resolve rebuilt node")
	app.inspector.set_named("sides", 5.0)
	check(fx.get_param("sides") == 5.0, "Shader editor did not use persistent overrides")
	app.stage.repeat_effect = false
	await get_tree().create_timer(3.0).timeout
	check(is_instance_valid(fx), "Single-shot circle deleted inspector binding")
	app.stage.replay()
	check(fx.strength() >= 0.0, "Circle replay")
	app.stage.repeat_effect = true

	app._show_source("arcflux_lite")
	fx = app.stage.effect
	var first_age: float = fx._age
	await get_tree().create_timer(3.0).timeout
	check(fx._age != first_age, "Bolt loop never advanced")
	app.stage.repeat_effect = false
	await get_tree().create_timer(1.8).timeout
	check(not fx.is_active(), "Bolt stopped looping")
	app.stage.replay()
	check(fx.is_active(), "Bolt did not replay")
	app.stage.repeat_effect = true

	app._switch_category("资源 / 授权")
	await image_of(app, "sources")
	print("REQUESTED_QA_DONE: ", count, " new effects, ", seen.size(), " packs, ", failures.size(), " failures")
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
