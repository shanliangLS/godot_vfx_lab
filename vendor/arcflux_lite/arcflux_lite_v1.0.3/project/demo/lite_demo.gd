extends Node3D
## ARCFLUX Lite demo: a repeating bolt and a sweeping laser. Click to strike the floor.
## The full version adds 10 more 3D effects, 5 2D effects and 33 presets.
## The corner button (UI/FullVersion/Button) opens the Full page in the browser. Only the
## button takes clicks; the container and the URL line ignore the mouse, so floor clicks
## anywhere else still strike.

const PRESETS: String = "res://vendor/arcflux_lite/arcflux_lite_v1.0.3/project/addons/arcflux_fx/presets/3d/"
const FULL_URL: String = "https://gennai.itch.io/arcflux-lightning-beam-vfx"

@onready var stage: Node3D = $DemoStage
@onready var full_button: Button = $UI/FullVersion/Button
var bolt: LabArcfluxLiteArcfluxBolt3D
var laser: LabArcfluxLiteArcfluxLaser3D
var t: float = 0.0
var timer: float = 0.0


func _ready() -> void:
	full_button.pressed.connect(func() -> void: OS.shell_open(FULL_URL))
	stage.set_view(Vector3(0.0, 3.4, 11.0), Vector3(0.0, 2.2, 0.0))
	bolt = (load(PRESETS + "bolt_blue.tscn") as PackedScene).instantiate() as LabArcfluxLiteArcfluxBolt3D
	bolt.autoplay = false
	bolt.position = Vector3(-2.0, 7.0, -1.5)
	add_child(bolt)
	var body: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.6, 3.0, 5.0)
	col.shape = box
	body.add_child(col)
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.17, 0.2)
	mi.material_override = mat
	body.add_child(mi)
	body.position = Vector3(5.0, 1.5, 0.0)
	add_child(body)
	laser = (load(PRESETS + "laser_red.tscn") as PackedScene).instantiate() as LabArcfluxLiteArcfluxLaser3D
	laser.position = Vector3(-4.5, 1.2, 1.0)
	laser.rotation.y = deg_to_rad(-90.0)
	add_child(laser)


func _unhandled_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var cam: Camera3D = get_viewport().get_camera_3d()
		var from: Vector3 = cam.project_ray_origin(mb.position)
		var dir: Vector3 = cam.project_ray_normal(mb.position)
		if dir.y < -0.001:
			bolt.strike(bolt.global_position, from + dir * (-from.y / dir.y))


func _process(delta: float) -> void:
	t += delta
	timer -= delta
	if timer <= 0.0:
		timer = 1.4
		bolt.strike(bolt.global_position, Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-1.0, 1.5)))
	laser.rotation.y = deg_to_rad(-90.0) + sin(t * 0.9) * 0.2
