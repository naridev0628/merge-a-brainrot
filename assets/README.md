# Original Blender asset library

These brick-style meshes and palette textures were authored for this project with the reproducible Blender scripts in `tools/`. User-supplied screenshots and the requested Brainrot visual references informed the designs. No ripped third-party meshes or embedded third-party scripts are included. The familiar character names and reference designs are not a claim of ownership of the underlying franchises.

`blender/` folders contain local source assets; `roblox/` folders contain imported `MeshPart` definitions. The older `ASSET_MANIFEST.csv` describes the initial procedural prototype, not the current imported inventory below.

## Rebuild

Run from the repository root with Blender installed. The current outputs were generated using Blender 5.2.2 LTS. On Windows:

```powershell
$blenderExe = 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
foreach ($script in @(
    'build_brainrot_models.py',
    'build_skibidi.py',
    'build_crocodilo.py',
    'build_map_props.py',
    'build_bonus_props.py',
    'build_brainrot_nest.py'
)) {
    & $blenderExe --background --python (Join-Path 'tools' $script)
    if ($LASTEXITCODE -ne 0) { throw "Blender failed: $script" }
}
```

The generators write GLBs, editable `.blend` scenes, preview PNGs, palettes, and triangle-count JSON files. Some generators also write FBX alternatives. GLBs use a single joined mesh and a palette-atlas material; the atlas image is embedded for import. Scene lights, cameras, and preview floors are excluded from the GLB exports. The first generator supplies shared helper functions to the other scripts; keep it alongside them.

| Generator in `tools/` | Outputs | Editable scene / preview |
|---|---|---|
| `build_brainrot_models.py` | TungTung, Chimpanzini, Ballerina, Tralalero; main and `_Mini` GLB/FBX pairs | `characters/blender/BrainrotCharacters.blend`, `CharacterPreview.png` |
| `build_skibidi.py` | Skibidi and Skibidi_Mini GLBs | `characters/blender/Skibidi.blend`, `SkibidiPreview.png` |
| `build_crocodilo.py` | Crocodilo and Crocodilo_Mini GLBs | `characters/blender/Crocodilo.blend`, `CrocodiloPreview.png` |
| `build_map_props.py` | BrickTree, BrickBush, BrickLog, BrickFlower, BrickGrass, BrickBridge, BrickBarn, BrickLilyPad, Shopkeeper GLBs | `map/blender/BrainrotMapKit.blend`, `MapPropsPreview.png` |
| `build_bonus_props.py` | BrickRockIsland, LuckyBlock, CoolTralalero GLB/FBX exports | `map/blender/BonusProps.blend`, `BonusPropsPreview.png` |
| `build_brainrot_nest.py` | BrainrotNest GLB and identical BrainrotNestFixed reimport alias | `map/blender/BrainrotNest.blend`, `BrainrotNestPreview.png` |

The shared character/Skibidi palette is `BrainrotPalette.png`; the map kit also saves `PropPalette.png`. Crocodilo, bonus props, and the nest use `CrocodiloPalette.png`, `LuckyBlock.palette.png`, and `BrainrotNestPalette.png`, respectively. Rebuilding local exports does not upload them or update Roblox asset IDs.

## Roblox mapping

`default.project.json` maps `characters/roblox` to `ReplicatedStorage.CharacterModels` and `map/roblox` to `ReplicatedStorage.MapModels`. Each `.model.json` stores its mesh ID, texture ID, imported size, and anchored/non-colliding properties. `src/shared/ModelFactory.luau` clones these templates. Mini geometry is exported at its source size and scaled to 0.42 by the producer factory.

Character filenames below omit the common `.model.json` suffix. Main and Mini IDs are separate uploads even when they share a palette.

| Local GLB | Roblox template | Mesh ID | Texture ID |
|---|---|---:|---:|
| TungTung | tier_01 | 90540311588684 | 96615363382476 |
| TungTung_Mini | tier_01_Mini | 84241195021837 | 100953947831905 |
| Chimpanzini | tier_02 | 133968757589877 | 80668443940912 |
| Chimpanzini_Mini | tier_02_Mini | 76267237896238 | 100953947831905 |
| Ballerina | tier_03 | 130327912478090 | 113800968386040 |
| Ballerina_Mini | tier_03_Mini | 131281464105642 | 70625725014519 |
| Tralalero | tier_04 | 96619356821743 | 74525185352432 |
| Tralalero_Mini | tier_04_Mini | 109268338996225 | 139701317647382 |
| Skibidi | tier_05 | 122021953736567 | 70625725014519 |
| Skibidi_Mini | tier_05_Mini | 92444647753394 | 70625725014519 |
| Crocodilo | tier_06 | 91734208278615 | 100011333208210 |
| Crocodilo_Mini | tier_06_Mini | 132112159852307 | 113608213681953 |

Map GLBs map to identically named files in `map/roblox`, for example `BrickTree.glb` to `BrickTree.model.json`. `BrainrotNestFixed.glb` is an alternate import filename for the corrected `BrainrotNest.glb`; both map to `BrainrotNest.model.json`.

| Map template | Mesh ID | Texture ID |
|---|---:|---:|
| BrickTree | 97126873613114 | 70625725014519 |
| BrickBush | 77904833453971 | 70625725014519 |
| BrickLog | 124237300445580 | 70625725014519 |
| BrickFlower | 93216957971156 | 70625725014519 |
| BrickGrass | 103199984160085 | 70625725014519 |
| BrickBridge | 110057911996854 | 70625725014519 |
| BrickBarn | 138674953489399 | 70625725014519 |
| BrickLilyPad | 120321747160351 | 70625725014519 |
| Shopkeeper | 98971650045663 | 70625725014519 |
| BrickRockIsland | 132359487497933 | 92286468279093 |
| LuckyBlock | 118562479134657 | 122055703541613 |
| CoolTralalero | 97742083681887 | 106777814112940 |
| BrainrotNest | 89792719614296 | 83615912467282 |

BrainrotNest is used in the farm display bays by `WorldBuilder.luau`. Its local Blender bounds are 5.3714 × 5.3714 across and 0.4772 high, starting at Z=0. Its imported Roblox size uses Y as height. The nest combines two brown brick courses, a studded gold center, and short gold straw blocks.

Keep the atlas as the **only UV layer**, exported as `TEXCOORD_0`. An earlier nest export retained primitive UVs as UV0 and placed its atlas on UV1; Blender rendered correctly but Roblox displayed incorrect black/white palette samples. The nest generator now removes the unused layer, and all current GLBs were inspected for one UV set with their material using UV0. Re-exporting the PNG alone does not fix this geometry mapping issue.

## Verified geometry budgets

Counts below come from the checked-in generator stats files, not estimated rendering performance or a statement of Roblox platform limits.

| Character | Main triangles | Mini triangles |
|---|---:|---:|
| TungTung | 4,740 | 1,036 |
| Chimpanzini | 4,276 | 996 |
| Ballerina | 4,240 | 1,660 |
| Tralalero | 7,416 | 1,540 |
| Skibidi | 7,196 | 2,488 |
| Crocodilo | 10,002 | 2,838 |

Map meshes range from BrickGrass at 176 triangles to BrickBarn at 14,652. BrickRockIsland has 10,064, LuckyBlock 5,028, CoolTralalero 7,900, and BrainrotNest 3,876. All current individual GLB exports are below 15,000 triangles; the nest is below its 4,000-triangle target. Totals depend on how many instances the map displays.

Detailed counts are in `characters/blender/mesh-stats.json`, `skibidi-stats.json`, `Crocodilo-stats.json`, and `map/blender/mesh-stats.json`, `bonus-stats.json`, `BrainrotNest-stats.json`.

## Portability and permissions

The `.model.json` files reference Roblox-hosted meshes and textures; they do not contain the mesh data or image pixels. Copying the repository, syncing with Rojo, or copying an asset ID does not grant another account, group, or experience permission to use those uploads. Mesh access and texture access both need verification in the destination experience. A mesh that loads without its texture is not a successful portable import.

When moving ownership or publishing elsewhere, import the local GLBs under the intended owner or configure the required asset permissions, then replace both `MeshId` and `TextureID` in the corresponding `.model.json` files with the destination's usable IDs. Preserve the intended imported sizes and test colors in Studio and the published experience. Keep the `.blend` files, palettes, and generators as the independent rebuild sources.
