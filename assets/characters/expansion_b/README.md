# Expansion B reference-inspired brick characters

Rebuild with `blender --background --python tools/build_expansion_b.py`. All geometry is original, procedurally authored in Blender from the four supplied character screenshots.

- GorilloSubwoofero: broad gorilla silhouette, ten recessed faceted speaker cones, chest cables, heavy knuckles and brown crown stripe.
- ToilettoFocaccino: porcelain toilet bowl/cistern, orange seat, armored robot limbs, red goggles, grille mouth and thick lavender ghost flames.
- OdinDinDinDun: layered orange fruit, long arms, bent green stem, moustache and black/white sneakers.
- TukannoBananno: black toucan, huge drooping banana bill, green eye rings, golden chest, folded wings and splayed toes.

Each main GLB is 5 Blender units tall; each `_Mini.glb` is 2 units tall, with reduced surface studs. Every GLB contains exactly one joined mesh, one material, one embedded palette image and a sole UVMap exported as TEXCOORD_0. Bounds start at ground Z=0; front is Blender -Y (Roblox -Z). Use uniform game scaling as needed. Editable Blender scene and reproducible builder are included. See mesh-stats.json for exact triangle counts and bounds.
