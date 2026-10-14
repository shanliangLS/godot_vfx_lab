# Compatibility

Tested by copying the `ParadoxNovissime` folder into a fresh project at `res://third_party/assets/` (not the root), importing,
then loading and running every model, effect and demo stage.

| Godot version | Models | Effects | Demos | Import time |
|---|---|---|---|---|
| 4.4.1 | 124 / 124 | 16 / 16 | 16 / 16 | ~14 s |
| 4.5.2 | 124 / 124 | 16 / 16 | 16 / 16 | ~13 s |
| 4.6.3 | 124 / 124 | 16 / 16 | 16 / 16 | ~12 s |
| 4.7.2 | 124 / 124 | 16 / 16 | 16 / 16 | ~15 s |

Minimum: **Godot 4.4**. (4.4.1 prints a harmless "Parameter t is null" line per model when importing headless; the editor does not.)

Renderers: Forward+ (reference), Mobile, and Compatibility / web (the live demo on the store page runs on Compatibility).

## Unity

Unity 6.3 LTS (built-in pipeline), all 124 FBX with the included `NovissimeImporter.cs`:

| Check | Result |
|---|---|
| Scale | 1.0 on 124 / 124 |
| Material | all 124 share ONE material (`M_Novissime`), so recolouring the palette updates everything |
| Glow | emission on for 124 / 124 |
| Pixel filtering | Point (crisp) |

URP: the importer picks `Universal Render Pipeline/Lit` automatically when URP is installed.
