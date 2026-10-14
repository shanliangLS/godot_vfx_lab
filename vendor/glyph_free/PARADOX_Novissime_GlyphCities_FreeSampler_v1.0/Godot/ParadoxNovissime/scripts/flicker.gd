extends OmniLight3D
## Organic fire-light flicker.
@export var amount := 0.3
@export var speed := 9.0
var _base := 0.0
var _t := 0.0
var _noise := FastNoiseLite.new()

func _ready() -> void:
	_base = light_energy
	_noise.frequency = 0.8

func _process(delta: float) -> void:
	_t += delta * speed
	light_energy = _base * (1.0 + amount * _noise.get_noise_1d(_t))
