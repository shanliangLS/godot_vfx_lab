# Sprite FX

Drop-in canvas_item shaders for 2D sprites, for Godot 4.3+ (Forward+, Mobile, Compatibility).

**The full pack:** **[Sprite FX](https://heyheythere.itch.io/sprite-fx)** has all 40: glow outline, burn, hologram, freeze,
electric, fire aura, teleport, disintegrate, cracks, afterimage, palette swap, cooldown and 22 more
on top of these six. Same helper, same code: install it over this one.

## Use from the inspector

Sprite2D (or any CanvasItem) → Material → New ShaderMaterial → Shader → load one from
`addons/sprite_fx/shaders/`. Every parameter shows under Shader Parameters.

## Use from code

```gdscript
SpriteFX.flash($Player, Color.WHITE, 0.15)
SpriteFX.blink($Player, 1.0)
await SpriteFX.dissolve_out($Enemy).finished
SpriteFX.burn_out($Letter, 1.5, Vector2(0.5, 1.0))
SpriteFX.apply($Chest, &"outline", {outline_color = Color.GOLD, width = 1.0})
SpriteFX.clear($Chest)
SpriteFX.animate($Boss, &"pulse_tint", &"max_amount", 0.0, 0.8, 0.5)
SpriteFX.shake($Crate, 0.3, 2.0)
await SpriteFX.teleport_out($Player).finished
SpriteFX.cooldown($FireballIcon, 4.0)
```

Effect names are the shader file names; `SpriteFX.effects()` lists them. `apply` keeps the node's
own material and `clear` (or the end of a one-shot effect) puts it back.

## Notes

- Outlines, glows, drop shadows, electric arcs, fire auras, motion blur, afterimages and disintegrate's
  dust draw into transparent space around the sprite. Give sprites padding, or set `grow` on
  single-texture sprites. Don't use `grow` with atlas regions or sprite-sheet frames.
- `cloak` reads the screen behind the sprite, so it shows nothing over an empty background.
- `glow_outline`, `electric`, `fire_aura`, `teleport` and the `dissolve` and `burn` edges go above
  1.0 brightness. With 2D HDR and a glow WorldEnvironment they bloom.
