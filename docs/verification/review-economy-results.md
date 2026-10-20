# Review economy verification — 2026-10-20

Verified the current working tree locally without invoking Studio or committing changes. This supersedes the economy values and timings in `ECONOMY_PACE.md`; historical runtime/performance captures do not certify this revision.

## Implemented behavior

- The exact reference quantities for tiers 1–9 are 1, 5, 25, 90, 300, 1,100, 4,000, 15,000, and 60,000 Minis per drop. At the one-second base interval these are also the unboosted rates. Tiers 10–25 use an inferred 3.2× progression rounded to the nearest 1,000, reaching 7,249,674,957,000 at tier 25. These later values are our balance choices, not verified Chicken Farm values. Each individual Mini has a $1 base sale value. Cash/rebirth boosts apply to value once; Mini2 doubles raw production; world-event and obby bonuses apply to deposit quantity with fractional carry.
- Deposits multiply the bag quantity by `(eventHundredths + obbyBonusHundredths) / 100`. For example, 5,280 Minis at 1.06× deposit 5,596 Minis and retain 80 hundredths of a Mini. The `depositCarry` integer (0–99) carries the remainder across deposits and multiplier changes, is included in transaction/wire snapshots, and resets on rebirth. Legacy states without the field start at zero. This remains memory-only; no durable player persistence was added.
- Deposit quotes check the expanded queue quantity and reserved cash value before changing the bag or carry. A rejected manual or automatic deposit preserves both. Accepted batches keep their species and base value; cash/rebirth multipliers still apply once per output Mini. Auto Collect/Auto Sell use the same deposit calculation. Successful results and cached replays return `inputCount`, `depositedCount`, and `multiplierHundredths` for the client receipt.
- Producers occupy display slots from highest tier on the left to lowest on the right. Equal tiers keep their previous slot order. Sorting display slots preserves the production scheduler, existing airborne Mini positions, and collectible Mini ownership.
- Production uses counted visual bundles, with the existing limits of 8 bundles per producer, 96 per plot, and 50 producers. The logical bag holds 15,000,000,000,000 Minis and the processor queue holds 37,500,000,000,000. Both Mini2 drops from one top-tier cycle fit the bag, and their 2.5× deposit fits the queue. A full tray still exceeds the bag; bundles that cannot fit remain on the tray.
- Three matching producers merge into one. Every catalog transition preserves or improves combined baseline production. Processor upgrades extend from 2 to 37,000,000,000,000 Minis/second. Rebirth requires tier 6 or higher; Buy100 uses rebirth-based tiers capped at tier 6 and automatically merges before the capacity check.
- Lucky rewards share one distinct 75%/20%/5% pool between the server and UI. At the upper limit the pool becomes tiers 23/24/25. Prices follow the actual lowest reward production rather than the obsolete doubling formula. With one producer, the basic tier-2 pool remains $50, the tier-6 pool costs $11,000, and the top pool costs $7,079,760,700,000: ten base seconds of the lowest reward output. Producer-count scaling remains in place. Tests cover every pool, stale-price rejection without mutation, and successful replay without another charge or roll.
- Curved conveyor motion uses the same trajectory for server pickup and client rendering, including rotated plots. The tested logical centers clear the red belt facets by more than 0.3 logical studs.

## Local checks

Economy/merge checkpoint before the concurrent final UI/ground edits: all 55 standalone non-Studio Luau tests pass, all 12 CLI harnesses pass, and all 207 Luau files compile. The obsolete tutorial fixture now supplies three matching producers. The Lucky price test first failed against the stale doubling curve, then passed after switching to actual production, including every probability boundary, stale-price rejection, and replay without a second charge or roll. Targeted economy analysis returned no diagnostics. The leaderboard harness now runs the actual GroundSurface module with both missing-template fallback and imported-mesh stand-ins. After the subsequent front-pillar and concurrent UI/ground edits, all 207 files still compile; the latest full run is 54/55 standalone tests and 10/13 CLI harnesses. Remaining failures at that instant: old text expectation in `multiplier-cue.luau`, new-constructor mocks in `home-layout-cli.ps1` and `touch-cue-cli.ps1`, and a generated-file parse error in the newly added `ground-surface-cli.ps1`. Those owners are updating their fixtures. The pillar and leaderboard harnesses pass. Counts below record earlier verification passes.

After the deposit multiplier and descending producer-order changes, all 52 executable non-Studio Luau tests passed; all 197 Luau files under `src`, `tests`, and `tools` compiled. Analysis of `FarmCore`, `Economy`, and `ProductionInfo` returned no diagnostics. The new deposit regression covers 0.50×, 1.06×, and maximum 2.50× conversion, fractional carry across multiplier changes and snapshot restore, replay receipts, mixed values, capacity/wallet rollback, automated sales parity, and expiry at the exact server timestamp. Producer-order tests cover purchases, manual/automatic merges, Lucky rewards, restored state, stable ties, and pickups after rearrangement.

| Check | Result |
|---|---|
| Executable non-Studio Luau tests, including capacity benchmark | 51 passed, 0 failed on processor rebalance pass |
| PowerShell CLI harnesses | 9 passed, 0 failed |
| Luau bytecode compilation across `src`, `tests`, and `tools` | 191 files, 0 failures |
| Luau analysis of changed pure economy, motion, targeting and domain modules | No diagnostics |
| Actual Conveyor controller with numeric geometry stand-ins | Curved-slide pickup/render agreement across rotated plots |
| Actual FarmUI/Cue/Sprint layout harness | 2,163 desktop layouts and 12 touch sizes across tested states |

The CLI harnesses cover conveyor visibility/lifecycle, deposit effects, shelf structure, farm actions, Home/layout, hub native studs, leaderboard faces, touch cues, and touch layout lifecycle. Compilation checks syntax/bytecode generation; it does not validate Roblox assets, native rendering, or engine behavior.

Updated obsolete Studio fixture expectations for per-tier Index rates, removed lighthouse/silo/pass placeholders, moved pads, collidable tray/chute geometry, and counted Mini bundles. These fixtures compile but **were not executed in Studio in this verification pass**.

## Processor price rebalance

The throughput ladder now runs from 2 to 37,000,000,000,000 Minis/second across 57 upgrades. The first two upgrades remain $10 and $30. Later prices now grow with current throughput: 7, 8, 9, 10, 11, then at most 12 seconds of current processor earnings at $1/Mini. Previously, price growth outpaced the earning rate and created waits of up to 32.6 minutes for a single upgrade.

`tools/simulate_processor_balance.luau` compares every level against the previous prices. Earning time means price divided by current throughput; incremental payback means price divided by the extra throughput. Both assume a continuously full backlog, baseline value, and no boosts.

| Upgrade (Minis/sec) | Previous price | New price | Earning time, before → after | Incremental payback, before → after |
|---|---:|---:|---:|---:|
| 10 → 18 | $90 | $70 | 9 → 7 sec | 11.25 → 8.75 sec |
| 31 → 52 | $750 | $279 | 24.19 → 9 sec | 35.71 → 13.29 sec |
| 52 → 90 | $2,000 | $520 | 38.46 → 10 sec | 52.63 → 13.68 sec |
| 700 → 1,200 | $120,000 | $8,400 | 171.43 → 12 sec | 240 → 16.8 sec |
| 128,000 → 216,000 | $250,000,000 | $1,536,000 | 1,953.13 → 12 sec | 2,840.91 → 17.45 sec |
| 24,000,000 → 42,000,000 | $30,750,000,000 | $288,000,000 | 1,281.25 → 12 sec | 1,708.33 → 16 sec |

The original 31 upgrades now have a maximum incremental payback of 18 seconds at full utilization. Total upgrade spend drops from $80,272,220,130 to $699,499,083. Ideal sequential earning time drops from 24,722.91 to 344 seconds; this is **not** a time-to-max prediction, because it excludes producer acquisition, travel, collection, and limited supply.

The new `tests/processor-balance.luau` exercises all 57 levels through real bounded-bag deposit, sale, claim, and upgrade commands: earned funds cover the quoted price, a live queue accelerates to the new rate, replay does not charge twice, and sale value is counted once. It initially failed on the old price curve, then passed after the Config-only pricing change. The initial processor-only non-Studio suite passed 51/51; the later production/three-to-one migration is verified separately below. Targeted compilation and analysis of Config, the regression, and the pricing benchmark passed. The nine CLI harnesses and 191-file compilation listed above are from the preceding full review pass, not a new engine validation.

## Active-player simulation

Re-ran `tools/simulate_progression.luau` against the actual FarmCore commands and current configuration. It assumes baseline production, no Lucky rewards or paid boosts, fixed two-second travel legs, 0.8-second repeated-buy movement, aura pickup, merging, and affordable processor upgrades. Travel is a simulation assumption, not a measured walkthrough of the changed map.

| Milestone | Elapsed |
|---|---:|
| Tier 2 | 00:37.05 |
| Tier 3 | 01:16.65 |
| Tier 4 | 02:49.15 |
| Tier 5 | 04:14.15 |
| Tier 6 | 08:49.70 |
| First rebirth | 09:44.05 |

At first rebirth with the exact reference quantities and three-to-one merges: 268 purchases, 131 merges, 95,801 collected Minis, $83,569 gross claimed revenue, eleven processor upgrades costing $20,283, zero deposit-capacity waiting, 139.25 seconds at the global ground cap, and 368 cached transaction requests.

Historical runs used different merge rules: the old two-to-one curve reached rebirth in 10:20.40, and reducing processor prices alone brought that to 8:43.50. The current 9:44.05 three-to-one run is not an isolated price comparison. Its long periods at the physical tray cap show that travel and collection cadence remain meaningful bottlenecks. The model uses single purchases and does not exploit Lucky rewards or Buy100.

## High-tier precision and capacity

The wallet cap is 8,000,000,000,000,000 quarter-dollar units. A full queue at maximum cash8/rebirth20 reserves 7,200,000,000,000,000 units, below that cap. Bag quantity ×250 plus fractional carry, every cash product, and every accepted wallet/queue/deposit reserve remain below the exact-integer limit of 2^53. An oversized prospective sum may exceed that limit, but is then necessarily above the lower wallet cap and rejected; it is never committed. Boundary tests accept exactly the cap and reject one quarter-dollar above it. This changes logical limits only; physical instance caps are unchanged.

The all-tier regression produces, collects, deposits, and values actual Mini2 drops at maximum event/obby/cash/rebirth boosts. It verifies exact quantities through snapshot transport, including a 36,248,374,785,000-Mini top-tier deposit. A separate odd large-quantity case verifies fractional carry without rounding loss. All 57 processor upgrades are earned through bounded bags and checked for queue acceleration and retry safety.

## Pending visual integration checkpoint

Blender ground tiles, trees, sky, refreshed UI icons, and the widened plot are still being integrated and require a final native Studio pass. The brown leaderboard panels are wired to GroundSurface and pass the CLI integration checks, but that is not a rendered-art approval. Stacked front-row pillars are implemented: eleven narrow gold, collidable posts per upper row, forty-four maximum. The actual-generator CLI verifies floor-to-underside contact, at least 4.8 logical studs of clearance from each producer/drop center, native stud faces, all 221 original row parts unchanged, and 1,161 total parts for five rows. Native appearance and collision still need Studio verification. The updated native Lucky appearance fixture checks the current three distinct rewards and shared scaled price, but has only been compiled locally.

## Remaining limits

- Native R6/R15 carry appearance, input responsiveness under real replication delay, mesh import/rendering, collision walking, and updated Studio fixtures still require runtime verification.
- The full 25-tier progression and stochastic Lucky/event pacing have not been calibrated through a complete player run. The deterministic benchmark covers first rebirth only.
- The maximum processor exceeds one tier-25 producer with Mini2 and the maximum 2.5× deposit bonus (36,248,374,785,000 Minis/sec). Multiple top-tier producers and travel between pickup/deposit can still outpace collection and finite bag/queue limits. Nominal processor throughput is not a guaranteed sustained player income.
- Pure CPU capacity timings are diagnostic, not evidence of client FPS, mobile performance, multiplayer scalability, or memory recovery. Existing physical model caps remain unchanged.
- Persistence and configured monetization remain outside this patch; preview progress remains memory-only.
