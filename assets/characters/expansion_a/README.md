# Original brick character expansion A

Seven original models modeled procedurally in Blender. No third-party meshes or downloaded textures are used. Each main and mini GLB contains one joined mesh, one palette material, and exactly one UV layer (`TEXCOORD_0`). Main height is 5 Blender units; mini height is 2. Feet touch Z=0; the origin is the ground pivot. Front is Blender -Y, which exports as Roblox -Z. GLB embeds the texture; `ExpansionAPalette.png` is also included separately.

## Files and rebuilding

- `ExpansionACharacters.blend`: editable named main/mini meshes and review lighting. The first pair is visible; other pairs are hidden for clean previewing.
- `<Character>.glb` and `<Character>_Mini.glb`: production and lightweight variants.
- `<Character>Preview.png`: actual Blender render showing main and mini together.
- `mesh-stats.json`: measured triangle counts, vertices, dimensions and UV/material counts.
- Build with `blender --background --python tools/build_expansion_a.py` from the repository.

Minis retain identifying silhouette and facial/accessory details while omitting dense studs, small texture geometry and selected secondary details. Geometry is deliberately a stylized, original interpretation of reference identity rather than an extracted game mesh.

## Reference mapping and uncertainty

| Export key | Display name | Reference and distinguishing features |
|---|---|---|
| NoobiniPizzanini | Noobini Pizzanini | User image `1c906dda-2e78-4605-b378-44edb54e2a82`: yellow smiling head/arms, yellow brim, cyan studded torso, green legs. |
| LiriliLarila | Lirilì Larilà | User image `3ee24930-6a60-4eba-a4dd-5c347b7daafe`: studded green cactus elephant, olive face/trunk, ivory tusks, four sandals. |
| TimCheese | Tim Cheese | User image `042d7e75-a158-41aa-9a7c-62578126500f`: grey mouse, pink ears/nose, silver sunglasses, black suit, purple tie and brown shoes. |
| Fluriflura | Fluriflura | User image `5dbb7888-7109-43b7-8ba3-8dc9da1935b2`: dark toucan with cream belly, orange beak/feet and gold round glasses. Verified against [Fluriflura reference](https://stealabrainrot.fandom.com/wiki/Fluriflura). |
| TalpaDiFero | Talpa Di Fero | User image `0c4fb8f6-9880-4ddd-861c-f8056ad54ff8`: brown mole, round brass goggles, warm orange nose and paws, tan studded belly. |
| RaccooniJandelini | Raccooni Jandelini | User image `3fb077c6-11a0-4d56-b243-b0abc8ee7d6e`: cream monkey face/hands/feet, tan outfit, red top hat with gold crown. [Identity reference](https://stealabrainrot.fandom.com/wiki/Raccooni_Jandelini) describes a raccoon body and monkey head. Added a stylized ringed tail to preserve that hybrid identity from side/back views. |
| PipiPotato | Pipi Potato | No supplied image definitively maps to this character. [Research reference](https://stealabrainrot.fandom.com/wiki/Pipi_Potato) and [image reference](https://steal-a-brainrot.wiki/Pipi_Potato) identify a hamster/mouse and potato hybrid. Original adaptation uses hamster ears/cheeks, speckled warm-brown brick potato body, small pink arms and humanlike feet. |

Reference research performed 2026-10-19. Fan sources differ on rodent terminology (mouse versus hamster); the silhouette uses round hamster-like ears and cheeks while retaining a small rodent muzzle. Economic stats, rarity and availability in those sources are not used by these assets.

## Validation

glb-validation.json independently inspects the exported GLB JSON and checks one mesh, one primitive, one material, embedded palette, only TEXCOORD_0, exact target height, and ground-aligned bounds. All 14 exports passed. Main meshes are 2,932–8,292 triangles; minis are 748–2,088 triangles.
