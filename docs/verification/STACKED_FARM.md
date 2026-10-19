# Stacked farm verification - 2026-10-19

Scope: `codex/stacked-brainrot-farm` against `codex/first-playable`. Roblox Studio on Windows, Rojo 7.7.1, Luau 0.743. This is a Studio-only memory prototype, not a published release.

## Automated checks

All nine non-Studio test scripts passed on the final source: `run` (13 cases), `conveyor`, `lucky`, `onboarding`, `progression`, `review-regressions`, `sales`, `stacked`, and `tier-values`. All 27 source files compiled. Strict analysis of FarmCore, RateLimiter, Config, CreatureCatalog, StarterPad and Tutorial passed. Rojo built `build/MergeABrainrot-StackedFarm.rbxlx`. Whitespace checks passed.

Coverage includes rejected malformed/distant/dead/foreign requests, duplicate/replayed purchases/merges/payouts, finite money/capacity bounds, earned progression, rebirth reset/discovery retention, bulk unlocks and remaining-capacity purchases, fair capped production, timed sales/upgrades, Lucky odds/bounds, and tutorial recovery. A new regression covers tiny negative floating-point floor coordinates at the starter pad. All 96 pile positions are unique, remain inside the tray, and can be collected from ground-level feet beneath the token. Pickup tests use live coordinates after repacking.

## Studio gameplay and visual checks

- Fresh spawn has $5 and no welcome modal. Real server transactions: walk-on first purchase, three automatic Mini pickups, deposit, automatic cash-pad claim of $6, second $5 purchase, merge to tier 2, $1 remaining. QA teleports briefly produced TooFar rejections before server position replication; subsequent validated requests succeeded without duplicate credits.
- All six plots generated. Lawn measures 56 × 56 studs, half the previous width/depth. Nearby pad centers are within a few seconds of walking. Cash and upgrade pads are adjacent. Conveyor has red studded inclines and no conveyor arrows; tutorial path arrows remain intentionally.
- Independent visual fixture rendered 100 producers across 10 rows and 96 individual Minis. Final pile mixes species/angles across four layers; Crocodilo remains flat. This is deterministic client settling/jostling, not a physical rigid-body simulation.
- Producer hop measured a 0.499 stud peak and returned exactly to its resting height. Deposit effect showed 18 characters at independently staggered X/Y positions and cleaned itself up after 2.5 seconds. It uses actual deposited species. Cash collection has transparent background, green vertical gradient, thick outline and avatar arcs/sparkles. Its rendered text was 42px after fixing a TextWrapped assignment that disabled TextScaled.
- Desktop Index shows Tong Tong first, four columns, discovered portraits and black unknown silhouettes. Portrait phone uses two columns with scrolling. Lucky card has square studs, a 3D gold block, 75/20/5 odds and an earned-cash unlock price. Rebirth badge was visible with sufficient cash and owned tier 6; weighted total for one of each tier was 63.
- iPhone 17 Pro simulation tested landscape and portrait with Sensor orientation/CoreUISafeInsets. Cash moved above the joystick, touch Sprint stays separate, and Index remains readable. Real touch-button activation set server WalkSpeed 24; Shift/dual-Shift release verified 24 → 16. Studio was restored to default viewport.
- Studio layout regression passed: modal feedback remains above the overlay, short-screen cards retain 48px height, and collection text retains automatic sizing/readable bounds.
- Blender mesh/texture imports were inspected in game. The nest's duplicate UV set initially produced checkerboard colors; corrected export contains sole TEXCOORD_0 and now renders brown/gold. All other GLBs were audited for the same issue. Original sources and Roblox mappings are in assets/README.md.
- Independent final code review found no new material defects. Earlier render-yield races, scaled interaction height and weighted leaderboard count findings were corrected.

## Economy and limits

The reproducible [economy audit](ECONOMY_PACE.md) completed real Core rebirth commands. Optimistic active simulation: first merge 30.5s, first tier 6 at 1m58.5s, first rebirth 46m13.5s with queue-driven upgrades. Without upgrades it took 60m38.5s; stopping expansion after tier 6 took 9h27m12s. These are deterministic benchmarks, not observed human retention times. The specified $1m rebirth price and bulk-buy unlocks are preserved, but thousands of manual purchases/merges remain a balance concern.

Persistence, friend boost, real gamepass/product IDs and live publishing are not implemented. Paid offers display Coming soon; prices can come from MarketplaceService once IDs are configured. Finish Now is also pending. Leaders rank only the current server. Asset permissions must be verified for the final experience owner. Real six-client load, low-end physical devices and Mac have not been tested.

No project runtime errors were observed in the tested flows. Studio still reports type-analysis warnings around dynamic Roblox tables/modules; this is not a claim of a warning-free Studio analysis panel. Installed Superpower plugin syntax errors and Roblox FoundationProvider warnings were observed independently of project code. No unrelated plugins were changed.
