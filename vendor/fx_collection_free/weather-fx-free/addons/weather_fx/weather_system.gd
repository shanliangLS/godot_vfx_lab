@tool
class_name LabFxCollectionFreeWeatherSystem
extends Node2D
## Weather as states: one call changes it, the effects that go fading out as the new ones fade in.
##
##     $Weather.change("storm", 6.0)                          # over 6 seconds
##     $Weather.weather = "snow"                              # over `fade`
##     $Weather.forecast = {clear = 3, cloudy = 2, rain = 1}  # changes on its own, by weight
##     $Weather.get_effect("lightning").strike()
##
## A state is LabFxCollectionFreeWeatherFX effects with their options (STATES). An effect the next state has too, with
## the same options, stays as it is.

signal weather_changed(state: String)

## Each state's effects and their options. Its first is its lead: the state is offered (states())
## when that one is installed, and brings whichever of the others are.
const STATES := {
	"clear": {},
	"cloudy": {"clouds": {coverage = 0.55}, "cloud_shadows": {coverage = 0.35}},
	"drizzle": {"rain": {density = 0.3, drop_length = 14.0, fall_speed = 0.8, splashes = 0.4},
		"clouds": {coverage = 0.8, color = Color(0.85, 0.87, 0.9), shade = Color(0.56, 0.6, 0.68)},
		"mist": {density = 0.35}},
	"rain": {"rain": {density = 0.55}, "storm_clouds": {cover = 0.3, flashes = 0.0}},
	"storm": {"storm_clouds": {cover = 0.4, flashes = 0.5},
		"rain": {density = 0.8, wind = 0.45, drop_length = 34.0, fall_speed = 1.3},
		"lightning": {frequency = 0.3}},
	"hail": {"hail": {density = 0.5}, "storm_clouds": {cover = 0.35, flashes = 0.15}},
	"snow": {"snow": {density = 0.45},
		"clouds": {coverage = 0.75, color = Color(0.92, 0.93, 0.96), shade = Color(0.7, 0.74, 0.84)}},
	"blizzard": {"blizzard": {}, "fog": {density = 0.3}},
	"fog": {"fog": {density = 0.55}, "mist": {density = 0.5}},
	"windy": {"wind": {density = 0.5}, "leaves": {density = 0.25, wind = 0.9}, "clouds": {coverage = 0.35, wind = 1.2}},
	"sandstorm": {"sandstorm": {}, "wind": {density = 0.35, color = Color(1.0, 0.9, 0.7, 0.5)}},
	"heatwave": {"heat_haze": {}, "sun": {}},
	"ashfall": {"ash": {}, "embers": {density = 0.3}},
}
## The effects that take `ground`.
const GROUNDED := ["rain", "hail", "lightning", "tornado"]

@export_enum("clear", "cloudy", "drizzle", "rain", "storm", "hail", "snow", "blizzard", "fog", "windy",
		"sandstorm", "heatwave", "ashfall")
var weather := "clear":
	set(v):
		if v not in STATES:
			push_error("LabFxCollectionFreeWeatherSystem: no state %s, pick one of %s" % [v, states()])
			return
		weather = v
		_apply(fade if _seconds < 0.0 else _seconds)
		_seconds = -1.0
## Seconds a change takes when not given.
@export var fade := 4.0
## Where rain splashes, hail bounces, lightning strikes and a tornado touches down: 0..1 down the
## view, 1 its bottom.
@export_range(0.0, 1.0) var ground := 1.0:
	set(v):
		ground = v
		for e in _shown:
			if e in GROUNDED:
				_shown[e].set_param(&"ground", v)
## Random weather: each state's weight. Empty holds the weather.
@export var forecast := {}:
	set(v):
		forecast = v
		_next = randf_range(change_every.x, change_every.y)
## Seconds between the forecast's changes, at random from x to y.
@export var change_every := Vector2(60, 180):
	set(v):
		change_every = v
		_next = randf_range(v.x, v.y)

var _shown := {}    # effect: its LabFxCollectionFreeWeatherFX
var _options := {}  # effect: the options it was added with
var _seconds := -1.0
var _next := randf_range(60, 180)


## The states whose lead effect is installed, and clear.
static func states() -> PackedStringArray:
	var have := LabFxCollectionFreeWeatherFX.effects()
	return PackedStringArray(STATES.keys().filter(func(s: String) -> bool:
		return STATES[s].is_empty() or STATES[s].keys()[0] in have))


## Changes the weather over `seconds` (-1: `fade`).
func change(state: String, seconds := -1.0) -> void:
	_seconds = seconds
	weather = state


## The state's LabFxCollectionFreeWeatherFX for `effect`, or null.
func get_effect(effect: String) -> LabFxCollectionFreeWeatherFX:
	return _shown.get(effect)


func _ready() -> void:
	_apply(0.0)


func _process(delta: float) -> void:
	if forecast.is_empty() or Engine.is_editor_hint():
		return
	_next -= delta
	if _next > 0.0:
		return
	_next = randf_range(change_every.x, change_every.y)
	var offered := states()
	var total := 0.0
	for s in forecast:
		total += forecast[s] if s in offered else 0.0
	var pick := randf() * total
	for s in forecast:
		if s in offered:
			pick -= forecast[s]
			if pick < 0.0:
				if s != weather:
					change(s)
				return


func _apply(seconds: float) -> void:
	if not is_inside_tree():
		return
	if Engine.is_editor_hint():
		seconds = 0.0
	var want: Dictionary = STATES[weather]
	for e in _shown.keys():
		if e not in want or want[e] != _options[e]:
			_shown[e].stop(seconds)
			_shown.erase(e)
			_options.erase(e)
	var have := LabFxCollectionFreeWeatherFX.effects()
	for e in want:
		if e in _shown or e not in have:
			continue
		var options: Dictionary = want[e].duplicate()
		if e in GROUNDED:
			options.ground = ground
		_shown[e] = LabFxCollectionFreeWeatherFX.add(self, e, options).fade_in(seconds)
		_options[e] = want[e]
	# LabFxCollectionFreeWeatherFX.EFFECTS' drawing order, the ones fading out among them
	var order := LabFxCollectionFreeWeatherFX.EFFECTS.keys()
	var fx := get_children().filter(func(n: Node) -> bool: return n is LabFxCollectionFreeWeatherFX)
	fx.sort_custom(func(a: LabFxCollectionFreeWeatherFX, b: LabFxCollectionFreeWeatherFX) -> bool: return order.find(a.effect) < order.find(b.effect))
	for i in fx.size():
		move_child(fx[i], i)
	weather_changed.emit(weather)
