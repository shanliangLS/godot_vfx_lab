extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func click(app: Control, point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	app.get_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	app.get_viewport().push_input(event, true)

func capture(viewport: Viewport, path: String) -> void:
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://artifacts/" + path + ".png")

func run(app: Control) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	await get_tree().process_frame
	await get_tree().process_frame
	app.library_search.grab_focus()
	click(app, app.library_search.get_global_rect().get_center())
	check(app.library_search.has_focus(), "Click inside text field lost focus")
	click(app, app.stats.get_global_rect().get_center())
	check(not app.library_search.has_focus(), "Blank space did not release input focus")
	var spin: SpinBox
	for node in PreviewStage._nodes(app.inspector.list):
		if node is SpinBox:
			spin = node
			break
	check(spin != null, "No numerical parameter editor found")
	if spin:
		spin.get_line_edit().grab_focus()
		click(app, spin.get_global_rect().end - Vector2(5, 8))
		check(spin.get_line_edit().has_focus(), "Spin arrows incorrectly dismissed focus")
		click(app, app.title_label.get_global_rect().get_center())
		check(not spin.get_line_edit().has_focus(), "Numerical field did not release focus")
	for button in app.nav_buttons:
		check(button.get_theme_stylebox("hover_pressed").border_color == LabTheme.ACCENT, "Selected hover border missing")
	check(app.theme.get_stylebox("hover_pressed", "CheckButton").border_color == LabTheme.ACCENT, "Switch selected hover missing")

	app.inspector.search.text = "color"
	app.inspector._render()
	await get_tree().process_frame
	var picker: ColorPickerButton
	for node in PreviewStage._nodes(app.inspector.list):
		if node is ColorPickerButton:
			picker = node
			break
	check(picker != null, "No color editor found")
	if picker:
		picker.pressed.emit()
		picker.get_popup().popup_centered()
		await get_tree().process_frame
		check(not picker.get_popup().transparent_bg, "Color popup viewport transparent")
		check(picker.get_popup().get_theme_stylebox("panel").bg_color.a == 1.0, "Color popup panel transparent")
		await capture(picker.get_popup(), "interaction-color-picker")
		picker.get_popup().hide()

	# Route real mouse events through the application while the simulation is frozen.
	app.stage.set_playing(false)
	var before_camera: Transform3D = app.stage.camera.transform
	var before_time: float = app.stage.elapsed
	var point: Vector2 = app.stage.get_global_rect().get_center()
	var drag := InputEventMouseMotion.new()
	drag.position = point
	drag.relative = Vector2(90, 35)
	drag.button_mask = MOUSE_BUTTON_MASK_RIGHT
	app.get_viewport().push_input(drag, true)
	check(not app.stage.camera.transform.is_equal_approx(before_camera), "Paused right drag did not move camera")
	check(app.stage.viewport.render_target_update_mode == SubViewport.UPDATE_ONCE, "Paused camera did not request a redraw")
	var distance_before: float = app.stage.distance
	var wheel := InputEventMouseButton.new()
	wheel.position = point
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	app.get_viewport().push_input(wheel, true)
	check(app.stage.distance < distance_before, "Paused wheel did not zoom")
	await get_tree().create_timer(0.2, true, false, true).timeout
	check(app.stage.elapsed == before_time, "Camera interaction advanced paused effect")
	await capture(app.get_viewport(), "interaction-paused-camera")
	app.stage.set_playing(true)

	var hit_count := 0
	for entry in app.catalog:
		if entry.mode != "hit":
			continue
		app.select_entry(entry)
		hit_count += 1
		for node in PreviewStage._nodes(app.stage.effect):
			if node is GeometryInstance3D:
				for material in PreviewStage._materials(node):
					if material is ShaderMaterial:
						check("depth_test_disabled" in material.shader.code, "Hit shader still depth tested: " + entry.id)
						check(not material.shader.get_shader_uniform_list().is_empty(), "Hit shader failed to compile: " + entry.id)
					elif material is BaseMaterial3D:
						check(material.no_depth_test, "Hit material still depth tested: " + entry.id)
		await get_tree().create_timer(0.15).timeout
		if hit_count == 1:
			await capture(app.get_viewport(), "interaction-hit-overlay")

	var projectile_count := 0
	for entry in app.catalog:
		if entry.pack_id != "inspired_projectiles":
			continue
		app.select_entry(entry)
		projectile_count += 1
		app.stage.repeat_effect = true
		# Shorten the lifetime for the regression, then actually wait through two cycles.
		app.stage.effect.set("lifetime", 0.6)
		app.stage.repeat_interval = 1.2
		var source: Node3D = app.stage.effect
		source.set("speed", 7.5)
		app.stage.set_effect_scale(1.2)
		await get_tree().create_timer(2.8).timeout
		check(is_instance_valid(source), "Loop destroyed projectile: " + entry.id)
		if not is_instance_valid(source):
			continue
		check(app.stage.projectile_clock < 1.2, "Projectile did not loop: " + entry.id)
		check(source.get("speed") == 7.5 and source.scale.is_equal_approx(Vector3.ONE * 1.2), "Loop lost parameters")
		app.stage.repeat_effect = false
		await get_tree().create_timer(1.4).timeout
		check(is_instance_valid(source), "Finished projectile cannot be replayed")
		check(source.get_node("Emitters").scale.x < 0.01, "Single shot failed to fade")
		app.stage.replay()
		check(source.get("age") == 0.0 and not source.get("collided"), "Replay did not reset lifecycle")
		check(source.get_node("Emitters").scale.is_equal_approx(app.stage.projectile_scales.Emitters), "Replay retained faded scale")
		check(source.get_node("TrailPrefab").points.is_empty(), "Replay retained old trail")
		for emitter in source.get_node("Emitters").get_children():
			check(emitter.emitting and emitter.visible, "Replay did not restart emission")
		for emitter in source.get_node("Impact").get_children():
			check(not emitter.emitting, "Launch spuriously emitted impact")
		await get_tree().create_timer(0.2).timeout
		await capture(app.get_viewport(), "interaction-projectile-" + str(projectile_count))
		app.stage.set_playing(false)
		app.stage.replay()
		check(source.get("age") == 0.0, "Paused replay did not reset projectile")
		app.stage.set_playing(true)
		app.stage.repeat_effect = true
		app.stage.repeat_interval = 2.4
	print("INTERACTION_QA: ", hit_count, " hit scenes, ", projectile_count, " projectile scenes, failures=", failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
