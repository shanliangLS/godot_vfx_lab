extends Node3D
## Original collection shaders/nodes on laboratory display objects and viewport overlays.
@export_file("*.gd") var source_script := ""
@export var sampler := ""
@export var variant := ""
var _sample: Node
var _clock := 0.0
var repeat_preview := true

func _ready() -> void:
	var api: Script = load(source_script)
	if sampler in ["psx", "toon"]:
		for i in 3:
			var mesh := MeshInstance3D.new()
			mesh.name = ["Sphere", "Cube", "Torus"][i]
			mesh.mesh = [SphereMesh.new(), BoxMesh.new(), TorusMesh.new()][i]
			mesh.position.x = (i - 1) * 1.8
			mesh.material_override = api.make(variant, null, [Color.CORAL, Color.SKY_BLUE, Color.GOLD][i])
			add_child(mesh)
		return
	var layer := CanvasLayer.new()
	add_child(layer)
	if sampler == "retro":
		_sample = api.new()
		_sample.preset = int(variant)
		add_child(_sample)
	elif sampler == "transition":
		_sample = api.new()
		layer.add_child(_sample)
		_sample.visible = true
		_sample.rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sample.rect.material = api.make_material(variant, {color = Color(0.1, 0.3, 0.6, 1)})
	elif sampler == "sprite":
		var sprite := Sprite2D.new()
		sprite.texture = load("res://icon.svg")
		sprite.position = get_viewport().get_visible_rect().size * 0.5
		sprite.scale = Vector2.ONE * 2.0
		layer.add_child(sprite)
		api.apply(sprite, variant)
		_sample = sprite
	else:
		_sample = api.new()
		_sample.effect = variant
		if "free_when_done" in _sample:
			_sample.free_when_done = false
		layer.add_child(_sample)
		if sampler == "vfx":
			_sample.position = get_viewport().get_visible_rect().size * 0.5
			_sample.scale = Vector2.ONE * 2.0

func _process(delta: float) -> void:
	_clock += delta
	if sampler == "transition" and is_instance_valid(_sample):
		_sample.rect.material.set_shader_parameter("progress", (sin(_clock * 1.8) + 1.0) * 0.5 if repeat_preview else minf(_clock, 1.0))
	elif sampler == "vfx" and repeat_preview and is_instance_valid(_sample) and _clock > 1.5:
		_clock = 0.0
		_sample.play()

func play() -> void:
	_clock = 0.0
	if is_instance_valid(_sample) and _sample.has_method("play"):
		_sample.play()
