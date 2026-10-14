@tool
extends MeshInstance3D
## Procedural lightning bolt: a jagged main channel plus branches, re-rolled while striking.
@export var end_point := Vector3(0, -3, 0)
@export var segments := 16
@export var jitter := 0.3
@export var width := 0.05
@export var branches := 2
@export var strike_on := 0.22
@export var strike_off_min := 0.4
@export var strike_off_max := 1.4
@export var light_path: NodePath = ^"../Flash"
## Nodes shown only while the bolt is striking (ground glow, arcs).
@export var strike_nodes: Array[NodePath] = [^"../GroundGlow", ^"../GroundArcs"]
var _im := ImmediateMesh.new()
var _t := 0.0
var _rebuild_t := 0.0
var _on := true
var _next := 0.2
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	mesh = _im
	_build()

func _process(delta: float) -> void:
	_t += delta
	_rebuild_t += delta
	if _t >= _next:
		_t = 0.0
		_on = not _on
		_next = strike_on if _on else _rng.randf_range(strike_off_min, strike_off_max)
	visible = _on
	for np in strike_nodes:
		var n := get_node_or_null(np) as Node3D
		if n:
			n.visible = _on
	if _on and _rebuild_t > 0.05:
		_rebuild_t = 0.0
		_build()
	var l := get_node_or_null(light_path) as Light3D
	if l:
		l.light_energy = _rng.randf_range(4.0, 10.0) if _on else 0.0

func _bolt(a: Vector3, b: Vector3, n: int, j: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var dir := b - a
	var side1 := dir.cross(Vector3.FORWARD).normalized()
	var side2 := dir.cross(side1).normalized()
	for i in n + 1:
		var f := float(i) / n
		var p := a + dir * f
		if i > 0 and i < n:
			p += (side1 * _rng.randf_range(-1, 1) + side2 * _rng.randf_range(-1, 1)) * j * sin(f * PI)
		pts.append(p)
	return pts

func _ribbon(pts: PackedVector3Array, w: float) -> void:
	for axis in [Vector3.RIGHT, Vector3.BACK]:
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var o: Vector3 = axis * w * (1.0 - float(i) / pts.size() * 0.5)
			_im.surface_add_vertex(a - o); _im.surface_add_vertex(a + o); _im.surface_add_vertex(b + o)
			_im.surface_add_vertex(a - o); _im.surface_add_vertex(b + o); _im.surface_add_vertex(b - o)

func _build() -> void:
	_im.clear_surfaces()
	var main := _bolt(Vector3.ZERO, end_point, segments, jitter)
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_ribbon(main, width)
	for k in branches:
		var s := main[_rng.randi_range(3, segments - 5)]
		var e := s + Vector3(_rng.randf_range(-1, 1), -_rng.randf_range(0.4, 1.0), _rng.randf_range(-1, 1)) * end_point.length() * 0.3
		_ribbon(_bolt(s, e, 6, jitter * 0.5), width * 0.5)
	_im.surface_end()
