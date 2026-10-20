# Overnight engineering handoff — 2026-10-20, 07:50 UTC

This is a live work checkpoint, not a completion or release report. The minimum work window continues until **13:30 UTC**. The continuation heartbeat now runs every **15 minutes**, as reported by root. See [machine-readable progress](OVERNIGHT_PROGRESS.json) for the current task pointer.

## Current Studio state

The temporary capacity harness and previews are **fully removed** and **both production Main scripts are enabled**. Root inspected and saved the final blue/white-cap Lucky capture, then restarted Play. The server confirms **zero `BrainrotProducer` / zero `ConveyorMini` tags**; the client has **BrainrotHUD enabled**, **CameraType.Custom**, and no `OvernightNormalFarmFlow` test script. No temporary world or tray fixture remains. The prior batch is **committed as `58c7875` and pushed to `origin/codex/stacked-brainrot-farm`**; PR 2 remains open, draft, and unmerged. The new gameplay/allocation/Lucky/shelf batch is **verified and ready for root's commit, but uncommitted**. The benchmark below retains its earlier fixed-source provenance; it measured neither the complete `58c7875` build nor this new batch.

Root compiled all **78 source files**, passed **42 standalone Luau test files**, the actual-generator shelf CLI check, Rojo build, and whitespace checks. [Studio source verification](studio-source-verification.json), recorded at **07:39:58 UTC**, reports **78 local / 78 Studio project scripts and zero mismatches**, after CRLF normalization and excluding engine-injected scripts. The current compact record uses `localCount` and `studioProjectCount`; the earlier 76-file verification belongs to the prior batch.

The optimized 60-second settled, 600-second churn, and 60-second settled-return samples are saved, together with recovery-start/end memory snapshots. The snapshots span 186.744 seconds at the same full population while the camera route continued. Total memory stayed elevated; this is not full memory recovery or a resolved-leak finding. Later lighthouse and multiplier-cue work is outside the benchmark's fixed source.

**GroundCap=96 may remain in the Studio preview**, while **Slots=50 is retained**. The six-farm benchmark and actual-character pickup pass support that preview setting. Multiplayer, physical-device, worst-case species, and longer memory behavior remain unvalidated. Nothing has been published.

## Completed normal-play QA

The first isolated harness was cleaned up, both Main scripts were enabled, and normal Studio Play was restored. Root synced 26 production modules for this pass.

All nine map fixtures passed:

- `studio-hub-stud-occlusion.server.luau`: 557 fully hidden hub studs removed; 1,480 visible/partial studs and nine collision slabs retained.
- `studio-conveyor-wheat.server.luau`: two five-stalk gold accents per plot; tree, pad, and belt clearance; facade budget retained.
- `studio-conveyor-facade.server.luau`: six facades clear producer bays, pads, red surfaces, and Mini trajectories.
- `studio-environment.server.luau`: identical plot decoration, clear gameplay zones, 30 lilies, and three rock islands.
- `studio-hub-routes.server.luau`: six clear approaches and 10,782 prop-clearance checks.
- `studio-farm-landmarks.server.luau`: bounded foundations, guarded silo bays, and clear pads.
- `studio-mirrored-plot.server.luau`: mirrored utilities, enlarged stall, continuous red conveyor, and closed front fences.
- `studio-bridge-grounding.server.luau`: six visible landings with walkable seams.
- `studio-obby-course.server.luau`: exact landing footprints/tops, clear jump approaches, readable numbers/reward, and fewer than 140 parts.

Root also reported passing UI/layout, capacity-hint, settings, obby-HUD, reveal-lifecycle, Conveyor idle/lifecycle, and Mini-neighbor fixtures. The new native `studio-conveyor-visibility.client.luau` fixture passed before the optimized measurement.

The actual Humanoid route passed all ten checkpoints and received the server finish award. The initial driver needed `ChangeState(Jumping)`; the successful run used real jumps after one setup teleport, default speed 16, and JumpPower 50. [Raw obby evidence](obby-playthrough-raw.json) records the earlier 06:29 UTC run and final bonus 25/cooldown packet. Root has now rerun the updated driver successfully in fresh normal Play. Root separately verified that Home preserves the awarded bonus; the fresh rerun and Home check are reported evidence, not new records in that earlier raw route file.

The [actual-character tray walk](tray-walk-96-raw.json), recorded at **06:54:52 UTC**, passed with **96 collected, 96 in the bag, zero remaining token models, all six species, and partial-pile repacking**. The Humanoid walked **52.0936 world studs through five waypoints** after one staging move. Server `CollectNearby` contexts came from the actual HRP; the isolated cloned farm and Core session were removed afterward. This exercises native collision/movement and collection without advancing the normal farm session. It is a mixed-species test, not an all-Crocodilo or multiplayer acceptance.

The world Mini-multiplier change cue is integrated into Main and passed native replay suppression, expiry, phone/short layouts, pickup/Lucky/Settings coexistence, and teardown checks, as reported by root.

The native pad-affordability fixture passed all assertions. The [production-controller pad-entry smoke](pad-entry-smoke-raw.json) bought the first producer **0.2654108 seconds after local foot entry** without a direct Buy command. Three `TooFar` responses during staging replication preceded `OK`; this is a single observed Studio smoke result, not a latency guarantee. An earlier movement target stopped outside the pad corner; moving the driver target reliably inside resolved that setup issue without a production change. The current Play was restarted afterward and is fresh.

PadLabels now passes its native fixture for all **15 local labels**, near/distance behavior, quote updates, hierarchy, geometry preservation, and teardown. The first fixture copied an already-managed source; correcting it to use an unmanaged plot then exposed a real `TextWrapped` cleanup omission, now fixed by capture/restore. [Before](fresh-hud-pad-spacing.jpg) and [after](pad-labels-after.jpg) show separated Buy costs. Auto Collect remains hidden while occluded by Merge and becomes readable on approach.

## New verified batch, awaiting commit

The [normal farm interaction route](normal-farm-flow-raw.json), recorded at **07:30:29 UTC on source `58c7875`**, passed with **100 Minis deposited, 92 client-observed all-flight collection events while Lucky was held, 88 standing `Claim OK` responses, and two `Upgrade OK` responses**. The card remained visible and nonmodal ([capture](normal-flow-lucky-held.jpg)). The route started with the starter producer: an earlier four-second Buy attempt had timed out after 14 `TooFar` responses and purchased later. This is a successful gameplay route, not a fresh-entry result, and predates the new retry, preflight, and Lucky visuals.

`PadHold` now bounds a `TooFar` retry to **0.5 seconds**, replacing the repeated reset that could retry at 20 Hz. Immediate entry and the existing two-second initial hold / half-second repeat remain intact; pure limiter checks and peer review pass. The separate [fresh Buy smoke](pad-retry-smoke-raw.json) passed at **0.6340522 seconds after local entry**, with one `TooFar` then `OK`. Server trace Z was **46.655 outside** on the first attempt and **55.349 inside** on success. This demonstrates the replication-boundary retry path in one Studio run, not a latency guarantee.

`Core.step` now checks conservatively whether a step can change state before copying it. The deterministic comparison passed **20,160 old/new steps with identical state and RNG**, avoiding **984,048 table copies over the 600-second scenario**, as reported by root. This is allocation-count evidence, not a new native FPS or memory result; the earlier churn/recovery evidence remains unchanged.

Lucky presentation now uses gold **Basic** for `baseTier <= 2` and blue for valid `baseTier >= 3`, consistently across ground block, held block, and card. This mapping is our adaptation; prices, odds, drops, and nonmodal behavior are unchanged. Blue blocks add **36 decorative Parts: 28 question-mark runs and eight white corner caps**. Updated server and client native fixtures pass. Root inspected and saved the final [blue/white-cap preview](blue-lucky-preview.jpg), then restored fresh normal Play. No code changed after the final 78-source / 42-test gate.

Upper display rows now have a thin rear joining panel and two rear edge supports, closing the air bands for **12 extra Parts per full plot**: 221 on the first row and 224 on each upper row. The native fixture passed one live row plus five isolated scaled rows; peer review and actual-generator CLI checks pass. Visual comparisons are saved for [one](shelf-supports-1-rows.jpg), [two](shelf-supports-2-rows.jpg), and [five rows](shelf-supports-5-rows.jpg). Existing producer labels can still clip behind upper ledges at some angles. A synthetic-camera rendering probe could not verify an `AlwaysOnTop` change, so **ModelFactory is unchanged**; real-camera label readability remains follow-up work.

## Saved baselines and current comparison

The historical [50-Mini raw results](capacity-50-raw.json) and [96-Mini raw results](capacity-96-raw.json) both identify **source commit 70786a3**. Each includes a 60-second settled sample and a 600-second churn sample. These precede the later UI, obby, geometry, and animation-scheduling batch.

| Sample | Mean frame | p95 / p99 frame | Maximum frame | Mean Conveyor work | Client memory before → after |
|---|---:|---:|---:|---:|---:|
| Baseline 50, settled | 16.699 ms | 17.75 / 18.75 ms | 67.570 ms | 1.045 ms | 2968.848 → 2970.922 MB |
| Baseline 96, settled | 16.672 ms | 17.75 / 18.50 ms | 55.267 ms | 1.810 ms | 3115.129 → 3114.102 MB |
| Baseline 50, 600 s churn | 16.816 ms | 18.00 / 19.25 ms | 165.165 ms | 2.321 ms | 2985.520 → 3070.063 MB |
| Baseline 96, 600 s churn | 16.982 ms | 18.25 / 27.75 ms | 166.535 ms | 4.328 ms | 3137.391 → 3313.914 MB |
| Optimized 96, 60.0038 s settled | 16.686 ms | 17.75 / 19.25 ms | 51.385 ms | 0.378 ms | 3536.648 → 3540.680 MB |
| Optimized 96, 600.0109 s churn | 17.045 ms | 18.00 / 25.50 ms | 185.385 ms | 2.123 ms | 3549.367 → 3708.969 MB |
| Optimized 96, 60.0013 s settled return | 16.662 ms | 17.75 / 18.25 ms | 30.248 ms | 0.383 ms | 3730.098 → 3728.879 MB |

All three optimized samples are saved in [capacity-96-optimized-raw.json](capacity-96-optimized-raw.json), with explicit working-tree provenance based on `70786a3`. Mean Conveyor work fell from 1.810442 to 0.377916 ms in the initial settled sample (about **79%**) and from 4.3282 to 2.1227 ms during churn (about **51%**). These are improvements in the measured Conveyor subsystem. Churn p95 improved from 18.25 to 18.00 ms and p99 from 27.75 to 25.50 ms, but mean frame time rose from 16.982 to 17.045 ms and the maximum rose from 166.535 to 185.385 ms. This is **not an overall FPS win**.

The optimized churn retained **576 Minis / 35,279 Parts / 39,749 Instances** at both endpoints while client memory rose **159.60 MB**, from 3549.367 to 3708.969 MB. After churn stopped, `recoveryStart` and `recoveryEnd` retained **89,116 global Instances** and **39,749 generated-world descendants**, with the same 576 Minis, 300 producers, mesh IDs, and texture IDs. Over **186.7438135 seconds**, total memory changed **3725.58203125 → 3728.33984375 MB (+2.7578125 MB)**. It did not return to the pre-churn level. The separate settled-return timing sample recovered to the frame/work values in the table; timing recovery and memory recovery are distinct.

The diagnostic's `gcinfo()` heap rose 10,328 → 11,292 KB, while the broader Stats `LuaHeap` tag rose 917.771 → 923.729 MB. Mesh/texture category readings stayed unchanged. These measurements have different scopes; categories must not be summed, and two snapshots do not identify the cause of retained memory. The read-only lifecycle audit found no actionable retained removed-model/connection defect in WorldBuilder, Conveyor, or TierEffects. It does not prove absence of a leak, and no immutable-attribute caching or pooling change was added.

Baseline 96 retained 576 Minis / 39,797 Instances at both churn endpoints, while client memory rose about 176.5 MB as reported by `Stats:GetTotalMemoryUsageMb()`. Baseline 50 began its churn sample with zero Minis and ended with 300, so its endpoint difference of 600 Instances includes the intended population fill. Neither observation alone proves or disproves a leak. The optimized raw file also saves `serverWholeTrial`: 841.37 seconds elapsed, 88,428 Minis created and removed, and the same final inventory. Its timing rings retain the last 2,400 work samples and 36,000 heartbeats. Whole-trial server summaries differ in duration and population phases across runs; their totals are not matched ten-minute windows. Absolute memory levels also reflect different prior machine/session history.

All benchmark samples use **one Studio client** and exclude production HUD/audio, ordinary player commands, six real clients, and low-end device conditions. Percentiles use 0.25 ms bins. The [96-Mini pile capture](capacity-96-pile.png) is visual evidence; the separate actual-character tray walk now supplies mixed-species physical pickup evidence. Neither establishes worst-case all-Crocodilo acceptance.

## Source state and next actions

The measured shelf refactor from `70786a3` used **221 Parts per row / 6,630 across six full farms**. The new uncommitted rear joins raise the current full-farm total to **6,702**, without changing the recorded benchmark inventory. The older 1,021-per-row estimate is historical. Cheap settled-Mini handling and conservative offscreen animation scheduling are already included in pushed `58c7875`; the original “no distance scheduling” observation is superseded.

The lighthouse native fixture now **passes**: **744 → 379 Parts**, with **365 hidden studs removed**, **328 visible studs retained**, and **51 body Parts / 22 colliders unchanged**. This is additional to the **557 hub studs** already removed and verified in Studio. The fixture's byte-quantization comparison was corrected while preserving the trees' fractional palette.

Commit `58c7875` is pushed and PR 2 remains draft/unmerged. Final capture and fresh-Play restoration are complete; root will commit the new verified batch after the documentation handoff. Retain 96 Minis for the Studio preview with the measured memory, device, species, and multiplayer limits explicit; do not describe memory growth as resolved.

Next, improve the farmer canopy proportions: thicken existing roof/fringe/posts and prototype lowering the canopy/sign assembly about two logical studs, with zero added Parts and face/deposit-route clearance preserved. Then inspect 50-producer label readability through the real gameplay camera before choosing a fix. Follow with targeted native allocation profiling only for a specific hypothesis from the completed attribute/snapshot/render audit; do not repeat the completed long profile without a reason.

The [additional reference research](../reference/ADDITIONAL_CHICKEN_FARM_RESEARCH.md#browser-follow-up--20-october-2026) remains the basis for visual comparisons. The newly completed Lucky identity pass does not establish exact reference economy rules.

Preserve the user's overrides: no incremental cash buttons, no “Received” prefix, immediate pad entry and held repeat, aura/airborne pickup, and nonmodal Lucky UI. Continue through the overnight cutoff; neither the window nor final 96-Mini validation is complete.
