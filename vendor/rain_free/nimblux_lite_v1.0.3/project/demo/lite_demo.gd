extends Node3D
## NIMBLUX Lite demo: rain over a small village. Drag the slider or press Up/Down to go from
## drizzle to downpour, T changes the time of day. There is no shelter under the bus stop
## roof, so the rain falls through it (NimbluxShelter3D is in the full version).
## The small button in the bottom-right corner opens the full version's itch.io page.
## Command line (after --): --noui, --amount=0.8, --mood=dusk, --cam=low, --sweep, --still

const DemoStage: GDScript = preload("res://vendor/rain_free/nimblux_lite_v1.0.3/project/demo/shared/demo_stage.gd")
const PRESET: String = "res://vendor/rain_free/nimblux_lite_v1.0.3/project/addons/nimblux_fx/presets/3d/rain_steady.tscn"
const MOODS: PackedStringArray = ["overcast", "dusk", "blue_hour", "night"]
const FULL_URL: String = "https://gennai.itch.io/weather-vfx-godot-4"

@onready var stage: DemoStage = $DemoStage
@onready var label: Label = $UI/Info
@onready var slider: HSlider = $UI/Amount
@onready var full_button: Button = $UI/FullVersion

var rain: LabRainFreeNimbluxRain3D
var t: float = 0.0
var mood: int = 1
var low_cam: bool = false
var sweep: bool = false
var still: bool = false


func _ready() -> void:
	rain = (load(PRESET) as PackedScene).instantiate() as LabRainFreeNimbluxRain3D
	add_child(rain)
	for a in OS.get_cmdline_user_args():
		if a == "--noui":
			($UI as CanvasLayer).visible = false
		elif a.begins_with("--amount="):
			rain.amount = clampf(a.substr(9).to_float(), 0.0, 1.0)
		elif a.begins_with("--mood="):
			mood = maxi(MOODS.find(a.substr(7)), 0)
		elif a == "--cam=low":
			low_cam = true
		elif a == "--sweep":
			sweep = true
		elif a == "--still":
			still = true
	slider.focus_mode = Control.FOCUS_NONE
	slider.value = rain.amount
	slider.value_changed.connect(_on_slider)
	full_button.focus_mode = Control.FOCUS_NONE
	full_button.pressed.connect(_on_full_version)
	stage.wetness = 0.9
	_apply_mood()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_UP:
			slider.value = minf(rain.amount + 0.1, 1.0)
		KEY_DOWN:
			slider.value = maxf(rain.amount - 0.1, 0.0)
		KEY_T:
			mood = (mood + 1) % MOODS.size()
			_apply_mood()


func _process(delta: float) -> void:
	t += delta
	var s: float = 0.0 if still else t
	if low_cam:
		stage.set_view(Vector3(0.4 + sin(s * 0.15) * 0.3, 0.75, 7.0 - s * 0.05), Vector3(-0.4, 0.05, 1.5 - s * 0.05))
	else:
		stage.set_view(Vector3(sin(s * 0.1) * 1.5, 1.7, 12.0 - s * 0.15), Vector3(-0.5, 1.5, -s * 0.15))
	if sweep:
		# Drizzle to downpour and back, for the store GIF.
		rain.amount = 0.12 + 0.88 * (0.5 - 0.5 * cos(t * TAU / 8.0))
		slider.set_value_no_signal(rain.amount)
	_update_label()


func _on_slider(value: float) -> void:
	rain.amount = value


func _on_full_version() -> void:
	OS.shell_open(FULL_URL)


func _apply_mood() -> void:
	stage.set_mood(MOODS[mood])


func _update_label() -> void:
	label.text = "NIMBLUX Lite   rain amount %.2f   |   Up/Down or slider  amount   T  time of day (%s)" % [rain.amount, MOODS[mood]]
