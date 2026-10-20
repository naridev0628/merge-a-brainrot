# Original Brainrot market props

Built and rendered in Blender 5.2.2 with `tools/build_brainrot_market.py`.
The log merchant, coffee-cup merchant, and three-face market sign are original
geometry. `BrainrotMarket.blend` preserves the editable joined meshes, palette,
camera, and lighting. Each GLB contains one mesh, one material, and UV0 only.

| Prop | Triangles | Native solids |
| --- | ---: | ---: |
| BrainrotLogKeeper | 1,340 | 37 |
| BrainrotCoffeeKeeper | 1,468 | 37 |
| BrainrotMarketSign | 760 | 26 |

The exact pre-bevel solid layouts generate `src/shared/BrainrotMarket.luau`.
Runtime prefers an imported MeshPart with the matching name in `MapModels`;
otherwise it places the authored solids. Both variants preserve color and
placement; the GLB adds the bevels shown in the preview.

`*-mesh.json` records Blender triangle geometry for the Studio EditableMesh
importer: Roblox-space vertices, reversed zero-based face winding, face normals,
three UV pairs per triangle, bounding size, and bounding center. Coordinates are
converted from Blender `(x,y,z)` to Roblox `(x,z,y)`. The palette is
`BrainrotMarketPalette.png`. Do not apply a second coordinate conversion.

The farm uses the log merchant. Two compact hub stands use the log and coffee
merchants between bridge approaches, outside the central plaza. All six bridge
routes remain open.
