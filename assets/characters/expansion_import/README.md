# Imported expansion characters

`BrainrotExpansion.glb` combines the 22 main/Mini exports from `expansion_a` and `expansion_b` into one Roblox import, retaining individual meshes and two shared palette materials. Rebuild it with Blender using `tools/build_expansion_import.py`.

Imported through Roblox Studio on 2026-10-19. `asset-manifest.json` records the resulting cloud mesh IDs, texture IDs, sizes and orientation. The 22 `.model.json` files in `../expansion_roblox` are the persistent runtime source mapped to `ReplicatedStorage.ExpansionModels`. Main models are five studs high, Minis two studs high before any runtime decoration scaling. Imports have identity orientation and face Roblox -Z.

Both Edit and Play preload verified every mesh and texture reference successfully. All eleven Mini variants decorate the six farmer stalls. The main characters are ready-to-clone templates; the existing six production tiers remain unchanged.
