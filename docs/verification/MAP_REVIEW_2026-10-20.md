# Map and gameplay review — 2026-10-20

Implemented and tested in the `MergeABrainrot-FirstPlayable` Studio place, from the `brainrot-first-playable/merge a brainrot` worktree.

## Visible map changes

- Blender-authored green, gold and brown ground meshes with wider square recesses, deeper edge shading, continuous texture color variation and broad world-space tint variation. The same treatment covers island sides, the central plaza, paths and sign panels.
- New tree, bridge, bush, log and grass meshes. The bridge has beveled planks, varied wood tones, square studs, washer/peg joins, capped posts, braces and supports. Its existing envelope and walking plane are preserved.
- Wider plot/rear conveyor area, clear cash/deposit approach, exact bridge/path join, larger processor board, and supports between upper display rows.
- Smooth six-face blue skybox with a pale horizon. The faceted dome is removed. Warm lighting and shadows are enabled.
- All 25 producer templates are present and normalize to 3.15 world studs tall. Mini pickup sizes are unchanged.
- White moving tutorial arrows, compact basket, modeled HUD icons on tinted tiles, index ray animation, and updated multiplier/pickup presentation.

The `.blend` sources, GLBs, import manifests, geometry audits and previews are under `assets/map/ground_review`, `assets/map/detail_props`, and `assets/map/reference_sky`. These are original assets authored for this project using the supplied visual references.

Actual Studio captures:

- [Ground and sky](review-ground-final.jpg)
- [Bridge and island edges](review-bridge-final.jpg)
- [Producer/avatar scale](review-scale-final.jpg)

## Gameplay changes

- Three same-tier producers merge into the next tier. Buy100 compacts before the capacity check.
- Tier 1–9 drops follow the supplied sequence: 1, 5, 25, 90, 300, 1,100, 4,000, 15,000, 60,000. Higher values are a designed continuation, not values established by the screenshots.
- Processor upgrades use the rebalanced progression documented in `review-economy-results.md`.
- Deposit multiplier is applied once, with fractional remainder retained server-side and the input, multiplier and credited quantity shown in the receipt.
- Standing on Buy1 repeats every half second and resumes after funds arrive. A bounded server recheck handles delayed physics packets without accepting client positions or widening purchase footprints.
- Cash-pad receipts count down over 1.5 seconds, showing whole dollars only. Cash particles return to the moving character. Basket and wallet increases animate.
- Short sound envelopes and priority voices improve action feedback. Redundant proximity panels are removed.

## Verification

- 57 pure Luau suites passed; all 16 engine-mock CLI suites passed.
- 210 source/test Luau files compiled before the final entry helper; the new helper, modified server handler and affected tests also compiled separately.
- Rojo built `build/MergeABrainrot-ReviewVerified.rbxlx`.
- Native layout checks passed for all six plots, bridge interfaces, 48 display lanes, 24 chutes, six signs and clear decorative approaches.
- Native producer checks passed for all 25 tiers: correct mesh, approximately 3.15 height, bay clearance, floor alignment and unchanged source templates.
- Native held-Buy1 test passed with exactly three purchases from one entry, no leaving/reentry, a 1.115-second funds shortage and automatic resumption. Repeat interval was 0.500 seconds. Local feedback measured 1.94–2.06 ms; server confirmations measured 66–283 ms. This is not a claim of sub-10-ms network completion. Full results: `review-held-buy-final.json`.
- Native deposit walk produced the exact receipt `Deposited 5,280 Minis (1.06× → 5,596)`, with empty bag, remainder 80/100 and sorted producers.
- Native cash label check produced `$700,000`, `$350,000`, `$0` at 0, 0.75 and 1.5 seconds.
- Native cash return/cleanup, compact basket and four modeled HUD icon checks passed.
- Studio still reports unrelated pre-existing cloud-plugin/UIBlox warnings and an asset-type warning for ID 203785492; that ID is absent from the project source/assets.

Both Main scripts are restored enabled. Disposable fixture progression is discarded on Stop. The local place is saved; this work does not publish the game or merge the draft PR. Cross-device performance and a live multi-player network test remain unmeasured.
