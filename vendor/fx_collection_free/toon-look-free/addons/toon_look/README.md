# Toon Look

Cel shading for Godot 4.3+ (Forward+, Mobile, Compatibility).

**The full pack:** **[Toon Look](https://heyheythere.itch.io/toon-look)** adds comic halftone and pencil hatching,
nine presets (Anime, Cartoon, Comic, Sketch, Engraving, Noir and more, each a whole look in one
line), six light ramps, and four more materials: cutout for grass and leaves swaying in the wind,
transparent for glass, toon water with waves and drifting foam, and the patterned two. Same code:
install it over this one.

## Use

```gdscript
Toon.convert(level)                 # StandardMaterial3Ds become toon materials, outlined
```

or `mesh.material_override = Toon.make(&"cel", texture, color)` for one.

## Presets

```gdscript
ToonPreset.named(&"comic").apply(level, world_env.environment)
```

sets the toon materials already under `level` (shading, rim, outline) and the Environment's
saturation and tint in one go. `ToonPreset.PRESETS` holds the nine: `anime`, `cartoon`, `soft`,
`storybook`, `pastel`, `comic` (halftone), `sketch` and `engraving` (hatching) and `noir`. A preset
is a Resource: save your own as a `.tres`. Each material keeps its own highlight.

## Materials

`Toon.make(kind, texture, color, outline)`: `kind` is `cel`, `hatch`, `halftone`, `cutout`,
`transparent` or `water`, each a `shaders/toon_<kind>.gdshader` you can also put on a
ShaderMaterial yourself. The solid three (`Toon.SOLID`) get `shaders/toon_outline.gdshader` as
their next pass. `Toon.convert(root)` maps alpha scissor to cutout and alpha to transparent, leaves
unshaded and additive materials as they are, and returns how many materials it made.
`Toon.set_param(root, name, value)` sets a parameter on every toon material under `root` and its
outline; `Toon.restyle(root, kind)` turns the solid ones to another solid kind, keeping their
settings.

Parameters on every kind: `albedo`, `albedo_texture`, `uv_scale`, `uv_offset`, `vertex_colors`,
`shadow_color` (the shade, in place of the Environment's ambient light), `bands`, `band_softness`,
`band_threshold`, `ramp` with `use_ramp` (a texture read from shade to light, in place of the
bands; `ramps/` has six), `specular`, `glossiness`, `rim`, `rim_color`, `rim_width`, `emission`,
and a wave along the normals (`wave_height`, `wave_length`, `wave_speed`, `wave_pinned`: 1 holds
the texture's top edge still, 2 its foot). Hatch and halftone add `pattern_size` and
`pattern_angle`, cutout `alpha_cut`, water `foam_color`, `foam`, `foam_width`, `foam_scale` and
`flow`. The outline: `outline_color`, `outline_width` (pixels of a 1080-line screen) and
`outline_smooth` (1 for hard-edged meshes such as boxes, whose split normals open the line at the
corners).

Each light is cut to a crisp edge: the sun's shadows fall hard, and an omni or spot light lights
a pool nearly as wide as its range. A rim catches large flat floors where they run out to the
horizon: give those `rim` 0.
