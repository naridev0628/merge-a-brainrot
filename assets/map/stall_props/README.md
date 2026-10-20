# Blender stall props

Original brick-style props authored from the user references. `KeyCrate.glb` is an open slatted crate with mini-placement slots documented in its manifest. `ShippingCrate.glb` is a tidy empty open crate with crossed plank braces. `CashStash.glb` includes bullion bars, coin stacks, loose coins, and two tied beige cash bags with raised green dollar marks.

Each GLB has one mesh, one material, an embedded palette, and only TEXCOORD_0. Rebuild with tools/build_stall_props.py. The editable combined Blender scene, palette, review renders, and exact counts are included.

The `*-layout.json` files record every primitive before join. Use type Block/Cylinder, size_roblox, position_roblox, rotation_matrix_roblox (row-major), and color_srgb for native Roblox Parts. Coordinates have already been converted from Blender Z-up to Roblox Y-up. Cylinder size X is its thickness, matching Roblox Cylinder geometry. Blender edge bevels and 16-sided coin facets are the only appearance differences from native smooth-edged Parts; all placements/colors are preserved. Crate manifests include interior bounds/placement slots in Blender coordinates.
