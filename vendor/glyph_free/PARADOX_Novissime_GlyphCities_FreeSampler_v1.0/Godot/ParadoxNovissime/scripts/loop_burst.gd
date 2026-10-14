@tool
extends Node3D
## Replays every one-shot particle system under this node on a timer.
## Lights with metadata "peak" (and optional "decay") flash and fade with each burst.
@export var interval := 2.0
@export var autoplay := true
## Click in the Inspector to replay the effect inside the editor.
@export_tool_button("Replay effect", "Play") var replay_button := play
var _t := 0.0

func _ready() -> void:
	if autoplay:
		play()

func _process(delta: float) -> void:
	_t += delta
	for l in find_children("*", "Light3D", true, false):
		if l.has_meta("peak"):
			l.light_energy = float(l.get_meta("peak")) * exp(-_t * float(l.get_meta("decay", 6.0)))
	if autoplay and interval > 0.0 and _t >= interval:
		play()

func play() -> void:
	_t = 0.0
	for p in find_children("*", "GPUParticles3D", true, false):
		p.restart()
