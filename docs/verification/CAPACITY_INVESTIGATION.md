# Capacity investigation — 2026-10-20

Current pointer: [overnight handoff, 08:16 UTC](OVERNIGHT_HANDOFF.md) and [progress JSON](OVERNIGHT_PROGRESS.json). **GroundCap=96 may remain in the Studio preview; Slots=50 is retained.** Latest committed/pushed source is `0059fb2`, with PR 2 open/draft/unmerged. The synced canopy/hub/packet batch is natively verified but uncommitted: all **79 local/Studio sources match with zero mismatches at 08:15:56 UTC**, and **79 source files compile, 43 standalone Luau files, Rojo build, and diff checks pass**. Normal Play is restored with server Main enabled, zero producer/Mini tags, HUD enabled, camera Custom, temporary packet folder removed; Main State/HUD smoke reports coinUnits=20 and zero producers/Minis. The benchmark below measured earlier fixed source, not complete `0059fb2` or this batch. Memory growth remains unresolved; device, multiplayer, worst-case species, and longer-duration limits remain.

The initial investigation below is a **historical record**. It left both caps at 50 and added the spatial-neighbor optimization and pure simulation probe. The measured shelf refactor used **221 Parts per row / 6,630 across six full farms**. The new rear joins add only 12 Parts per full plot: current rows use **221 / 224 Parts**, or **6,702 across six full farms**. Native one-live/five-isolated-row checks and saved one/two/five-row views pass; the recorded benchmark inventory is unchanged. `Conveyor` already has cheap settled handling plus conservative offscreen scheduling through `AnimationVisibility`. Original baseline tables are retained as evidence, not descriptions of the current source.

Saved-image persistence was repaired from the original retained captures: 11 truncated JPGs were replaced, and root verified all 13 verification JPGs decode at 1759 × 567. This includes the original normal-flow capture; no new gameplay run, capture-date change, or benchmark-provenance change occurred.

Completed source-`70786a3` Studio baselines are saved in [capacity-50-raw.json](capacity-50-raw.json) and [capacity-96-raw.json](capacity-96-raw.json), with 60-second settled and 600-second churn samples for each. The later reviewed working-tree run is saved separately in [capacity-96-optimized-raw.json](capacity-96-optimized-raw.json). Its 60.0038-second settled sample has mean frame 16.6862 ms, p95 17.75 ms, p99 19.25 ms, maximum 51.385 ms, and mean Conveyor work 0.377916 ms versus the prior 1.810442 ms.

The optimized 600.0109-second churn reduced mean Conveyor work from 4.3282 to **2.1227 ms**, about **51%**, with frame p95 18.00 versus 18.25 ms and p99 25.50 versus 27.75 ms. Mean frame time was 17.045 versus 16.982 ms, and the maximum was 185.385 versus 166.535 ms, so this is not an overall FPS improvement. Both inventory endpoints retained **576 Minis / 35,279 Parts / 39,749 Instances**. Client memory rose from **3549.367 to 3708.969 MB (+159.60 MB)**; stable instance counts do not resolve that growth.

The saved `serverWholeTrial` spans 841.37 seconds and records 88,428 Minis created and removed. Its bounded timing rings and whole-trial totals are not a matched 600-second server comparison. Absolute memory levels reflect different preceding machine/session history. The one-client benchmark excludes HUD/audio, ordinary player commands, six real clients, and low-end device performance. The later 365-stud lighthouse cull was excluded from this fixed-source benchmark; the 557-stud hub cull was included. The lighthouse's separate native fixture now passes: 744 → 379 Parts, with 328 visible studs, 51 body Parts, and 22 colliders retained. Do not subtract this later change from the recorded benchmark inventories.

After disabling churn, `recoveryStart` and `recoveryEnd` span **186.7438135 seconds** at the same full population with the camera route continuing. Total memory changed **3725.58203125 → 3728.33984375 MB (+2.7578125 MB)**. Global Instances stayed **89,116**, generated-world descendants stayed **39,749**, and Mini/producer counts and unique asset IDs stayed unchanged. This does not show return to the pre-churn memory level or establish that growth is leak-free. The separate **60.0013498-second settled-return sample** measured mean frame **16.662266 ms**, p95 **17.75 ms**, p99 **18.25 ms**, maximum **30.247699 ms**, and mean Conveyor work **0.383178 ms**. Its total-memory endpoints were 3730.09765625 → 3728.87890625 MB. Frame/work recovery is established for that sample; full memory recovery is not.

The [native tray-walk record](tray-walk-96-raw.json) reports **52.093612 world studs**, five visited waypoints, **96 collected / 96 bag / zero remaining models**, all six species, and a partial pickup that repacked survivors. It used an isolated cloned farm, real imported meshes, a real Humanoid after one staging move, and server pickup contexts from its actual HRP. Production was frozen only in that independent test session; the clone and controls were removed and the character restored. This confirms mixed-species physical collection for the Studio preview, not all-Crocodilo or multiplayer capacity.

The read-only WorldBuilder/Conveyor/TierEffects lifecycle audit found no actionable retained removed-model or connection defect. `studio-memory-snapshot.luau` provides one-shot heap/category/inventory diagnostics without forcing GC or retaining Instances. No new caching or pooling optimization followed from that audit. The subsequent allocation review produced a conservative `Core.step` preflight: **20,160 deterministic old/new steps retained identical state/RNG and avoided 984,048 table copies over the 600-second scenario**, as reported by root. This measures avoided allocations, not native frame time or memory recovery; the earlier raw benchmark results above remain unchanged.

Normal functional coverage now includes [100 deposited, 92 client-observed airborne collections with Lucky held, 88 standing claims, and two upgrades](normal-farm-flow-raw.json) on source `58c7875`, starting with the starter producer after a delayed Buy. The later [fresh Buy retry smoke](pad-retry-smoke-raw.json) passed in 0.6340522 seconds with one `TooFar` then `OK`; the bounded 0.5-second retry preserves immediate entry and held-repeat timing. Updated Lucky server/client fixtures and the shelf join fixture also pass. These functional checks do not expand the benchmark's measured workload. Canopy native checks now pass all six plots at 68 Parts per stall; hub environment and six-route/8,664-check validation pass with 12 extra decorative Parts. Board-face assessment is active; real-camera producer-label readability remains open because the AlwaysOnTop capture is unverified. The 13:30 UTC minimum work cutoff and 15-minute heartbeat remain active.

The new `SnapshotPacket` helper preserves deep transaction snapshots while cloning only the outbound packet root. At 50 producers/96 Minis it avoids **151 nested table copies per send**. Three actual-helper CLI trials of 12,000 envelopes measured deep-copy **2,786.891 / 2,063.966 / 2,053.348 ms** versus **8.308 / 7.541 / 8.333 ms**, avoiding 1,812,000 nested copies per trial. No GC was forced. These measurements exclude RemoteEvent serialization, Studio, GPU, and native memory. The native server/client probe independently passes full 50/96 content, real CFrame, client isolation, metadata, and later Core commit; this is correctness evidence, not a native performance or leak-resolution claim. Existing benchmark metrics/provenance remain unchanged.

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

## Historical rendering costs before the later shelf and scheduling passes

1. **Original shelf estimate, superseded.** The initial WorldBuilder loops created approximately 1,021 Parts per ten-producer row, or 30,630 across six full 50-producer farms. The later verified `DisplayShelves` pass reduced this to 221 per row / 6,630 total. Keep the old estimate only as the starting point; it must not be used as the current inventory.
2. **Imported creatures use one MeshPart each, but geometry is substantial.** Checked-in asset statistics list main models from 4,240 to 10,002 triangles and Minis from 996 to 2,838. A six-farm all-Crocodilo 50/50 population represents about 3.85 million source triangles before map geometry; 100/100 would represent about 7.70 million. These totals are source geometry, not rendered triangle counts after visibility or engine LOD.
3. **Original animation observation, superseded.** At the initial checkpoint, all tagged producers animated every frame and Minis had no distance scheduling. The later working tree adds settled-Mini early exits and conservative offscreen transform scheduling; its native visibility fixture and the optimized benchmark have completed. This schedules cosmetics, not authoritative production or pickup.
4. **World models churn as goods are produced and collected.** Server rendering clones each new Mini and destroys each collected one. Lifetime pooling may help instance creation but will not itself reduce live geometry, remote replication, or the data snapshots.
5. **Full state snapshots scale with entity count.** The pure probe reports copied entity totals to make this visible. It does not estimate packet bytes.

## Original experiment recommendation — runtime trial completed

Start with **50 producers / 96 Minis**, after the spatial-index Studio regression passes. This preserves five producer rows and fits four complete 24-position tray layers. In the pure probe it raises automatic delivery from 10.00 to 18.05 Minis/s/farm over 40 seconds, while keeping all resting Minis inside the current center aura. Its top layer is only two logical studs above the current 50-token pile.

This was the runtime test target and now remains a Studio-preview setting, not a claim that 96 is safe on every device. The original acceptance checklist was:

- Populate all six farms with 50 producers and 96 mixed-tier Minis; include the highest-triangle species.
- Record client frame-time distribution, server heartbeat time, total instances, memory, and network traffic during repeated production/collection for at least ten minutes. Compare with the same camera route and population at 50/50.
- Verify no monotonic instance or memory growth across repeated fill/collect cycles and returning to the same settled state.
- Walk the full tray perimeter and collect from the center; verify pickup counts, authoritative repacking, bag/queue totals, and no hidden production backlog.
- Run the existing pure suite and grounded producer, pad, and conveyor Studio fixtures. Generalize tests that explicitly encode fifty ordinary Minis; retain producer-cap assertions while that cap remains fifty.
- Compare a low-end device or an appropriately constrained client before claiming a release capacity.

The shelf extraction/reduction and initial conservative animation scheduling have since landed locally. The six-farm trials and mixed-species native tray walk above are complete; low-end/multiplayer, worst-case species, and longer memory validation remain open. A later producer increase still needs measurement; Slots remains 50. A more ambitious design could separate simulated goods from a bounded set of client-rendered proxies, but that changes pickup representation and replicated state and requires its own design and regressions.

## Verification at the initial checkpoint

- The neighbor-index test was observed failing for missing neighbors before implementation, then passed.
- All 23 standalone behavior test files passed, including the new exact-neighborhood suite.
- The ten-scenario capacity probe passed its state, cap, throughput-progress, and pile-construction checks.
- New/changed Luau files compile.
- `tests/studio-mini-neighbors.client.luau` was compiled but not run at this initial checkpoint; it subsequently passed in normal Studio Play, as recorded in the current handoff.
- `tests/studio-capacity-profile.client.luau` provides a read-only ten-second client sample: frame-time percentiles, memory before/after, live producers/Minis, and total/shelf/character Parts. It does not alter population, camera, settings, or game state. Use repeated comparable samples as part of the longer soak; a single sample is not certification.
- No capacity constants changed in this initial pass. The later working tree retains GroundCap=96 for Studio preview with the current limitations above; release capacity is not certified.
