# Reversible Studio capacity comparison

Current execution status: [overnight handoff at 06:45 UTC](../docs/verification/OVERNIGHT_HANDOFF.md) and [progress JSON](../docs/verification/OVERNIGHT_PROGRESS.json). The working tree now sets **GroundCap=96 as a candidate, with Slots=50 retained**. Root has deliberately re-entered the isolated harness: both production Main scripts are temporarily disabled, optimized Conveyor/AnimationVisibility sources are synced, and the 60-second settled and 600-second churn samples are complete. Equivalent-state memory recovery, the normal-game tray walk, cleanup, and final capacity acceptance remain pending.

This harness compares **six farms × 50 producers / 50 Minis** with **six farms × 50 producers / 96 Minis**. The harness itself derives trial configuration without editing production Config; the separately authorized local candidate change is described above. Each farm has the same ordered mixture of all six species, including Crocodilo, five producer shelves, and an initially full settled pile. Setup uses actual FarmCore production and validated commits; churn uses real Auto Collect/Auto Sell and World.render.

Historical fixed-source baselines are [capacity-50-raw.json](../docs/verification/capacity-50-raw.json) and [capacity-96-raw.json](../docs/verification/capacity-96-raw.json), both from `70786a3`. They precede the later map/UI/obby and scheduling batch. Do not label an optimized run with that old source commit; save its exact revision/working-tree provenance and keep source fixed throughout sampling.

The saved [optimized 96-Mini trial](../docs/verification/capacity-96-optimized-raw.json) identifies its reviewed working-tree source and includes settled, churn, `serverWholeTrial`, and recovery-start data. Churn mean Conveyor work is 2.1227 ms versus 4.3282 ms (about 51% lower), while mean frame time is 17.045 versus 16.982 ms and maximum frame time is 185.385 versus 166.535 ms. Frame p95/p99 are 18.00/25.50 versus 18.25/27.75 ms. This does not establish an overall FPS gain. Generated-world Instances stay at 39,749, but client memory rises 159.60 MB; a recovery endpoint is still required. The server summary covers 841.37 seconds, not exactly the client churn window. The reviewed lighthouse cull is not installed in this sample.

## Install only for a temporary Play session

1. Record the current `Disabled` state of `ServerScriptService.Main` and `StarterPlayer.StarterPlayerScripts.Main`. Disable both **before starting Play**. This prevents duplicate world generation, conveyors, HUD, audio and network handlers.
2. Sync the current production sources, including `Conveyor.destroy()`, `DisplayShelves`, all six character/Mini meshes, and map dependencies.
3. Install `tests/CapacityHarnessScenario.luau` as the ModuleScript `ServerScriptService.CapacityHarnessScenario`.
4. Install `tests/studio-capacity-harness.server.luau` as a server Script. It creates controls but does not start the population automatically. Install `tests/studio-capacity-harness.client.luau` as a LocalScript in `StarterPlayerScripts` before Play, or the current player's `PlayerScripts` during Play.
5. Start Play. The server refuses to replace an existing generated world or coexist with FarmNetwork. Keep the avatar stationary during measurements. Use the same client count, graphics quality, viewport size, mesh/streaming settings and machine for both variants.

The files under `tests/` are not included in `default.project.json`; do not add them to the shipped Rojo tree.

## Run from server/client contexts

Server commands return immediately; initialization and simulation run in a background task.

```luau
local control=game.ServerStorage.CapacityHarnessControl
control:Invoke('start',50)
-- Poll until Status == "Ready"; do not sample setup or replication warmup.
control:Invoke('counters')
```

Client:

```luau
local control=game.Players.LocalPlayer.PlayerGui.CapacityHarnessClientControl
control:Invoke('start','farm1')
```

Allow at least ten seconds after server Ready, and confirm the client inventory sees **300 producers / 300 Minis** (or **576 Minis** at cap 96). Wait for mesh loading and stable counts. The camera stays scripted at FOV 60. Available views are `farm1` through `farm6`, `overview`, and `route` (the same smooth 60-second circuit through all six farm views).

```luau
-- Client: returns immediately; poll counters until SampleStatus == "Complete".
control:Invoke('sample',{seconds=60,camera='route'})
control:Invoke('counters')
-- Full inventory is expensive: request only outside active samples.
control:Invoke('counters',true)
```

`lastSample` includes frame mean/max/p50/p95/p99, Conveyor work time, memory before/after, model/part inventories, and received snapshot counts. A camera, capacity, churn, snapshot setting or server lifecycle change cancels an active sample. Percentiles use fixed 0.25 ms histogram bins to avoid measurement-memory growth; frames above 128 ms use the observed maximum for the overflow percentile. Exact mean/max remain available. Existing `studio-capacity-profile.client.luau` is a separate ten-second check if exact sampled percentiles are needed.

Server:

```luau
control:Invoke('churn',true)
-- Poll until Status == "Churning", allow one 5-second fill/collect cycle,
-- then run the same client sample, camera route and duration.
control:Invoke('counters')
```

Run at least ten minutes of churn for each cap when evaluating growth. The server exposes ticks, rendered farm updates, created/removed Minis, snapshot entities, wall time spent on each simulation/render/network tick, heartbeat intervals and server memory. Its timing rings are preallocated and bounded to the last 2,400 work samples and 36,000 heartbeats. Server summaries cover the whole trial since Ready; use equal warmup and measurement durations. Detailed `counters(true)` performs an inventory scan and should be called between samples. While a sample runs, poll the lightweight `ReplicatedStorage.CapacityHarness` attributes and client `counters()`; defer server `counters()` (which sorts timing distributions) until the sample ends.

Disable churn, wait at least eight seconds and confirm the full population returns before comparing the settled memory/inventory again:

```luau
control:Invoke('churn',false)
control:Invoke('counters',true)
control:Invoke('stop')
-- Wait until Status == "Stopped", then:
control:Invoke('start',96)
```

Starting the next variant clears/reseeds farm actors while reusing the same authored world. Repeat the same warmup, fixed and route samples, churn duration and settled return. Prefer an A/B/A sequence (50 → 96 → 50) to expose warm-cache or temperature drift. A stopped server trial freezes simulation and keeps its scene available for inspection.

One representative farm snapshot is sent to each connected client on that farm's updates, matching the normal ownership shape. Six farms still simulate and replicate their world instances. The client stores the latest snapshot but does not render the production HUD. `control:Invoke('snapshots',false)` disables these test remotes for a separate rendering-only experiment; keep that setting identical across compared runs. Use Studio's performance/network counters for actual traffic rather than treating entity counts as byte estimates.

## Cleanup

1. Client: `CapacityHarnessClientControl:Invoke('destroy')` disconnects RenderStepped, snapshot and lifetime signals, calls real `Conveyor:destroy()` (including tags and tier accents), and restores the previous camera state.
2. Server: `CapacityHarnessControl:Invoke('destroy')` stops the background task at a safe checkpoint, destroys the test world and controls, restores the saved Lighting/water properties, and restores the terrain voxel region modified by World.build. Poll for the controls to disappear. [Terrain CopyRegion/PasteRegion](https://create.roblox.com/docs/reference/engine/classes/Terrain) supplies that reversible terrain snapshot.
3. Stop Play, remove the temporary test scripts/module, and restore both Main scripts to their recorded `Disabled` values. Check that normal gameplay starts with one world and one conveyor controller.

No player economy is loaded, no DataStore is used, and the harness itself does not edit passes or production capacity. The local GroundCap=96 candidate is an independent source change under evaluation. Do not run the harness in an active ordinary game session.

## Interpretation and limitations

This isolates world simulation, replication, Mini/producers, shelves and the production Conveyor/TierEffects client. It excludes the production HUD, audio, purchase commands, six real users' movement, player-owned inventory UI work and platform/device differences. One Studio client cannot certify six-device networking or low-end performance. Loading/build time is intentionally outside steady-state samples. Fixed mixed-tier farms are reproducible but are not an all-Crocodilo worst-case scene.

Inspect the collection pile and walk the tray manually in a separate normal-game QA pass before promoting a cap; this harness's scripted camera and automatic collection do not prove every real pickup route. The current 50-producer/96-Mini local configuration remains a candidate until longer comparable measurements, equivalent-state memory recovery, device limitations, and gameplay QA are assessed. Do not call the candidate final solely because a one-client settled sample passed.

Pure population validation:

```powershell
& '.tools/luau/luau.exe' 'tests/capacity-harness-scenario.luau'
```
