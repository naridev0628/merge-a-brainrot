# Square recessed ground — revision 2

Import **GroundDetailImport.glb**. It contains eight embedded-texture meshes:
green, gold and brown square/triangle tiles, the green island-side panel, and
the existing tree envelope. It contains no sky. Older files and imported asset
IDs are retained separately; this build does not rewrite Roblox IDs.

The revision replaces the previous narrow, two-sided recess shading with four
matched square loops: broad surface, bevel lip, dark inner wall and inset floor.
The recess opening is 1.26 logical studs wide instead of 0.84. Relief spans
0.02–0.18 above the original collision plane. Island-side panels are 16×8 with
four rows, keeping side recesses square on the thick foundations.

The palette PNG is written as explicit sRGB bytes. The green surface varies
continuously from approximately RGB(98,157,40) to RGB(150,200,60), with darker
forest-green rims and floors. Continuous vertex UV gradients avoid random
per-cell colors; GroundSurface adds deterministic variation across larger areas.

Verification:

- All polygon normals face their authored surface; minimum positive dot 0.3719.
- All triangle winding agrees with its polygon normal; no zero-area triangles.
- 1,664 triangles per square tile, down from 2,432.
- Eight meshes / 14,872 triangles in the complete import.
- GroundSurface CLI verifies unchanged collision planes, exact plot/octagon
  bounds, safe relief, meaningful tint variation, side normals and fallbacks.
- `GroundSurfacePreview.png` shows the actual top/side meshes.
- `GroundGameplayPreview.png` tests repeated ground at avatar-camera distance.
- `ground-detail-audit.json` records the frozen bundle hash and measured values.

Regenerate with Blender 5.2:

`blender --background --threads 4 --python tools/build_ground_review.py`
