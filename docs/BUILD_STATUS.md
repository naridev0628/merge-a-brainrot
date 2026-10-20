# Build status — 2026-10-19

Current work is on `codex/stacked-brainrot-farm`, based on `codex/first-playable`, in draft PR #2. The latest pass replaces nests with studded brick platforms, fixes decoration positions and pad footprints, enlarges ground Minis and crates, adds a 12-stud pickup sphere, and changes production to a one-second base cycle. Buy/Upgrade repeat every 0.1 seconds after a two-second hold. The farmer sign, glowing deposit pad and hub have more brick detail; lily pads and rock islands support players. See [current verification](verification/INTERACTION_AND_LAYOUT.md). Earlier [seamless-farm checks](verification/SEAMLESS_FARM.md) and [economy benchmark](verification/ECONOMY_PACE.md) are historical; their previous production timings and pickup distances are superseded.

Build `default.project.json` to `build/MergeABrainrot-StackedFarm.rbxlx` and press Play. Memory only: progress resets on Stop. First rebirth is now $25,000 plus Level 6. Processor upgrades start at $10. Buy 5/10 are available immediately; Buy 100 starts at rebirth 1 and advances the species on that same pad. Ground cash bundles clear after two seconds.

Eleven new original characters and eleven matching Minis are imported into Roblox with both palette textures. All 22 templates are saved under `assets/characters/expansion_roblox`, mapped to `ReplicatedStorage.ExpansionModels`, and verified to load in Edit and Play. All eleven Mini variants appear across 36 farmer-crate decorations. Main characters are reusable templates; assigning new gameplay tiers is separate from this import. Three stall props render as native parts derived from their Blender layout. Editable Blender sources, GLBs and previews remain included.

Pending release work: saving, global rankings, configured purchases/group reward, friend boost, real multiplayer/device load tests and final-owner asset permissions. A user-supplied water texture is still pending. Collaborator invitation and Mac verification remain pending. No live experience was published.

## Historical Checkpoint 0 record — 2026-10-14

BUILD_MODE: INCREMENTAL

Checkpoint 0: Windows build, Studio open/Play, and Rojo live sync verified; private shared repository created. Collaborator access and Mac verification pending.

Completed:
- Extracted the 30-file handoff intact into `Merge_a_Brainrot_Pack/`.
- Read the canonical specification and incremental scope.
- Inspected the initially empty Git repository; no remote or existing commits were present.
- Created `codex/checkpoint-0-setup`.
- Verified Git, installed Studio, and connected Studio tool availability.
- Installed project-local Rojo 7.7.1 and verified the official archive digest.
- Created portable shared/server/client mappings and successfully built an isolated setup place.
- Documented Windows and macOS setup, distinguishing executed checks from instructions.
- Opened the generated setup place in its own Studio window (PlaceId 0).
- Connected the installed Rojo 7.7.1 plugin to this project's server on localhost:34873.
- Verified a temporary ModuleScript appeared, a source edit synced, and removal synced; removed the probe afterward.
- Ran Play: one player spawned at approximately (0, 4.645, 0), with Health 100 and a solid Plastic floor. Visually confirmed the avatar on the floor, then stopped Play.
- Following the owner's clarification that no shared repository existed, created private `naridev0628/merge-a-brainrot` for this project.

Pending:
- Owner to invite the collaborator to the new private repository.
- Verify the collaborator's Mac setup.

The setup place is open in Edit mode. The separate `StackAndSteal-TreasureV2-2026-10-14.rbxl` instance was not modified. The Rojo development server was left running on port 34873 for this session.

Next learner action: invite the collaborator through the repository's Settings → Collaborators / access page.

Roadmap: Checkpoint 1 first playable loop → 2 full farm/rebirth → 3 persistence → 4 presentation → 5 QA. The supplied UI design remains a draft. No gameplay implementation, persistence, gameplay test passes, or release readiness is claimed.

Installed-plugin issues observed: `cloud_9643911698.Superpower.LocalScript:5` reports a syntax error; AssetExport reports an animation-export ferry connection failure. Neither is project source. These were recorded without disabling or modifying unrelated plugins.
