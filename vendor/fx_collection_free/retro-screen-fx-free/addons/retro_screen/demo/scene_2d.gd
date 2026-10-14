extends Control
## A pixel-art 2D scene to show the effects on: hills, drifting clouds, a hopping slime.

const ART := "res://vendor/fx_collection_free/retro-screen-fx-free/addons/retro_screen/demo/art/%s.png"

var slime: TextureRect
var clouds: Array[Vector2] = [Vector2(0.1, 0.12), Vector2(0.45, 0.2), Vector2(0.75, 0.1)]
var t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var size := get_viewport_rect().size
	for p in [["bush", 0.14], ["mushroom", 0.33], ["slime", 0.55], ["chest", 0.72], ["coin", 0.88]]:
		var s := TextureRect.new()
		s.texture = load(ART % p[0])
		s.size = s.texture.get_size() * 5.0
		s.position = Vector2(size.x * p[1], size.y * 0.72) - Vector2(s.size.x * 0.5, s.size.y)
		add_child(s)
		if p[0] == "slime":
			slime = s


func _process(delta: float) -> void:
	t += delta
	var size := get_viewport_rect().size
	slime.position.y = size.y * 0.72 - slime.size.y - absf(sin(t * 3.0)) * size.y * 0.12
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	var ground := size.y * 0.72
	for y in int(ground):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.35, 0.6, 0.95).lerp(Color(0.95, 0.85, 0.75), y / ground))
	draw_circle(Vector2(size.x * 0.8, size.y * 0.2), size.y * 0.09, Color(1.0, 0.9, 0.55))
	for c in clouds:
		var x := fposmod(c.x * size.x + t * 30.0, size.x + 300.0) - 150.0
		for k in 3:
			draw_circle(Vector2(x + k * 40.0, c.y * size.y + (k % 2) * -14.0), 34.0, Color(1, 1, 1, 0.9))
	for i in 3:
		var hill := PackedVector2Array()
		var base := size.y * (0.55 + i * 0.06)
		for x in range(0, int(size.x) + 41, 40):
			hill.append(Vector2(x, base - sin(x * 0.005 + i * 2.0) * size.y * 0.07))
		hill.append(Vector2(size.x + 40, size.y))
		hill.append(Vector2(0, size.y))
		draw_colored_polygon(hill, Color(0.35, 0.65, 0.4).darkened(0.15 * i))
	draw_rect(Rect2(0, ground, size.x, size.y - ground), Color(0.45, 0.32, 0.25))
	draw_rect(Rect2(0, ground, size.x, 10), Color(0.4, 0.75, 0.35))
