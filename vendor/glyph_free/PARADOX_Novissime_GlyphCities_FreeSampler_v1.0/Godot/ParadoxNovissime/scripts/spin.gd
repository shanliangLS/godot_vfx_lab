@tool
extends Node3D
## Slow rotation with a gentle hover.
@export var speed := Vector3(0, 0.6, 0)
@export var bob := 0.05
var _t := 0.0
var _y0 := 0.0

func _ready() -> void:
	_y0 = position.y

func _process(delta: float) -> void:
	_t += delta
	rotation += speed * delta
	position.y = _y0 + sin(_t * 1.5) * bob
