# Overnight engineering handoff — 2026-10-20, 10:47 UTC

This is a live work checkpoint, not a completion or release report. The minimum work window continues until **13:30 UTC**. The continuation heartbeat now runs every **15 minutes**, as reported by root. See [machine-readable progress](OVERNIGHT_PROGRESS.json) for the current task pointer.

## Current Studio state

The latest pushed checkpoint is **ea5de16**, containing the verified Foltyn map batch. Studio currently runs that baseline plus the verified rear farm-title fix below. All 80 source hashes match at **10:47:24 UTC**. Both production Main scripts are enabled; temporary visual and walking clones are removed. The title batch is ready to commit. PR 2 remains draft and unmerged; nothing is published.

The current source passes **44 standalone Luau suites, 80-source compilation, strict Core analysis, native map/collection checks, Rojo build and diff check**. Saved earlier benchmarks retain their own frozen-source provenance and are not measurements of this map batch. The full Studio Script Analysis panel has not been re-read.

The 07:56 physical Escape stop is historical: root ended UI inspection in that earlier turn and later completed the native/render checks below. No overnight cancellation was requested. The active 15-minute heartbeat and **13:30 UTC** minimum cutoff remain. Saved capacity benchmarks retain their earlier fixed-source provenance and do not measure the complete later `0059fb2`, `4d4fd29`, `88818e4`, `db4ec65`, or `2dc70b1` builds.

Saved-image persistence is now repaired. Oversized transfer chunks had left 11 JPGs truncated; root restored all 11 from their original retained captures using smaller checked chunks and verified all 13 verification JPGs decode at 1759 × 567. The original normal-flow capture was recovered, so its date and source provenance remain unchanged. This repair does not represent a new gameplay run or change any benchmark measurement.

The optimized 60-second settled, 600-second churn, and 60-second settled-return samples are saved, together with recovery-start/end memory snapshots. The snapshots span 186.744 seconds at the same full population while the camera route continued. Total memory stayed elevated; this is not full memory recovery or a resolved-leak finding. Later lighthouse and multiplier-cue work is outside the benchmark's fixed source.

**GroundCap=96 may remain in the Studio preview**, while **Slots=50 is retained**. The six-farm benchmark and mixed-species and all-Crocodilo actual-character pickup passes support that preview setting. All-Crocodilo performance, multiplayer, physical-device, and longer memory behavior remain unvalidated. Nothing has been published.

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

The [actual-character tray walk](tray-walk-96-raw.json), recorded at **06:54:52 UTC**, passed with **96 collected, 96 in the bag, zero remaining token models, all six species, and partial-pile repacking**. The Humanoid walked **52.0936 world studs through five waypoints** after one staging move. Server `CollectNearby` contexts came from the actual HRP; the isolated cloned farm and Core session were removed afterward. This exercises native collision/movement and collection without advancing the normal farm session. That earlier record covers mixed species; the all-Crocodilo check is separate.

The [all-Crocodilo native route](crocodilo-tray-native.json), recorded at **09:39:10 UTC on `4ae9a52`**, passed with **96 collected / 96 bagged / zero remaining tokens or cloned Mini models**, partial-pile repacking, and **51.4551 world studs walked through five waypoints**. All 96 initial models were checked against the imported tier-06 mesh `rbxassetid://132112159852307`; surviving models were rechecked after repacking. The [front-view capture](crocodilo-tray-96.jpg) accompanies the second successful route, repeated because the first capture faced the shelf rear. This uses one Studio client, an isolated cloned Plot1/Core session, one staging teleport, and subsequent real Humanoid walking with pickup positions from its HRP. Production was frozen only for that test session. The clone and fixture were removed and the character, HUD and Custom camera restored; HUD hiding was capture-only. This verifies all-Crocodilo physical collection, not all-Crocodilo FPS, multiplayer, physical-device performance, or memory recovery.

The world Mini-multiplier change cue is integrated into Main and passed native replay suppression, expiry, phone/short layouts, pickup/Lucky/Settings coexistence, and teardown checks, as reported by root.

The native pad-affordability fixture passed all assertions. The [production-controller pad-entry smoke](pad-entry-smoke-raw.json) bought the first producer **0.2654108 seconds after local foot entry** without a direct Buy command. Three `TooFar` responses during staging replication preceded `OK`; this is a single observed Studio smoke result, not a latency guarantee. An earlier movement target stopped outside the pad corner; moving the driver target reliably inside resolved that setup issue without a production change. Play was restarted after that historical smoke.

PadLabels now passes its native fixture for all **15 local labels**, near/distance behavior, quote updates, hierarchy, geometry preservation, and teardown. The first fixture copied an already-managed source; correcting it to use an unmanaged plot then exposed a real `TextWrapped` cleanup omission, now fixed by capture/restore. [Before](fresh-hud-pad-spacing.jpg) and [after](pad-labels-after.jpg) show separated Buy costs. Auto Collect remains hidden while occluded by Merge and becomes readable on approach.

## Verified batch committed as 0059fb2

The [normal farm interaction route](normal-farm-flow-raw.json), recorded at **07:30:29 UTC on source `58c7875`**, passed with **100 Minis deposited, 92 client-observed all-flight collection events while Lucky was held, 88 standing `Claim OK` responses, and two `Upgrade OK` responses**. The card remained visible and nonmodal ([capture](normal-flow-lucky-held.jpg)). The route started with the starter producer: an earlier four-second Buy attempt had timed out after 14 `TooFar` responses and purchased later. This is a successful gameplay route, not a fresh-entry result, and predates the new retry, preflight, and Lucky visuals.

`PadHold` now bounds a `TooFar` retry to **0.5 seconds**, replacing the repeated reset that could retry at 20 Hz. Immediate entry and the existing two-second initial hold / half-second repeat remain intact; pure limiter checks and peer review pass. The separate [fresh Buy smoke](pad-retry-smoke-raw.json) passed at **0.6340522 seconds after local entry**, with one `TooFar` then `OK`. Server trace Z was **46.655 outside** on the first attempt and **55.349 inside** on success. This demonstrates the replication-boundary retry path in one Studio run, not a latency guarantee.

`Core.step` now checks conservatively whether a step can change state before copying it. The deterministic comparison passed **20,160 old/new steps with identical state and RNG**, avoiding **984,048 table copies over the 600-second scenario**, as reported by root. This is allocation-count evidence, not a new native FPS or memory result; the earlier churn/recovery evidence remains unchanged.

Lucky presentation now uses gold **Basic** for `baseTier <= 2` and blue for valid `baseTier >= 3`, consistently across ground block, held block, and card. This mapping is our adaptation; prices, odds, drops, and nonmodal behavior are unchanged. Blue blocks add **36 decorative Parts: 28 question-mark runs and eight white corner caps**. Updated server and client native fixtures pass. Root inspected and saved the final [blue/white-cap preview](blue-lucky-preview.jpg), then restored fresh normal Play. That capture and restoration introduced no changes after the batch's 78-source / 42-test gate.

Upper display rows now have a thin rear joining panel and two rear edge supports, closing the air bands for **12 extra Parts per full plot**: 221 on the first row and 224 on each upper row. The native fixture passed one live row plus five isolated scaled rows; peer review and actual-generator CLI checks pass. Visual comparisons are saved for [one](shelf-supports-1-rows.jpg), [two](shelf-supports-2-rows.jpg), and [five rows](shelf-supports-5-rows.jpg). Existing producer labels can still clip behind upper ledges at some angles. A synthetic-camera rendering probe could not verify an `AlwaysOnTop` change, so **ModelFactory was unchanged at that checkpoint**. The current depth-offset improvement below supersedes that status; it does not enable AlwaysOnTop.

## Canopy, hub, and packet batch committed as 4d4fd29

The canopy is live on all six plots with **68 Parts per stall**, preserving the existing count. The mirrored-plot native fixture passes; front and elevated views keep the farmer face visible. See [before](farmer-canopy-before.jpg), [after](farmer-canopy-after.jpg), and [elevated](farmer-canopy-elevated.jpg). The earlier local checks measured 0.688462 logical studs above the farmer head and 0.1 logical studs between sign and fringe. Native acceptance now supersedes the earlier unsynced/pending status.

The hub composition passes the native environment fixture and **all six routes / 8,664 clearance checks**. It contains **21 bushes, 51 flowers, and six logs**, with decorative collision/query/touch flags false, for **12 additional Parts**. Saved views: [before](hub-composition-before.jpg), [overview after](hub-composition-after.jpg), and [ground view](hub-composition-ground.jpg). These are geometry/route checks, not a new capacity benchmark.

`SnapshotPacket` now clones only the outbound root; deep `Core.snapshot` remains unchanged for transactions. The actual 50-producer/96-Mini state has 152 tables, so the helper avoids **151 nested table copies per send**. Eleven real Core transition checks, metadata/state parity, no-yield checks, strict analysis, and independent review pass. Root's native [server](../../tests/studio-snapshot-packet.server.luau) / [client](../../tests/studio-snapshot-packet.client.luau) probe passes the full **50/96 payload, real CFrame, client isolation, later Core commit, and metadata**. The normal Main State/HUD smoke also passes after cleanup. [Saved native packet evidence](snapshot-packet-native.json) records the isolated probe, normal HUD result, cleanup, and limitations.

For **12,000 envelopes per trial**, actual-helper CLI timings were deep **2,786.891 / 2,063.966 / 2,053.348 ms** versus packet **8.308 / 7.541 / 8.333 ms**, avoiding **1,812,000 nested table copies per trial**. Order alternated and no GC was forced. These timings exclude RemoteEvent serialization, Studio rendering, GPU, and native memory; the native probe establishes correctness, not a native FPS or memory improvement. The earlier capacity/churn/recovery metrics remain unchanged.

## Board, menu, and label batch committed as 88818e4

All three leaderboards now show the same current-server ranks and guarded personal footers on both faces. The native server/client fixtures and actual-module CLI pass. Exactly **six inert planes** raise the three-board Part count **765 → 771**; collision/query/touch remain false on the additions. Root inspected front and rear views with the player in the hub. [Front](leaderboard-front.jpg) and [rear](leaderboard-rear.jpg) captures are saved. All five board/label JPGs passed direct JPEG header, expected-length, and System.Drawing decode checks at **1759 × 567**. This is a reference-informed usability adaptation, not an exact copy or a global leaderboard claim.

`FarmUI.drawMerge` now defers panel construction when `overlay.Visible` is false; `open()` renders the latest state. The actual native regression passed hidden state/pending/shop changes, fresh reopening, visible Merge/Shop/Rebirth/Index updates, and nonmodal Lucky/Settings. Hidden construction changed from **249 cards / 249 portraits / 6,993 added descendants** to **0 / 0 / 3,756**. The remaining 3,756 is consistent with **626 deferred startup/layout studs × six Instances**, because the counter starts immediately after `UI.new`, before deferred `BrickArt` layout runs. The removed 3,237 descendants equal 249 mesh-backed card subtrees × 13 Instances. This establishes avoided hidden card construction, not zero total allocation, native FPS improvement, or resolved memory growth. Visible-panel activity remained expected at 150 cards / 158 portraits / 2,152 added descendants for the exercised sequence; the fixture removes its temporary HUD.

Producer labels now move forward **four logical studs**, which native `Model:ScaleTo(.65)` scales to **2.6 world studs**. The unchanged 65-stud logical cutoff scales to **42.25 world studs**. All six actual meshes passed; normal depth occlusion remains enabled. [Before](producer-labels-before.jpg), [after](producer-labels-after.jpg), and [oblique view](producer-labels-angle.jpg) show improved lower-row readability. Top-row cropping and overlapping labels at oblique angles remain; this is a bounded improvement, not complete readability acceptance.

## Server types and reference documentation committed as db4ec65

Main.server keeps strict mode while refining each cloned optional Lucky state, typing its outgoing response envelope, and making the protected render call return explicit `nil` on success. The [isolated diagnostics probe](main-strict-diagnostics.json) imports the actual `Core.State` and `Core.Result` types. It reproduced all five original warnings with the old solver, then passed with both old and new solvers after the changes. The full Studio Script Analysis panel was not re-read, so this is not a claim of a clean full-file native analysis.

The [fresh normal gameplay route](main-strict-gameplay.json), recorded at **08:44:34 UTC** against the `88818e4` baseline plus the Main.server changes now committed in `db4ec65`, passed with **159 Minis deposited, three client-observed all-flight collection events while Lucky was held, 141 standing cash claims, and two upgrades to processor level 2**. A same-ID Buy replay preserved `action`, `requestId`, and revision while retaining one producer. Actual death and live respawn preserved the same Lucky ID in its unheld state at **100 health**. Root removed the temporary drivers and observers and restored fresh normal Play. This is a one-client, memory-only gameplay check, not a new capacity, frame-time, or memory benchmark.

The refreshed reference board links the front/rear leaderboard views and producer-label comparisons. It identifies two-sided boards as our adaptation, preserves all **100 frames / 36 key references**, and retains the 96-Mini preview limitations.

## Shop redraw batch committed as 2dc70b1

The [native Shop regression](shop-redraw-native.json), recorded at **08:49:25 UTC** on baseline `db4ec65` plus the Shop patch, observed RED with **36 rebuilt offers / 1,296 added descendants** across six unrelated snapshots. GREEN now records **zero offer creations, zero added descendants, all six offer identities retained, and an unchanged 997-descendant list** over the same six updates. Ownership, metadata, pending-state, mode, and upgrade-key changes still refresh correctly. The native hidden-panel regression also passes.

The fixture exercises the actual FarmUI in an isolated HUD, starting observation after three heartbeats to exclude deferred startup construction. It does not change normal gameplay state or preferences. These results establish avoided redundant construction and preserved refresh behavior; they are not a new FPS, capacity, or memory-recovery measurement.

## Endpoint-write batch committed as cbbd765

The [native endpoint regression](conveyor-end-writes-native.json) executes the actual `World.render` and Core against disposable, unparented models and modules. RED completed every phase before the expected duplicate-call assertion: **create 12 / recreate 12 / unchanged 6 / repack 5 / remove 0**. GREEN passes all phases with **create 6 / recreate 6 / unchanged 6 / repack 5 / remove 0**.

New Minis now receive one endpoint setter and point conversion before tagging instead of two. Existing-Mini identity, endpoint initialization before parenting/tagging, Core repacking, removal, and recreation checks pass. This measures one redundant setter and point conversion removed per created Mini; it does **not** establish replication, FPS, or memory savings.

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

## Snapshot-toggle probe on frozen cbbd765

The [three-phase raw record](capacity-96-snapshot-toggle-2026-10-20.json), completed at **09:16:36 UTC**, samples one continuous six-farm mixed-species churn epoch with one Studio client. Production source was frozen at `cbbd765`; the later counter and DepositEffects patches were not synced. Each phase had at least ten seconds of drain or warmup before its approximately 60-second frame sample.

| Frame sample | Duration | Mini endpoints | Received snapshots | Client memory before → after | Delta | Mean / p95 / p99 frame |
|---|---:|---:|---:|---:|---:|---:|
| ON1 | 60.0060 s | 576 → 576 | 168 | 4596.6211 → 4609.8555 MB | +13.2344 MB | 16.9026 / 17.75 / 22.75 ms |
| OFF | 60.0067 s | 576 → 576 | 0 | 4638.2227 → 4651.1719 MB | +12.9492 MB | 16.8933 / 17.75 / 22.50 ms |
| ON2 | 60.0093 s | 300 → 576 | 167 | 4670.0391 → 4660.0469 MB | −9.9922 MB | 16.8278 / 17.75 / 19.75 ms |

**Disabling the full historical snapshot send pipeline did not eliminate short-window memory growth.** ON1 and OFF had matching population endpoints and similar growth despite zero OFF packets. This does not establish zero snapshot cost or rule out carryover allocations from ON1. ON2 began with fewer Minis, so its decrease does not prove recovery and must not be averaged with ON1/OFF as a matched-population comparison. The frame results do not establish an overall FPS gain.

The separate memory/tag brackets last **97.1631 / 73.3967 / 108.4864 seconds**, and server-counter brackets last **97.2796 / 73.3636 / 108.5856 seconds**. Their measurements include collection and polling time outside the frame windows. Do not relabel them as 60-second deltas or equate their packet totals with the frame-sample packet counts. Global Instances were 89,129 at the tag-bracket endpoints; stable live counts do not establish why memory was retained.

The harness uses **deep `Core.snapshot`**, and OFF skips both copying and `FireClient`. This is not a performance measurement of production `SnapshotPacket` or an isolated deserialization test. Production HUD/audio and ordinary player commands are excluded. The camera was fixed at farm 1, FOV 60, viewport 1759 × 567, but saved graphics quality was **Automatic** and actual dynamic quality was unavailable. Initial spawn/control and camera setup repairs happened before measurement. No GC was forced; this is one ordered sequence with no repeated or counterbalanced trials. Light text work continued and a 0.54-second targeted compile occurred during ON1; full suites and builds were held outside the windows. These limits preclude a packet root-cause, resolved-leak, engine-cache, multiplayer, or further-capacity claim.

## Source state and next actions

The measured shelf refactor from `70786a3` used **221 Parts per row / 6,630 across six full farms**. The rear joins committed in `0059fb2` raise the current full-farm total to **6,702**, without changing the recorded benchmark inventory. The older 1,021-per-row estimate is historical. Cheap settled-Mini handling and conservative offscreen animation scheduling are already included in pushed `58c7875`; the original “no distance scheduling” observation is superseded.

The lighthouse native fixture now **passes**: **744 → 379 Parts**, with **365 hidden studs removed**, **328 visible studs retained**, and **51 body Parts / 22 colliders unchanged**. This is additional to the **557 hub studs** already removed and verified in Studio. The fixture's byte-quantization comparison was corrected while preserving the trees' fractional palette.

Commit **`4ae9a52` is pushed**, and PR 2 remains open, draft, and unmerged. The counter/deposit and profiling-evidence batch joins the prior committed checkpoints. Retain 96 Minis for the Studio preview with the memory, device, all-Crocodilo performance, and multiplayer limits explicit; do not describe memory growth as resolved.

**Counter/deposit batch committed as `4ae9a52`:** The [native record](counter-deposit-native.json) saves expected RED on `cbbd765` followed by GREEN. The final mirrored fixture passes **18 inert counter panels**, existing footprints, farmer/face/sign clearance, deposit approach, routes and fences. Final **panel-only RGB(55, 66, 165)** and lowered proportions are synced on all six plots. A dedicated native height check observed RED then GREEN: counter center **Y = 3.2 logical studs**, counter top **2.275 world studs**, and panel height **2.455 logical studs**; the farmer remains **5.5 world studs tall**. The [before](farmer-counter-before.jpg), [after](farmer-counter-after.jpg), and [elevated](farmer-counter-elevated.jpg) JPEGs are validated at **1759 × 567**. Root inspected the replaced final front/elevated captures showing the shirt, both sleeves and pocket; farmer size, sign, canopy and XZ footprint remain unchanged.

DepositEffects passes **eight native cases plus the existing effects regression**. Its pulse occurs independently at 0.5 seconds, portraits have a 0.35-second loading budget, and the scope expires after 1.9 seconds; the default runtime loading budget for other effects remains three seconds. The native fixture injects loading outcomes in disposable clones while retaining real UI/models/tweens/tasks. Stalled/failed loads, warm desktop/phone/short layouts, replacement, GUI destruction and worker cleanup pass. These are bounded behavior/lifecycle checks, not a new FPS or memory-recovery result.

Final **43 pure suites / Deposit CLI / changed source and fixture compilation / peer review / Rojo / diff / 79-source parity** pass. Cleanup restores normal Main scripts, HUD and Custom camera with zero temporary remnants. This later batch is **committed and pushed as `4ae9a52`**, and remains outside the frozen `cbbd765` snapshot-toggle measurement.

**Current work:** the Home/onboarding UI fix is underway, with independent source review and native UI acceptance pending. The separate all-Crocodilo pickup result above is complete; it does not expand the performance benchmark scope.

Producer-label top-row cropping and oblique overlap remain; any further change needs actual player-camera evidence. Keep the existing 50-producer / 96-preview-Mini scope and nonmodal gameplay intact.

The endpoint patch has passed its scoped behavior and source-sync gates. Any further memory experiment needs a changed hypothesis and controlled conditions. Do not repeat the completed long benchmark without a concrete reason, or treat setter/conversion counts or the short toggle sequence as resolved memory growth.

The [additional reference research](../reference/ADDITIONAL_CHICKEN_FARM_RESEARCH.md#browser-follow-up--20-october-2026) remains the basis for visual comparisons. The newly completed Lucky identity pass does not establish exact reference economy rules.

Preserve the user's overrides: no incremental cash buttons, no “Received” prefix, immediate pad entry and held repeat, aura/airborne pickup, and nonmodal Lucky UI. Continue through the overnight cutoff; neither the window nor final 96-Mini validation is complete.

## Home layout and booth extraction verified at09:55:44UTC

The Home button is available once the farm is Ready, including onboarding. Compact screens keep the objective, detail, action row and cash-plus Shop access. Native testing exposed and then resolved Lucky at640×500 and Settings at900×600 overlaps; existing scrolling panels use a bounded fallback only when they intersect another control. Twelve viewport sizes pass native rendered text and separation checks. An observed native Home activation returns the early-tutorial avatar from the hub to the plot. The [before](home-onboarding-before.jpg) and [after](home-onboarding-after.jpg) images use the actual UI inside an isolated390×440 frame; they are not physical-device acceptance.

FarmerBooth now owns the unchanged stall constructor formerly in WorldBuilder. A disposable oracle from committed9ee6fda matches426 parts across all six integrated booths, including transforms/sizes within1e-5, hierarchy, colors, materials, interaction flags, surfaces and imported mesh/texture IDs. The existing mirrored-map fixture also passes. The initial unencoded snapshot probe returned Complex Table and was not used as parity evidence.

The [native record](home-booth-native.json) includes RED/GREEN layout results, booth parity and cleanup. All80 sources compile and match Studio;43 standalone suites, actual-module Home CLI, Rojo, peer review and both image decode checks pass. This batch was committed and pushed as 699931c; no FPS or memory improvement is claimed. New work now targets a broader shallow tray and diagonal gold display dividers, informed by the additional Foltyn video study. Continue through13:30UTC; overnight work is not complete.

## Foltyn map pass verified at 10:20:48 UTC

The additional [Foltyn study](../reference/chicken-farm-foltyn-study/index.html) contains 14 selected timestamped frames and eight key views from the newly requested video, plus nine annotated native before/after pairs. The earlier 100-frame board is preserved. Reference selection is no longer capped at 100; this study records selected observations, not a continuous video or audio audit.

The collection floor is now **24 × 16 logical studs**, with **32 resting positions per layer** and three layers at 96 Minis. Buy 5/10 move to X = ±22, Auto Collect to Z = 52 and Lucky to Z = 65. Existing values, Mini sizes, rotation/jitter, aura radius, collision heights and the full red belt remain intact. Native RED observed the old 16-stud width; GREEN checks all six plots, every pad base/trim clearance and center belt collision. All 96 targets from both conveyor extremes clear the decorative facade. Each facade has 213 Parts, two fewer than before.

The shelf's rectangular dividers become sloped wedges with diagonal gold caps. Five-row native geometry checks pass with the same **221 ground-row / 224 upper-row Parts**. Independent structural comparison preserves all 1,017 unrelated Parts across five rows. The [paired 96-Mini front view before](layout-before-96-front.jpg) and [after](layout-after-96-front.jpg), with 24/50 variants on the board, use fixed IDs, cameras and 50 actual Crocodilo producers. Dense Crocodilo mesh overlap remains. Cloned plots do not receive the normal owned-plot PadLabels controller; overlapping pad labels in these comparisons are not font-layout acceptance.

Both actual-Humanoid walking variants pass with **96 collected / 96 bagged / zero survivors**, partial repacking and all five waypoints: mixed species walked **43.4284 world studs**, all Crocodilo **43.3708**. Their isolated Core sessions freeze production and preserve each species' catalog value. [Raw native tray evidence](wide-tray-native.json) includes the complete samples. These are physical pickup checks, not performance measurements.

The redundant lawn overlay is removed: **844 Parts per plot / 5,064 total**. Native checks retain **77 colliders per plot**, and all 18 original ground slab transforms, sizes, colors, materials, native Studs and interaction flags match within 1e-5. Environment, mirrored-map, bridge landing and live affordability fixtures pass. The generic cosmetic cash-ground ray can now start up to 0.078 world studs lower at the real slab. See [coarse overlay before](lawn-overlay-before.jpg) and [native lawn after](lawn-native-after.jpg).

Only Tung Tung and Crocodilo producer-name colors change, to warm cream RGB(255, 204, 143) and light green RGB(177, 236, 112). The other four species, font, label geometry, meshes and catalog remain unchanged. [Before](producer-palette-before-front.jpg), [after](producer-palette-after-front.jpg) and oblique pairs show the six actual meshes. The [lawn/palette record](lawn-palette-native.json) saves native checks and limitations.

All **44 standalone suites**, **80 production-source compilations**, strict Core analysis, Rojo build, peer review, diff check and **80/80 Studio source hashes** pass. Nineteen newly saved native JPEGs decode at 1759 × 567 (including the initial lawn trial). Temporary plots are removed; normal HUD and Custom camera are restored. Relocated-pad normal-client interaction smoke passes in the following section. This does not change capacity acceptance, claim FPS/memory improvement or end the overnight window.

### Relocated-pad normal-controller acceptance at 10:32:53 UTC

The [normal-controller route](moved-pad-native.json) passes in a disposable seeded session, using actual Humanoid walking and shipped Main for all purchases/pickup. Buy 5/10 entry successes arrive **0.6665 / 0.6166 seconds** after sampled foot entry; the first repeats arrive **2.1489 / 2.0996 seconds** after entry, and subsequent intervals are **0.5509 / 0.5331 seconds**. Each purchase pad had one initial TooFar at the replication boundary before its bounded retry succeeded. This is observed Studio timing, not a latency guarantee.

The route walks **92.7728 world studs**, ends at **46 producers / 5,120 coin units**, shows Auto Collect + Deposit / Coming soon on the unconfigured offer, and carries the same Lucky without a charge. Lucky remains unheld at **7.0485 world studs** and becomes held at **5.4714**, with one boundary TooFar before success. Its panel remains nonmodal during further walking. The [normal owned-plot capture](moved-pad-normal-owned-plot.jpg) includes the production PadLabels controller; it also demonstrates the rear farm-title clipping selected for the next fix.

Synthetic setup is explicitly limited to 10,000 coin units and one tier-2 Lucky through Core snapshot/commit. The first direct-executor bootstrap did not intercept normal Main's module context, so that Play was discarded. The successful attempt uses an actual disposable runtime Script and restores its one-shot wrapper before returning the created session. Both Main scripts are re-enabled in Edit afterward, normal fresh Play is restored, and the temporary fixture/progress are removed. No production source was changed for seeding.

Final 44 standalone suites, four new native-fixture compilations, shelf CLI and image decode checks pass. The map batch is ready to commit. The unattributed asset-type warning for audio ID 203785492 predates this work and has no repository/live-game reference found; all configured farm audio voices load. Its external caller is unresolved, and the game audio was not replaced.

## Rear farm title above stacked rows — verified 10:47 UTC

The rear title follows the highest occupied row, uses a world-aligned vertical offset, and wraps within a scaled canvas. The existing font, outline, sign, portrait, ordinary depth occlusion, and 65-world-stud cutoff remain. Native RED reproduced shelf clipping; GREEN covers 1 → 11 → 50 → 11 → 1 → 0 → 50 producers and clear/reset. Actual species model identities are checked after every transition. Four paired camera views are saved in the [Foltyn board](../reference/chicken-farm-foltyn-study/index.html#comparison-owner-title).

A 20-W display name plus suffix measured 343.53 × 40.06 pixels inside a 347 × 43 canvas at the recorded close five-row view. [Raw title evidence](owner-title-native.json) records the checks and scope. Lower producer names can still clip behind upper fascia; distant or short-screen portrait/title overlap remains possible. Cloned pad labels in these geometry comparisons are not managed by the normal owned-plot controller.

All 44 standalone suites, 80 source compilations, seven affected fixture compilations, native affordability and endpoint lifecycle regressions, peer review, Rojo build, eight full-size JPEG decodes, and diff check pass. All 80 running-Server source hashes match. Temporary previews are gone; normal HUD and Custom camera are restored, with character health 100. Sources are synced to Studio and the local Rojo place is saved; no Studio document Save or game publishing action was performed.

The previous Foltyn map batch was committed and pushed as **ea5de16**. This title batch is ready to commit. Next: test a bounded producer-label anchor correction at real front, oblique and elevated views, then continue the highest-value UI/map work through the 13:30 UTC minimum.


## Held-Lucky Settings access and pad refresh — verified 11:17 UTC

The title batch is committed and pushed as **c0204a1**. Two producer-label anchor trials were rejected because oblique clipping remained; neither changed production ModelFactory.

Settings now stays reachable beside Home while holding a Lucky Block. It reuses the existing button and restores its rail placement/caption after closing. Native virtual layouts pass at 15 sizes, and the actual-module CLI passes 2,163 supported viewport combinations, including the 800 × 500 and 800 × 573 boundaries without shrinking an otherwise full-height card. The multiplier cue avoids the reused gear. Actual mouse input opens Settings, changes music from 35% to 45%, and returns to the same synthetic held ID with no drop and no modal overlay. The short card scroll settles at 42 pixels with Discard bottom equal to the viewport bottom; its dummy callback is received once. The first immediate scroll assertion ran too early and is retained as a test-timing limitation. [Native record](settings-access-native.json), [gear](held-settings-gear.jpg), and [panel](held-settings-panel.jpg) record the scope; screenshots use a synthetic UI state, not an actual server-held mesh.

WorldBuilder now indexes pad decoration pieces once per changed render and retains no cache between renders. The threshold replay reduces 46 root scans / 65,734 visited children to 18 / 25,722, with unchanged colors and affordability. One hundred unchanged renders perform zero scans. Native replacement, addition, rename, clear and isolation cases pass in [raw pad-index evidence](pad-piece-index-native.json). These counts do not establish FPS or memory gains.

Three shared modules also receive narrow callback/placement types and direct MeshPart guards. Both CLI solvers pass the reproduced pure-module diagnostics; native Lucky client/server and pad-label regressions pass. Studio's Edit aggregate changed from 703 to 697 warnings with zero errors; the virtualized warning list was not exhaustively audited, and broader warnings remain.

All 44 standalone suites, 80 production-source compilations, 2,163-layout CLI, native fixtures, independent review, Rojo build and diff check pass. All 80 running sources match disk. An actual Ctrl+S saved **build/MergeABrainrot-FirstPlayable.rbxlx** at **11:17:25.0166435 UTC**; XML inspection confirms all 80 saved sources match the same hashes. Fresh normal Play restores HUD, Custom camera, health 100 and no temporary UI. No game publishing action occurred. Capacity remains 50 producers / 96 preview Minis, with the earlier performance limitations unchanged. Continue coding through 13:30 UTC.


## FarmUI strict cleanup — verified 11:25 UTC

The Settings/pad-index batch is committed and pushed as **dea3690**. FarmUI's six warnings are now cleared in the same opened native Play script after analysis settles: the optional tween is played through its nonoptional local, unreachable walk-pad button branches are removed behind the unchanged allowlist, and Shop captions are narrowed to TextLabel. [Native evidence](farm-ui-strict-native.json) preserves before/after diagnostics. Broader Edit analysis still reports 691 warnings and zero errors; this is not a global clean result.

The actual dispatch method passes 40 context/guard combinations before and after. Existing Settings and Shop native regressions pass, six Shop captions retain TextScaled and 12–23 constraints, and actual mouse hover/press/release/leave on a disposable Home button reaches 1.05 / 0.97 / 1.05 / 1. All 44 pure suites, 2,163 viewport combinations, scoped compilation, independent review, Rojo build and 80-source parity pass. Ctrl+S saved the existing Studio document at 11:25:31.7114036 UTC; all 80 XML sources match. Fresh normal Play is restored. Continue to 13:30 UTC; a lower-row nameplate prototype is next, with no producer-label change accepted yet.
