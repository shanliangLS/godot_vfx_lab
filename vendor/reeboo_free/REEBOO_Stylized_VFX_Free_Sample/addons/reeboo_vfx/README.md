# REEBOO Stylized VFX for Godot 4 - Free Sample

This free sample holds 3 of the 25 effects: `hit_spark`, `slash` and `pickup_sparkle`.
The full pack is here: https://reebo0.itch.io/stylized-vfx-godot

25 stylized effects made from shaders and GPU particles. There are no sprite sheets or baked
textures: every color, size and timing is a setting you can change in the Inspector.

**Requirements:** Godot 4.4 or newer (tested on 4.4.1 and 4.7.2), Forward+ or Mobile renderer.

## Quick start

1. Copy the `addons/reeboo_vfx` folder into your project.
2. Drag any scene from `addons/reeboo_vfx/effects/` into your level, or spawn one from code:

```gdscript
const EXPLOSION := preload("res://addons/reeboo_vfx/effects/explosion.tscn")

func _on_rocket_hit(hit_position: Vector3) -> void:
	VFXEffect.spawn(EXPLOSION, get_tree().current_scene, hit_position)
```

One-shot effects delete themselves when they finish. Looping effects keep running until you
call `stop()` or free them.

3. Turn on glow. Add a `WorldEnvironment` with **Glow** enabled. The demo uses intensity 0.7,
   HDR threshold 1.0, blend mode Screen and glow levels 2 to 5. The effects work without glow,
   but glow is what makes them shine.

To browse everything, open this project in Godot and press F5. Use Left/Right to switch
effects, Space to replay and A to toggle auto-advance.

## The effects (full pack; this sample has hit_spark, slash and pickup_sparkle)

| Scene | Type | Notes |
|---|---|---|
| `explosion` | one-shot | Flash, fireballs, smoke, sparks, embers, ground shockwave, light |
| `fire_impact` | one-shot | Small fiery hit for spells and fire bullets |
| `fireball` | looping | Projectile: move the node and the flame trail stays behind |
| `hit_spark` | one-shot | Melee or bullet impact |
| `slash` | one-shot | Sword swing in front of the node, along -Z |
| `lightning_strike` | one-shot | A 14 m bolt that strikes the node's origin |
| `heal` | one-shot | Rune circle, light column, rising sparkles |
| `level_up` | one-shot | Gold pillar, rising rings, star burst |
| `shield` | looping | Hex force field; call `impact(point)` for ripples |
| `portal` | looping | Swirling gate facing +Z, with a floor circle |
| `poison_cloud` | looping | Toxic cloud with bubbles |
| `ice_burst` | one-shot | Ice shards, frost ring, mist |
| `muzzle_flash` | one-shot | Fires along -Z; spawn one per shot |
| `pickup_sparkle` | looping | Coin or item glow |
| `ground_slam` | one-shot | Shockwave, dust ring, flying rocks |
| `campfire` | looping | Flames, smoke and embers rising from the node's origin |
| `burning` | looping | Status effect: flames over a 1.8 m tall character |
| `smoke_poof` | one-shot | Cartoon puff for spawning, despawning or hiding |
| `water_splash` | one-shot | Droplet crown, ripples and mist |
| `arcane_missile` | looping | Magic projectile: move the node and the trail stays behind |
| `collect_burst` | one-shot | Gold flash and stars for picking something up |
| `shadow_burst` | one-shot | Dark magic impact with smoke, shards and a shockwave |
| `teleport` | one-shot | Rune circle, light column and rising rings |
| `power_aura` | looping | Buff or rage aura around a character's feet |
| `electric_hit` | one-shot | Lightning arcs and sparks for shock damage |

Every effect uses fewer than 100 particles.

## VFXEffect (the root of every effect)

| Member | What it does |
|---|---|
| `play()` | Plays or replays every layer from the start |
| `stop()` | Stops emitting; live particles finish and lights fade out |
| `impact(world_position, duration)` | Plays a ripple on shield-type meshes |
| `get_duration()` | Seconds until a one-shot effect is done |
| `is_looping()` | True for effects that run until stopped |
| `finished` (signal) | Emitted when a one-shot effect is done |
| `autoplay`, `auto_free`, `time_scale` | Inspector settings; `time_scale` speeds the whole effect up or down |
| **Replay** button | Previews the effect in the editor viewport |

Per-layer timing lives in node metadata, which you can edit in the Inspector:
`vfx_delay` (seconds before a layer or light starts), `vfx_flash` (seconds for a light to fade
out) and `vfx_flicker` (0 to 1, flicker for lights that stay on).

## Making it yours

- **Color:** select a layer, then *Process Material > Color > Color Ramp*.
- **Brightness:** *Material Override > Shader Parameters > Emission Energy*.
- **Size and count:** *Amount* on the layer; *Scale Min/Max* on its process material.
- **Shape:** the particle shader's *Shape* setting (Soft Dot, Flare, Streak, Ring, Puff or Star).
- **Dissolve:** *Erosion* eats a puff away over its life, which is how the fire and smoke break up.
- **New effects:** duplicate a scene and change its ramps. All layers share the same shaders.

## Files

- `effects/`: the 3 sample effect scenes (25 in the full pack)
- `shaders/`: the `vfx_add` (glow) particle shader and the slash shader (the full pack adds
  smoke, beam, bolt, shield, portal, rune and ice shaders)
- `textures/`: a tileable noise texture
- `vfx_effect.gd`: the `VFXEffect` script

Made by REEBOO Labs. Questions and requests are welcome in the comments on the itch.io page: https://reebo0.itch.io/stylized-vfx-godot
