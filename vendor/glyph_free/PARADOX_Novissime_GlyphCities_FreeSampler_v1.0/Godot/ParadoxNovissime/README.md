# PARADOX Novissime - Glyph Cities

Stylized low-poly alien ruins from the planet Novissime: 18 modular models and 12 live effects (FREE SAMPLER of the full 124-model, 16-effect pack), every one in 4 colourways (496 model variants + 64 effect variants) for Godot 4 (FBX included for Unity and other engines).

**Made with AI. Tested in real engines.** Every model and effect was generated with AI and then checked the only way that matters: does it work in your game? See `docs/COMPATIBILITY.md` for the test results.

## What's inside

| Folder | Contents |
|---|---|
| `models/` | 124 glTF models (`.gltf` + `.bin`), all sharing one palette image; drag into a scene (see `docs/MODELS.md`) |
| `effects/` | 16 drag-and-drop effect scenes (see `docs/EFFECTS.md`) |
| `demo/` | One demo stage per effect, shown inside its matching model |
| `textures/` | Particle and glyph sprites for the effects (the model palette lives in `models/`) |
| `scripts/`, `shaders/` | Small runtime scripts (loop, flicker, lightning, spin) and the portal / hologram / beam shaders |
| `themes/` | 4 colourways (Cyan, Violet, Gold, Red): palettes + ready materials |
| `docs/` | Model list, effect reference, compatibility results |

## Install (Godot 4.4 or newer)

1. Copy the whole `ParadoxNovissime` folder anywhere inside your project. It does not need to be at the root.
2. Let Godot finish importing.
3. Open any scene in `demo/` to see an effect in its model.

Moving or renaming the folder inside Godot's FileSystem dock is safe; every scene references its files by UID.

## The kit

- **Grid:** everything snaps to 2 m. Floor tiles are 2 x 2 x 0.2 m (top at 0.2 m). Walls are 2 m wide, 0.4 m thick, 3 m tall.
- **Pivots:** at the base centre of each piece. Fronts face +Z in Godot. Hanging pieces (`SM_Crystal_Hanging_*`, `SM_Light_HangingCrystal`) have their pivot at the ceiling.
- **Families:** Architecture (32), Monuments (25), Crystals (27), Artifacts (21), Portals and Gates (13), Lights (6).
- **Triangles:** 24 to 1,216 per model; most under 400. Light enough for web and mobile.

## Recolour the whole pack in one step

All 124 models share one material and one tiny palette image.

1. Open `models/T_Novissime_Palette.png` (8 x 8 colour cells) and `models/T_Novissime_Emission.png` (which cells glow).
2. Repaint a cell, for example the cyan glow cells to violet or gold, in any image editor.
3. Save. All 124 models update, because they all point to these two images.

## Colour themes: 4 colourways, 496 model variants

Every model comes in **Cyan** (default), **Violet**, **Gold** and **Red**.

- **Recolour one model:** drag `themes/M_Novissime_Gold.tres` (or Violet / Red / Cyan) onto the model's *Material Override*. Mix colours in the same level.
- **Recolour the whole pack:** copy a theme's two images over `models/T_Novissime_Palette.png` and `models/T_Novissime_Emission.png`.
- **Matching effects:** every effect exists in each colourway: `effects/FX_PortalSwirl_Vertical_Gold.tscn` etc. (Cyan has no suffix). Each has a demo in `demo/` with the matching coloured model.
- **Recolour a whole section:** add `scripts/theme_apply.gd` to any parent node and pick a theme material; every mesh below it recolours.
- **Unity:** `Materials/M_Novissime_Violet / _Gold / _Red` - drag onto any model.

## Using the effects

Drag an effect scene from `effects/` into your level, or instance it from code:

```gdscript
var fx := preload("res://ParadoxNovissime/effects/FX_PortalSwirl_Vertical.tscn").instantiate()
fx.position = portal.position + Vector3(0, 1.75, 0)
add_child(fx)
```

Each effect's root node has a description (hover it in the Scene dock) saying where it fits and what to tweak.

- **One-shot effects** (Glyph Pulse, Teleport, Crystal Shatter) replay every `interval` seconds. Set `interval` to `0` and call `play()` from your own code. Use the **Replay effect** button in the Inspector to preview them in the editor.
- **Lights:** the lamp, beacon, crystal and portal effects include real lights. The glowing models themselves only glow; add an effect (or your own OmniLight3D) where you want light cast on the scene.
- **Glow:** effects use colours brighter than white, so enable Glow in your `WorldEnvironment`.

## Particle collision

Crystal Shatter shards bounce on Godot particle colliders. Effects do not carry their own colliders, because built-in colliders would affect every effect in the scene. Add one `GPUParticlesCollisionHeightField3D` to your level, sized to the play area.

## Other engines

`FBX/` (next to this folder in the download) has every model as FBX at real-world scale (scale 1 in Unity). The palette uses crisp pixel filtering: in Unity set the two palette textures to **Filter Mode: Point** and enable **Emission** with `T_Novissime_Emission` on the material. The included Unity helper script does both automatically.

## Updates and voting

This pack keeps growing. Buyers vote on the next upgrade (more detail, new colour themes, LODs and collision shapes, animated glyphs). Every update is free for everyone who bought it.
