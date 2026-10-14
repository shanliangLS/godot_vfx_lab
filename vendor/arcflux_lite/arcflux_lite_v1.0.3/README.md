# ARCFLUX Lite - Lightning and Beam VFX for Godot 4

Want more effects? ARCFLUX Full: https://gennai.itch.io/arcflux-lightning-beam-vfx

Free version of ARCFLUX. Includes the two core effects and two presets:

- `ArcfluxBolt3D` - one-shot branching lightning bolt: `strike(from, to)`
- `ArcfluxLaser3D` - continuous laser that snaps to the first collision: `set_active(true)`
- Presets: `presets/3d/bolt_blue.tscn`, `presets/3d/laser_red.tscn`
- Palettes: blue, red

Godot 4.4 or newer. Tested on 4.4.1 and 4.7.2 with Forward+, Mobile and Compatibility.
Free for commercial use (see LICENSE.txt). Version 1.0.2.

## What the Full version adds

- More 3D lightning: sky strike with a ground flash and scorch mark, chain lightning
  (`chain([a, b, c])`), a continuous arc between two moving nodes, an electric aura on any
  mesh, a Tesla coil and a plasma ball
- More 3D beams: energy beam with a charge-up (`fire()`), railgun trail, heal / tractor beam
- EMP shockwave and electric impact burst
- 5 2D effects (bolt, chain, arc, laser with 2D raycast, impact) with an optional pixel mode
- 33 presets instead of 2, and 6 palettes (blue, purple, red, green, gold, white) instead of 2
- Demo project with a showcase scene, a 2D showcase and a click-to-fire playground
- Same addon folder and class names: to upgrade, copy the Full `addons/arcflux_fx/` over
  the Lite one

You can try every effect in the browser on the Full page:
https://gennai.itch.io/arcflux-lightning-beam-vfx

## Install

Copy `project/addons/arcflux_fx/` into your project. The nodes appear in the Add Node dialog
(search "Arcflux"). Open `project/` in Godot to run the demo (click the floor to strike).

## Quick start

```gdscript
var bolt := ArcfluxBolt3D.new()
add_child(bolt)
bolt.strike($Hand.global_position, $Enemy.global_position)
```

```gdscript
$Laser.set_active(Input.is_action_pressed("fire"))
```

Add a `WorldEnvironment` with Glow enabled for the best look. Without glow the effects
still draw their own soft halo.

## Bolt properties

`end_point`, `target`, `one_shot`, `interval`, `width`, `chaos`, `segment_length`,
`branches`, `branch_length`, `branch_angle`, `branch_depth`, `end_width`, `bow`,
`halo_width`, `leader_time`, `stepped_leader`, `restrikes`, `flicker_time`, `afterglow`,
`branch_decay`, `impact_flare`, `impact_flare_size`, `source_flare`, `impact_sparks`,
`light_position`, plus the common `palette`, `intensity`, `time_scale`, `autoplay`,
`preview_in_editor`, `random_seed`, `light_enabled`, `light_energy`, `light_range`.

## Laser properties

`target`, `max_length`, `collide`, `collision_mask`, `ramp_time`, `width`, `core_ratio`,
`halo_width`, `body_glow`, `outer_glow`, `flow_speed`, `edge_noise`, `body_noise`, `pulse`,
`pulse_speed`, `muzzle_flare_size`, `impact_flare_size`, `impact_sparks_per_second`,
`impact_in_air`. Methods: `set_active()`, `is_active()`, `is_hitting()`, `get_end_point()`.

## Full version

ARCFLUX Full adds sky strikes with scorch marks, chain lightning, continuous arcs, electric
auras, Tesla coil, plasma ball, energy beam with charge-up, railgun, heal/tractor beam, EMP,
impact bursts, five 2D effects with a pixel mode, 33 presets, six palettes and a showcase.

Get it here: https://gennai.itch.io/arcflux-lightning-beam-vfx

## Rating

If this pack is useful to you, a rating on its itch page helps other Godot users find it:
https://gennai.itch.io/arcflux-lite
If something breaks or you have a question, leave a comment on the same page and I will answer.

## Changelog

- 1.0.3 - README only (nothing else changed): a short Rating section with the itch page link.
- 1.0.2 - README: a list of what the Full version adds. Demo: the corner note is now a
  small button that opens the Full page. The addon is unchanged.
- 1.0.1 - Links to the Full version in the README and the demo.
- 1.0 - First release.
