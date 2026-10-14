extends Node3D

@export var alpha_value: float = 0.0:
	set(value):
		alpha_value = value
		$Cube_001.get_active_material(0).set_shader_parameter("alpha", value)
