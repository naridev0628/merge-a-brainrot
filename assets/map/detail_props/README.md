# Detailed drop-in brick props

Import `MapDetailImport.glb`, replacing only the existing `BrickBridge`,
`BrickBush`, `BrickLog` and `BrickGrass` templates. The four object/node names
match those templates. One embedded explicit-sRGB palette supplies face shading.
The generator reads current template sizes but never changes their asset IDs.

Every model preserves its exact native envelope and ground-center pivot. The
bridge additionally preserves the deck top at 0.5 above its lower bound, the
13.6-wide walkway and plank endpoints at ±31.45. Its authored length remains
64; WorldBuilder can retain its existing resize to length39.

| Model | Triangles | Detail |
|---|---:|---|
| BrickBridge | 16,324 | 21 beveled planks, 147 square studs, inset washers/pegs, mortised rails, post crowns, diagonal braces, underside supports |
| BrickBush | 2,244 | Rounded two-tier foliage, shaded side studs, dark stacked course |
| BrickLog | 1,300 | Beveled block bark, square cut-end rings, top mould lines and shaded studs |
| BrickGrass | 704 | Four capped blades, raised ribs and shaded roots |

`mesh-stats.json` records measured and expected dimensions. `import-audit.json`
records the frozen GLB hash. The generator verifies nonzero triangles, consistent
normal winding and all envelope dimensions before export.

The PNGs show each actual sculpture, bridge joinery close-up, and the bridge at
the current 39-stud gameplay length. `MapDetailProps.blend` retains the models,
materials and render setup. No realistic wood grain or new scenery style is used.

Regenerate:
`blender --background --threads 4 --python tools/build_map_detail_props.py`
