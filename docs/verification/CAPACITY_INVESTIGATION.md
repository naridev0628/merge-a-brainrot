# Capacity investigation — 2026-10-20

The user authorized reconsidering the 50-producer / 50-Mini limits. This investigation keeps the shipped limits unchanged while separating simulation, rendering, and collection throughput. It adds one bounded client optimization and a reproducible pure simulation probe.

## Implemented optimization

`src/shared/MiniNeighborIndex.luau` indexes landed Mini centers in two-world-stud spatial cells. `src/client/Controllers/Conveyor.luau` builds the index only when a fresh landing needs its contact animation, reuses it for the rest of that frame's arrivals, and discards it afterward. Repacking therefore cannot leave stale positions in a persistent index. It retains the original strict distance check, landing order, stale-arrival suppression, and authoritative pickup centers.

Previously, every fresh arrival scanned every tagged Mini on every farm. Exact-membership tests compare the new query results with an independent brute-force distance check over six separated farms:

| Total Minis | Old candidate checks | Spatial candidate checks | Reduction |
|---:|---:|---:|---:|
| 300 | 90,000 | 4,740 | 94.7% |
| 600 | 360,000 | 16,494 | 95.4% |
| 1,200 | 1,440,000 | 36,804 | 97.4% |

These are deterministic candidate counts for the test layout, not measured FPS gains. The spatial index still performs an initial linear scan of landed Minis when a landing occurs.

## What the two current caps actually control

- `Config.Slots` caps simulated producers and the displayed producer models. Every ten producers adds another shelf row. No producer proxy or separate rendering cap exists.
- `Config.GroundCap` caps all ordinary Mini tokens together, including airborne tokens during the four-second conveyor journey. Every token is also represented by a replicated world model. There is no separate simulation/rendering cap.
- Bag and processor queue counts already use compact batches; increasing those counts does not instantiate another object for each good.
- Lucky Blocks have a separate one-active-block limit.
- `FarmController` and `RenderLoop` are not source files in this project. The actual paths are `FarmCore`, `WorldBuilder`, `Main.client`, and `Controllers/Conveyor`.

Increasing producer count alone does not fix a full conveyor budget. With Auto Collect, arriving tokens occupy capacity until their journey completes. Production runs before automatic collection inside the server step, which also affects the observed cycle.

## Pure simulation probe

Run:

```powershell
& '.tools/luau/luau.exe' 'tests/capacity-benchmark.luau'
```

The probe uses six independent sessions, 40 simulated seconds at the actual quarter-second cadence, tier-one producers, Auto Collect/Auto Sell, maximum processor level, and no Lucky rolls. It includes changed-state snapshots, verifies state validity and capacity, and separately inspects a full resting pile. Results from the final local run:

| Producers / Minis per farm | Six-farm average CPU per tick | Peak tick | Delivered Minis/s/farm over 40 seconds | Full pile top, logical studs | Reachable from center aura |
|---|---:|---:|---:|---:|---:|
| 50 / 50 | 1.019 ms | 4.716 ms | 10.00 | 5.3 | 50 / 50 |
| 50 / 96 | 2.103 ms | 7.691 ms | 18.05 | 7.3 | 96 / 96 |
| 50 / 100 | 2.104 ms | 6.232 ms | 18.75 | 9.3 | 100 / 100 |
| 50 / 200 | 4.907 ms | 10.637 ms | 36.25 | 17.3 | 200 / 200 |
| 100 / 50 | 1.371 ms | 5.385 ms | 10.00 | 5.3 | 50 / 50 |
| 100 / 100 | 2.451 ms | 9.169 ms | 20.00 | 9.3 | 100 / 100 |
| 200 / 100 | 3.486 ms | 13.165 ms | 20.00 | 9.3 | 100 / 100 |
| 200 / 200 | 6.633 ms | 12.650 ms | 40.00 | 17.3 | 200 / 200 |
| 200 / 300 | 10.724 ms | 19.982 ms | 57.50 | 25.3 | 244 / 300 |
| 500 / 200 | 11.324 ms | 35.334 ms | 40.00 | 17.3 | 200 / 200 |

Timing varies with the host and garbage collection. An earlier run had a 52.070 ms peak at 100/100; it must not be hidden by the lower subsequent peak. These numbers exclude Roblox rendering, physics, instance creation, attribute replication, network serialization, UI work, and actual device performance. Forty-second delivery rates include startup and the final partially delivered wave.

The 300-Mini pile is already too tall for the existing centered pickup aura to reach every resting Mini at once. Removing lower Minis would repack the pile, but that is a different player experience and requires deliberate design.

## Rendering costs that remain

1. **Shelves dominate native instance growth.** The current WorldBuilder loops create approximately 1,021 Parts per ten-producer row, including studs and trim. Six full 50-producer farms therefore use approximately 30,630 shelf Parts. Raising producers to 100 approximately doubles that to 61,260, before any characters, map scenery, or tokens. Root's ongoing map edits may change this count; measure the resulting Studio hierarchy before changing producer capacity.
2. **Imported creatures use one MeshPart each, but geometry is substantial.** Checked-in asset statistics list main models from 4,240 to 10,002 triangles and Minis from 996 to 2,838. A six-farm all-Crocodilo 50/50 population represents about 3.85 million source triangles before map geometry; 100/100 would represent about 7.70 million. These totals are source geometry, not rendered triangle counts after visibility or engine LOD.
3. **All tagged producers animate every client frame.** Tier accents already cap themselves to 16 nearby producers at 10 Hz, but producer sways and Mini motion do not have distance scheduling. Settled Minis avoid repeated `PivotTo`, yet still read attributes and evaluate their motion state.
4. **World models churn as goods are produced and collected.** Server rendering clones each new Mini and destroys each collected one. Lifetime pooling may help instance creation but will not itself reduce live geometry, remote replication, or the data snapshots.
5. **Full state snapshots scale with entity count.** The pure probe reports copied entity totals to make this visible. It does not estimate packet bytes.

## Recommended next capacity experiment

Start with **50 producers / 96 Minis**, after the spatial-index Studio regression passes. This preserves five producer rows and fits four complete 24-position tray layers. In the pure probe it raises automatic delivery from 10.00 to 18.05 Minis/s/farm over 40 seconds, while keeping all resting Minis inside the current center aura. Its top layer is only two logical studs above the current 50-token pile.

This is a justified runtime test target, not a claim that 96 is already safe on every device. Before promoting the configuration:

- Populate all six farms with 50 producers and 96 mixed-tier Minis; include the highest-triangle species.
- Record client frame-time distribution, server heartbeat time, total instances, memory, and network traffic during repeated production/collection for at least ten minutes. Compare with the same camera route and population at 50/50.
- Verify no monotonic instance or memory growth across repeated fill/collect cycles and returning to the same settled state.
- Walk the full tray perimeter and collect from the center; verify pickup counts, authoritative repacking, bag/queue totals, and no hidden production backlog.
- Run the existing pure suite and grounded producer, pad, and conveyor Studio fixtures. Generalize tests that explicitly encode fifty ordinary Minis; retain producer-cap assertions while that cap remains fifty.
- Compare a low-end device or an appropriately constrained client before claiming a release capacity.

For a later producer increase, first move the shelf generator into a bounded reusable module and reduce decorative Parts per bay without shrinking the visible stand or losing the reference silhouette. Then add distance scheduling for cosmetic sways, settle checks, and nameplates. A more ambitious design could separate simulated goods from a bounded set of client-rendered proxies, but that changes pickup representation and replicated state and requires its own design and regressions.

## Verification state

- The neighbor-index test was observed failing for missing neighbors before implementation, then passed.
- All 23 standalone behavior test files passed, including the new exact-neighborhood suite.
- The ten-scenario capacity probe passed its state, cap, throughput-progress, and pile-construction checks.
- New/changed Luau files compile.
- `tests/studio-mini-neighbors.client.luau` is provided for live checks of contacts, distant farms, repacking, stale arrivals and the strict radius. It was compiled but has not been run by this subagent, which did not mutate Studio during the root agent's map QA.
- `tests/studio-capacity-profile.client.luau` provides a read-only ten-second client sample: frame-time percentiles, memory before/after, live producers/Minis, and total/shelf/character Parts. It does not alter population, camera, settings, or game state. Use repeated comparable samples as part of the longer soak; a single sample is not certification.
- No capacity constants were changed.
