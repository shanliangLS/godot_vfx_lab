# Scene Transitions Free

8 full-screen transitions for Godot 4.3+ (Forward+, Mobile, Compatibility). No autoload or plugin to
set up: `SceneTransition` adds its own CanvasLayer the first time you use it.

**The full pack:** **[Scene Transitions](https://heyheythere.itch.io/scene-transitions)** has all 48: clock, spiral,
hexagons, rays and 15 more patterns, 9 screen effects that bend the game image (pixelate, swirl,
melt, tv and 5 more) and 12 more rule masks, heart, moon and flames among them. Same code: install
it over this one.

## Change scenes

```gdscript
SceneTransition.change_scene("res://level_2.tscn")                     # fade through black
SceneTransition.change_scene("res://level_2.tscn", &"diamonds")
SceneTransition.change_scene(packed_scene, &"iris", {center = $Player, duration = 0.6})
await SceneTransition.change_scene("res://menu.tscn", &"circles")      # resumes once revealed
```

A path loads on a background thread while the screen covers.

## Cover, do something, reveal

```gdscript
await SceneTransition.cover(&"clouds", {color = Color.WHITE})
$Player.global_position = spawn_point
await SceneTransition.reveal(&"clouds")
```

## Styles

`SceneTransition.styles()` lists them all.

- Patterns: fade, dither, wipe, diamonds, circles, iris
- Rule masks: clouds, spots

Any greyscale `Texture2D` is a style too: black covers first, white last.

```gdscript
SceneTransition.cover(preload("res://my_rule.png"))
```

## Options

| option | for | |
|---|---|---|
| `duration` | all | seconds per half, default 0.45 |
| `color` | all | default black |
| `ease`, `trans` | all | Tween easing, default EASE_IN_OUT / TRANS_SINE |
| `reveal_style` | change_scene | reveal with a different style |
| `center` | iris | UV (0..1), or a 2D or 3D node to close on |
| `angle` | wipe and other directional patterns | degrees, 0 = left to right |
| `cells` | grid patterns | cells across the screen height |
| `softness` | patterns and masks | edge blur, 0..0.5 |
| `flip` | patterns and masks | run the pattern backwards, e.g. iris opens |
| `pixel_size` | patterns and masks | chunky edges for pixel-art games, in screen pixels |

Any other key is passed to the shader as a uniform.

## Without code

Put a ColorRect over your scene, give it a ShaderMaterial with `transition.gdshader`, pick `style`,
and animate `progress` from 0 to 1 in an AnimationPlayer.
`SceneTransition.make_material(style, options)` builds the same material from code.

## Notes

- The layer is 128. CanvasLayers above 128 stay on top of the transition.
- It keeps running while the tree is paused, and blocks mouse input while visible.
- Starting a transition while one plays replaces it.
