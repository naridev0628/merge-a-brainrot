# Additional Chicken Farm research

Research date: 20 October 2026. Scope: additional gameplay sources beyond `csKguFJi77Q` and `HJcoc02bumg`, with useful gaps for Merge a Brainrot.

The initial research found an optional obby with an availability state and a temporary production reward, plus production-cap feedback. Gems and gold variants remain longer-term progression candidates. The initial pass below used creator metadata, accessible transcripts, the official experience description, and a read-only repository inspection. A later browser inspection of four gameplay frames is recorded at the end of this document.

## Source identity and evidence limits

The target is [Chicken Farm by Skandi Studios, place 137233438285284](https://www.roblox.com/games/137233438285284/Chicken-Farm), universe `10209534490`. Its current description explicitly lists an obby, events, Gem Upgrades, Gold Chickens, another Lucky Block, another rebirth, and two additional Buy Tiers. It also says chickens produce while the player is away. Those statements establish feature existence, not their prices, limits, UI, or exact rules.

YouTube watch-page fetches were throttled, and CUA reported no available browser surfaces. Thumbnail endpoints were also unavailable through the web tool. Therefore this document does **not** claim playback, frame inspection, measured timings, or visual confirmation of any new source. Accessible Dailymotion transcripts were read directly; their wording may contain automatic transcription errors. No video/audio was downloaded or extracted.

## Additional video shortlist

| Source | Evidence actually inspected | Why it is useful / next inspection target |
| --- | --- | --- |
| [Foltyn — ROBLOX CHICKEN FARM..](https://www.youtube.com/watch?v=jdZNH1-EMJo) | YouTube-indexed creator/title/description; dated 17 July 2026. Creator describes making a Chicken Farm. Also associated with the exact Roblox place by the discovery directory below. | A different creator's first-session progression. Watch purchase, merge, processor, and discovery transitions; no particular transition has been verified here. |
| [RyanRbx — I SPENT 100 HOURS MAKING THE BEST CHICKEN FARM IN ROBLOX...](https://www.youtube.com/watch?v=F-bSM-0xe2k) | YouTube-indexed metadata; dated 15 July 2026. | Potentially compact progression coverage. “100 hours” is a title claim, not a measured play duration. The description's generic reference to Roblox obbies does **not** prove a Chicken Farm obby appears. |
| [PRO GAME ZONE 0 — I Made $125,000 From My Chicken Farm in Roblox!](https://www.youtube.com/watch?v=wy_TBMJA7nw) | YouTube-indexed metadata; dated 14 September 2026. Description explicitly names Chicken Farm by Skandi Studios and a $125,000 goal. | Stronger exact-game attribution and a later upload than the July videos. Inspect the opening HUD and any available obby/event controls first. Upload date alone does not establish which game build was recorded. |
| [BemmyBlox — I HATCHED *INFINITE* CHICKENS in ROBLOX CHICKEN FARM...](https://www.youtube.com/watch?v=1CtZLJiktoI) | Title/channel and linked video ID in a directory attached to the exact Roblox place; no primary page or playback inspection. | Lower-confidence discovery lead for dense production and collection readability. “Infinite” is promotional wording, not a verified mechanic. |
| [CoralBlox4 — Starting Over as NOOB with OP SECRET in Chicken Farm! (Roblox)](https://www.youtube.com/watch?v=jBhJSBdaD54) | Title/channel and linked video ID in the same directory; no primary page or playback inspection. | Lower-confidence lead for reset/rebirth presentation and returning-player flow. Do not assume the title proves a particular reset rule. |

The last two links were resolved from the public HTML of the [Roburo exact-place video directory](https://www.roburo.jp/games/137233438285284/chicken-farm/videos/). It is a discovery source, not an authority for mechanics. These are five new video IDs; metadata-only entries are a watch queue, not five inspected playthroughs.

## Concrete transcript observations

The following are additional Roblox Chicken Farm gameplay uploads by PoknatXy. The dialogue names systems and species consistent with the target game, but the exact experience was not visually confirmed. Treat the statements as player reports. Clips from the same creator may overlap; they are not independent corroboration.

| Source and transcript time | What the source actually supports | What remains unverified |
| --- | --- | --- |
| [Meet our feathered friend](https://www.dailymotion.com/video/xbb1bmq), 01:48–02:22 | Players say the obby has become available, discuss claiming an egg-related reward for five minutes, then report falling. | Exact multiplier, cooldown, whether the reward was just claimed, checkpoint rules, course layout, and reset behavior. |
| Same video, 01:12–01:19 | A player attributes stopped egg production to lack of space. | Which capacity is full and whether the interpretation is correct. |
| Same video, 04:00–04:28 | A player weighs a Rainbow Lucky Block against an unaffordable cost and a rebirth goal, then discusses discarding it. | Price formula, reward pool, and any discard confirmation UI. |
| Same video, 05:07–05:23 and 08:39–08:44 | Players notice different values and are unsure why. | Whether size, variant, boosts, or another factor caused the difference. |
| [Bright, glossy, blocky egg bucket icon](https://www.dailymotion.com/video/xbcjg0q), 00:09–00:18 | Players report three rebirths and access to gems/upgrades. | Exact unlock threshold and whether rebirth itself grants the gems. |
| Same video, 00:39–00:54 | A player reports gems from collecting a diamond egg. | Reward quantity, chance, and whether an upgrade changes it. |
| Same video, 06:05–06:36 | Players compare another player's low/high species and ask about a named creature's tier. | Actual label arrangement or discovery restrictions on visiting another farm. |

No settings panel was established by this new evidence. Search results also included third-party automation menus; those are **not** native game settings and were excluded. Commercial clone templates, unrelated chicken tycoons, and community code lists were not used as implementation references.

## Repository gaps checked

This is a snapshot of the working tree during research, not a claim that later overnight work has remained unchanged.

| Area | Current implementation inspected | Consequence |
| --- | --- | --- |
| Settings | `src/client/Controllers/SettingsPanel.luau` has independent music/effects percentages, reset, responsive scrolling, and a session-only notice. `src/shared/ClientPreferences.luau` stores those two values locally. | Basic audio settings are already implemented. Persistence and reduced-motion options would be original product decisions, not verified reference parity. |
| Obby | A search of `src` found no obby controller, course, or reward flow. | A genuine missing activity, supported at the feature level by the official game description. |
| Events | `src/shared/MiniEvent.luau` and `src/server/Main.server.luau` already rotate a shared production multiplier every 90 seconds; `MultiplierDisplay` shows it. | Do not add a duplicate “event system.” An obby reward needs a separate duration/state and explicit stacking rules. |
| Production cap | `FarmCore.step` stops creating physical Minis at `GroundCap` or `GroundPerProducer`; producer clocks advance, with no hidden backlog. | Make paused production understandable without changing this domain rule. |
| Lucky Block decisions | `LuckyPanel.luau` already displays cost, reward odds, unavailable amount, and stack-full state; discard exists. | Focus on clarity around a pending discard or a blocked action, rather than rebuilding the panel. |
| Index and values | `IndexPanel.luau` already displays discovered names, levels, a computed Mini cash value, and production cadence. | Any explanation should separate production multipliers from sale-value multipliers; avoid presenting one unexplained combined number. |
| Persistence | `Main.server.luau` explicitly runs in Studio memory mode and rejects live progression because saving is not implemented. | Offline production cannot be honestly added as a UI-only bonus. It depends on durable progression first. |

## Prioritized coding candidates

These are proposed adaptations. Acceptance criteria below are our design requirements, not claims about Chicken Farm.

1. **P1 — Explain a full collection tray.** Add a quiet status near the basket or producer display when the local physical-Mini limit prevents additional drops. Suggested copy: “Tray full — collect Minis to keep production moving.” Derive state from the existing server snapshot; distinguish a global tray cap from one producer's cap. Clear the notice after collection, avoid repeated toasts, and test both cap types plus auto-collect. This is a small usability improvement with a concrete existing condition.

2. **P1 — Add a compact optional obby beside the hub.** Begin with start, progress/checkpoint, fall/retry, finish, and return-to-farm states. Keep the six farm approaches clear. The transcript suggests a time-limited production reward, but its exact multiplier and cooldown are unknown; choose and document our own balanced rule. Validate checkpoints and finish on the server, award once per run, and test death, Home teleport, repeated finish touches, cooldown expiry, and multiplier expiry. A visible availability/countdown state is part of this candidate, not a verified reproduction of reference UI.

3. **P2 — Explain production and cash value separately.** Use a short breakdown in the existing Index or contextual detail: base Mini value, rebirth/cash effects, then production cadence and active production boost. Preserve the current HUD's simplicity. Check it against `FarmCore` and `Economy`; a production boost must not accidentally be advertised as increasing each Mini's sale value. This addresses the transcript's confusion without importing unverified variant math.

4. **P2 — Add a local reduced-effects preference.** The current panel can support a simple option affecting discovery bursts, deposit flights, and cash/pickup celebration density. Keep functional pickup and value feedback visible. This is an original accessibility/performance improvement; no new source confirms a matching reference control. Preference persistence belongs with the broader persistence milestone, because the current session-only label is honest.

5. **P3 — Specify gems/variants after the core progression is stable.** The official feature list and gem transcript justify investigating a secondary progression layer, but do not justify copying costs, chances, unlock levels, or a second currency immediately. First decide what decision gems add beyond cash/rebirth. Require clear source-of-gems feedback, spend confirmation, and durable balances before implementing a shop.

6. **P3 — Plan offline production with saving.** Use the official offline-production statement as a feature target only. Before any return reward, define elapsed-time bounds, storage limits, clock handling, and atomic claim behavior. Never label a fresh Studio session as recovered offline progress.

Across all candidates, retain the user's existing direction: no incremental cash purchase buttons and no “Received” prefix in reward feedback. There is no need to copy the source's code, audio, paid offers, or exact economy.

## Next visual research pass

The highest-value capture is the obby sequence in `xbb1bmq` around 01:45–03:45: entrance text, availability state, course, fall behavior, finish reward, then the farm HUD showing reward duration. Next inspect `xbcjg0q` around 00:00–01:05 for the gem balance/upgrade panel and a diamond pickup. The newer PRO GAME ZONE upload is the first YouTube candidate to check for current HUD changes.

For each observation, record the displayed timestamp and one image of the actual state. Do not promote the ambiguous transcript's five-minute egg reward to “2× production for five minutes” until the UI is legible. A settings screenshot is still an open research need.

Validation: all local source paths above existed when checked; the two old video IDs are excluded from the new shortlist; five new YouTube IDs and two transcript URLs are explicitly separated by evidence quality. No gameplay, map board, or test files were changed in this research pass.

## Browser follow-up — 20 October 2026

The additional [PRO GAME ZONE 0 playthrough](https://www.youtube.com/watch?v=wy_TBMJA7nw) loaded in the in-app browser. After its pre-roll, the player reported a 2:37 duration. Four paused gameplay states were visually inspected through browser screenshots; this was sampled viewing, not a continuous or audio review. The source video is soft at this viewport, so small numbers are not used as exact balance requirements.

| Player time | Visible evidence | Application to the current game |
| --- | --- | --- |
| [00:13](https://www.youtube.com/watch?v=wy_TBMJA7nw&t=13s) | The avatar carries a cyan/blue question-mark block. A narrow blue Lucky Block card remains on the right, with three reward rows and 75/20/5 percentages; the farm remains bright. A compact multiplier-change line sits above the basket. | Preserve held-block/nonmodal behavior. The new bounded multiplier cue follows this placement. Blue block/card presentation is a future visual progression candidate; exact unlock and price rules are not established. |
| [00:40](https://www.youtube.com/watch?v=wy_TBMJA7nw&t=40s) | A wide pale-yellow Deposit Eggs pad, ground direction arrows, an empty basket, and a small deposit-count message are visible together. | Keep the entire pad active and keep deposit feedback compact. Our Brainrot basket and visible glow are deliberate substitutions. |
| [01:20](https://www.youtube.com/watch?v=wy_TBMJA7nw&t=80s) | The same playthrough now shows a gold Basic block/card while several collection amounts rise near the basket. The tray and conveyor are red with gold trim. | Confirm that open Lucky UI must coexist with pickup feedback. Keep the existing bounded pickup lanes and continuous red conveyor. The different block presentations do not by themselves establish their drop algorithm. |
| [02:00](https://www.youtube.com/watch?v=wy_TBMJA7nw&t=120s) | A low camera shows several occupied shelf rows. Buy 1 text is larger nearby, while Buy 5 and Auto Collect appear smaller farther away. | This supports the distance-sensitive pad-label pass prompted by our own spawn-camera overlap. Preserve readable costs and current action geometry. |

These observations supplement the existing 100-frame annotated map study. They do not add four saved images to that study or claim that settings, obby rules, sound choices, or new economy formulas were verified in this video. The current implementation has since added an obby, capacity hints, and production/value explanations; the earlier repository-gap table is historical.
