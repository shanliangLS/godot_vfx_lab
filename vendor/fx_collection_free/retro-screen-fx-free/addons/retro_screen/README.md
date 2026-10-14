# Retro Screen FX Free

Full-screen CRT, VHS, arcade and film post-processing for Godot 4.3+ (Forward+, Mobile,
Compatibility), over 2D and 3D.

**The full pack:** **[Retro Screen FX](https://heyheythere.itch.io/retro-screen-fx)** adds what this one leaves out:
palettes (twelve included, or any Lospec palette of your own), ordered dithering, colour levels and
the LCD pixel grid, and twenty more presets: Game Boy, PICO-8, NES, C64, PSX and other machines,
Amber and Green Phosphor monitors, Old TV, Security Cam, Night Vision, Broken Tape and more. Same
code: install it over this one.

## Use

Add a **RetroScreen** node to your scene (Add Child Node → RetroScreen) and pick a preset in the
inspector. Or from code:

```gdscript
var retro := RetroScreen.new()
retro.preset = RetroScreen.Preset.CRT
add_child(retro)

retro.preset = RetroScreen.Preset.VHS      # switch any time
retro.set_param(&"noise", 0.6)              # tweak anything on top
```

It covers everything on lower CanvasLayers, including the 3D view. Its layer is 100: put UI on a
higher layer to keep it crisp, or lower to run it through the effect too.

## Presets

None, CRT, Arcade, VHS, Film. `RetroScreen.PRESETS` lists what each one sets. Setting a preset first
resets every parameter.

## Parameters

Each effect is off at its default. The ones a preset doesn't set stay off.

- **pixels:** `pixel_size` (screen pixels per retro pixel)
- **color:** `brightness`, `contrast`, `saturation`, `tint`
- **crt:** `curvature`, `corner_radius`, `scanlines`, `scanline_count`, `mask`, `mask_size`, `glow`,
  `chromatic`, `vignette`
- **vhs:** `jitter`, `color_bleed`, `tracking`, `noise`
- **compare:** `split` leaves the left part untouched, for before/after shots

## Without the node

`retro_screen.gdshader` works on any ColorRect, even one smaller than the screen.
`RetroScreen.make_material(preset)` builds a material for that.


## More

[Retro Screen FX](https://heyheythere.itch.io/retro-screen-fx) adds palettes (twelve, or any of your
own), ordered dithering, colour levels, the LCD pixel grid and twenty more presets: Game Boy,
PICO-8, CGA, 1-bit, NES, C64, ZX Spectrum, EGA, Virtual Boy, Teletext, PSX, LCD, Amber and Green
Phosphor monitors, Posterize, Old TV, Security Cam, Night Vision, Broken Tape and Sepia.
