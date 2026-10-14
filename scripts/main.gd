extends Control

func _ready() -> void:
	var title := Label.new()
	title.text = "VFX LAB · 3D 特效实验室"
	title.position = Vector2(40, 40)
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)
