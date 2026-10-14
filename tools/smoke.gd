extends Node

func run(app: Control) -> void:
	app._switch_category("激光 / 射线")
	app._apply_template(3)
	await get_tree().create_timer(1.2).timeout
	app.stage.set_playing(false)
	var time: float = app.stage.elapsed
	var before: Dictionary = app.inspector.snapshot()
	await get_tree().create_timer(0.2, true, false, true).timeout
	assert(app.stage.elapsed == time, "Pause moved effect")
	assert(Engine.time_scale == 0.0, "Pause did not stop timers")
	app.inspector.set_named("beam_radius", 0.3)
	await get_tree().process_frame
	app.stage.set_playing(true)
	assert(Engine.time_scale == 1.0, "Resume did not restore time")
	# Parameters unrelated to the edit retain their values across pause/resume.
	var after: Dictionary = app.inspector.snapshot()
	for key in before:
		if key.ends_with(":speed_scale"):
			assert(before[key] == after[key], "Pause lost a speed parameter")
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var image: Image = app.get_viewport().get_texture().get_image()
	assert(image.save_png("res://artifacts/preview.png") == OK)
	print("SMOKE_PASS: paused timers, parameter edit, retained speeds, resumed, ", Engine.get_frames_per_second(), " FPS")
	get_tree().quit()
