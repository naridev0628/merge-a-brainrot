# Build status — 2026-10-20

Current engineering checkpoint: [overnight handoff at 07:17 UTC](verification/OVERNIGHT_HANDOFF.md) and [progress JSON](verification/OVERNIGHT_PROGRESS.json). The verified batch is ready for commit/push to draft PR 2. All **76 source files compile**, **40 standalone Luau tests pass**, and Rojo builds; after the scoped PadLabels cleanup fix, targeted compilation/native QA and another rebuild passed. [Studio verification](verification/studio-source-verification.json) matches all **76/76 project scripts** by normalized checksum and byte length, excluding six untouched engine scripts. Both Main scripts are enabled, the harness is removed, and current normal Play is fresh with zero producers.

**GroundCap=96 remains a Studio-preview setting; producer Slots=50 remains unchanged.** The native Humanoid tray walk passed all 96 mixed Minis, all six species, partial repacking, and five waypoints over 52.0936 world studs. The updated ten-checkpoint obby driver and finish award passed again; Home separately preserved the award.

The optimized 600-second churn reduced Conveyor work about 51%, while overall mean frame time did not improve. A later 60-second settled return measured mean frame 16.662 ms, p95/p99 17.75/18.25 ms, and mean Conveyor work 0.383 ms. Across 186.744 seconds, recovery snapshots retained 89,116 global Instances and 39,749 world descendants, while total memory changed 3725.582 → 3728.340 MB. This does not establish full memory recovery or resolve growth. Device, multiplayer, worst-case species, and longer-duration validation remain open.

The world multiplier-change cue, lighthouse cull, pad affordability, and all 15 local PadLabels passed native QA. Lighthouse Parts fell **744 → 379** while its 51 body Parts and 22 colliders stayed unchanged; the fractional tree palette is preserved. PadLabels separates Buy costs and restores managed text properties on teardown. The actual production controller completed first purchase in **0.2654108 seconds from local pad entry**, with three staging-replication `TooFar` responses before success; this single smoke sample is not a latency guarantee. Raw evidence and before/after captures are linked in the handoff.

Next, exercise the missing shipped-controller paths: airborne pickup with Lucky open, standing cash claim, deposit, and upgrades. Then compare remaining map/HUD gaps, including cyan/gold Lucky presentation from four newly inspected gameplay moments, without inventing reference economy rules. Inspect allocation sources before another performance change; do not repeat the completed profile without a new hypothesis. The minimum overnight work window continues until **13:30 UTC**, with an active **15-minute** continuation heartbeat. Nothing is merged or published, and the window is not complete. The records below describe earlier checkpoints and do not override this current status.

## Chicken Farm reference implementation

The annotated [reference board](reference/chicken-farm-video/index.html) now maps all twelve captured moments to concrete applied changes and includes four implementation previews. Shared rounded typography, separate pad title/price labels, a larger woven Mini basket, responsive nonmodal Lucky odds and two real rebirth reward tiles follow the reference hierarchy. Small-phone Lucky content scrolls when necessary, keeping both actions reachable.

The rear display spans about 90% of the conveyor width; character names wrap and scale within their physical bays. The group board's blank face is repaired, the processor board exposes implemented status/rate, and the deposit pad has a broader warm glow. Cash, pickup, deposit, purchase and discovery effects use bounded bursts. Higher-tier accents affect at most sixteen nearby producers. Successful actions use three reusable quiet audio voices and distinct pitch patterns from the existing cleared project cue; original video audio has not been audited or copied.

Verification: all 46 source files compile, all 22 standalone Luau test files pass, and Rojo builds the place. Studio checks pass for ten HUD sizes (including short portrait and landscape), reachable Lucky actions, pickup aggregation/expiry, mirrored environment, pad affordability, producer grounding, cash/deposit/tier effect budgets and cleanup, and the three-voice audio pool. Populated-row, Lucky, rebirth, farmer/deposit and utility-board views were inspected. These are Studio checks, not physical-device or multiplayer certification. See [verification details](verification/CHICKEN_FARM_REFERENCE_PASS.md).

## Prior refactor and reference preparation

Client pad targeting now lives in the pure `Shared/PadTargeting` module. `Main.client` retains the interaction scheduler, remote handling, Lucky pickup and aura. The extraction preserves action precedence, full-pad corner ownership, exact Buy quantities, merge eligibility, immediate entry and the existing two-second/half-second repeat. No balance or visual behavior changed in this preparation pass.

The supplied Chicken Farm video was inspected in Chrome at selected early, middle and late moments. Twelve timestamped screenshots document the HUD, conveyor/pad row, farmer/deposit, plot proportions, Lucky card, pickup numbers, processing board, cash effects and rebirth layout. The board distinguishes observed details, adaptations and the user's existing overrides. It is not a continuous viewing or audio audit. Reference screenshots are documentation only and are outside the Rojo project mapping.

Verification for this pass: all 22 standalone Luau test files pass; all 43 source files compile; Rojo builds `MergeABrainrot-StackedFarm.rbxlx`; the new targeting module passes standalone analysis; independent refactor review found no actionable regressions. In Studio, the new module resolved Buy1 correctly, the HUD loaded, and moving the avatar onto Buy1 produced a successful starter purchase followed by the expected insufficient-funds response on the held repeat. This smoke check does not replace a full live Lucky-open/device regression run. The temporary result observer was disconnected afterward.

Work remains on `codex/stacked-brainrot-farm`, based on `codex/first-playable`, in draft PR #2. At the earlier fifty-cap checkpoint, plots had a 50-Brainrot cap, five rows, and at most 50 ordinary conveyor Minis across flight and ground; the current preview raises only the Mini cap to 96 as recorded above. Buy50 replaces Buy100; a shared quote drives server purchases, HUD prices and green/red pad colors. Pads act immediately, then repeat every half-second after a two-second hold. Farmer/barn and utility boards are mirrored left/right, the stall is larger, bridge landings overlap the plots, front fences close around the entrance, and the red center covers the entire conveyor. Producer animation stays grounded. The carried Lucky Block card, cyan Home button and rainbow Cash offer remain in place. See [fifty-cap checkpoint verification](verification/FIFTY_CAP_AND_CONNECTED_PLOTS.md); earlier behavior records are historical.

Build `default.project.json` to `build/MergeABrainrot-StackedFarm.rbxlx` and press Play. Memory only: progress resets on Stop. First rebirth is now $25,000 plus Level 6. Processor upgrades start at $10. Buy 5/10 are available immediately; Buy 50 starts at rebirth 1 and advances the species on that same pad. Ground cash bundles clear after two seconds.

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
