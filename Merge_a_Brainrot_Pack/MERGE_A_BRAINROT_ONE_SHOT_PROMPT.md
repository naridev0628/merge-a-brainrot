# MERGE A BRAINROT — Original Roblox / Luau Build Prompt

Version 1.0 · 2026-10-14 · Default mode: INCREMENTAL

This is an original adaptation of the supplied `STEAL_AN_EGG_ONE_SHOT_PROMPT.md`, not a recreation of another experience. It replaces the original game's chase, speed-training, hatching and three-pet fusion systems with the production, collection, selling, two-of-a-kind merging and rebirth loop requested by the project owners. The confirmed inspiration is **Chicken Farm by Skandi Studios**. “Steal a Brainrot-style” means a playful collection of absurd characters with visible progression; it does not authorize copying its models, voices, branding or map.

The entire specification is usable on its own. Supporting research, inventories and design briefs explain the evidence and decisions. All numbers, character concepts, geometry and UI arrangements below are **original design defaults**, not measured Chicken Farm balance values. The exact two-input recipe is a project requirement, not a verified claim about Chicken Farm.

## 0. Your role, scope and working mode

Act as a technical development partner to two college students building their first Roblox game. One uses macOS, the other Windows. They share an existing GitHub repository, but cloning, Studio installation and Rojo configuration have not been verified. Do not assume setup is finished or invent a repository URL. Read applicable repository instructions and inspect the existing project before editing. Preserve unrelated work.

Create a playable **solo progression game in a shared server**: six players can see one another's plots, but each controls only their own economy. There are no teams or competitive rounds. Build from original primitive models so missing art never prevents play.

Set `BUILD_MODE` explicitly:

- **INCREMENTAL (default):** complete the next runnable checkpoint only, test what tools permit, explain its purpose briefly and give the learner one next action. Ask for only the access or missing information needed for that checkpoint. Do not hand them fifteen setup tasks at once. Keep later requirements in the roadmap.
- **FULL:** when the user explicitly selects this mode, implement the complete v1 scope, internally following the same checkpoints. Deliver complete source files and honest test results. A large generation is not proof of a working game. Respect any pending design review before implementing non-trivial UI.

This document is a build specification, not proof that any code, artwork or game has already been built. Do not deploy, publish, spend Robux, buy assets or message collaborators as part of generating the prototype.

### Hard requirements

1. Typed, modular Luau; use `--!strict` where practical. Runtime-validate all remote input and loaded data.
2. Server-owned economic state. Clients request actions and present effects; they never decide rewards, ownership, timers, costs or merge outputs.
3. Reproducible original world and placeholder characters built from `MapSpec` and `ModelFactory`. No external asset ID is required for v1.
4. One shared, bounded production scheduler; finite plot, drop and bag capacities.
5. Deterministic **two distinct identical species → one next-tier species**, without a fee, chance roll, hatch wait or mutation.
6. Working collect → sell → buy → merge loop, six tiers, rebirth and a persistent discovery index.
7. Persistence with an explicit session lifecycle, session locking and failure handling before a live release. Early Studio checkpoints may use an explicitly labelled memory-only mode.
8. Mouse, keyboard and touch support. No precision dragging, hover-only information or tiny close buttons. Controller support is a later checkpoint unless requested.
9. Portable source structure for Mac and Windows, with a verified Rojo mapping if Rojo is used. Do not maintain independent conflicting copies of scripts in Studio and Git.
10. Record actual checks separately from unrun tests. No fabricated screenshots, test passes, asset licenses or tool capabilities.

### Asset policy

Use team-created primitive placeholders first. A future replacement must have documented appropriate permission, dependency access for the target experience and a script/dependency review. Record it in `assets/ASSET_MANIFEST.csv`. A publicly accessible model, meme name, free listing, screenshot or another game's use does not establish permission for this project.

Do not extract places or proprietary models, decompile other games, rip meshes/textures/audio, import the supplied decompiled client-derived tables, or reproduce distinctive proprietary characters from screenshots. Credit third-party creators accurately; do not claim authorship of acquired assets. Reference images inform observations, not production textures or marketing art. Unknown assets stay as placeholders. Imported scripts are inspected before use, never executed merely because they arrived in an archive.

Optional original concept images, icons and licensed audio can follow the playable prototype. Verify that tools are available before using them. Keep original prompts and provenance. Never make image generation or an upload a prerequisite for core gameplay.

## 1. The complete v1 loop

1. Join your automatically assigned plot with **one Tier 1 producer and zero Coins**.
2. Every six seconds, each producer creates one collectible **Mini**: an egg-like token or simplified baby-shaped token representing its species.
3. Walk near a Mini to collect it into your bag. Mini tokens are sale goods; they never become new producers.
4. Visit your plot's **Sell Minis** pad to sell the whole bag for Coins.
5. Spend 20 Coins on **Buy Tier 1**. The new producer occupies the lowest free numbered slot.
6. Open **Merge**, select two identical species and confirm the visible output. Both inputs are consumed; one next-tier producer appears immediately.
7. Discover all six original species. Higher tiers produce more valuable Minis, and merging frees one plot slot.
8. Own a Tier 6 producer and reach the current Coin requirement to **rebirth**. Reset the current run, receive a fresh starter and keep a permanent +25 percentage-point sale bonus per rebirth.
9. See other players' collections across the plaza. Progression is independent; visitors have no purchase, collection or merge authority on somebody else's plot.

Do not add stealing, combat, guardians, speed stats, treadmills, growth timers, genders, weight rolls, mutations, lucky blocks, trading, paid products, offline income, events, daily rewards or global leaderboards to v1. Keep these out of the implementation rather than creating empty services for them.

## 2. Original catalog and economy

Working names below are proposed original concepts, not cleared trademarks or finished assets. Stable IDs are the implementation contract; names and art can change without changing saves.

| Tier | Stable species ID | Working name | Interval | Base Coins per Mini | Base Coins/second | Successor |
|---|---|---|---:|---:|---:|---|
| 1 | `tier_01` | Spoon Sprout | 6 s | 2 | 0.3333 | `tier_02` |
| 2 | `tier_02` | Wobble Waffle | 6 s | 5 | 0.8333 | `tier_03` |
| 3 | `tier_03` | Bubble Boots | 6 s | 12 | 2 | `tier_04` |
| 4 | `tier_04` | Disco Turnip | 6 s | 29 | 4.8333 | `tier_05` |
| 5 | `tier_05` | Noodle Comet | 6 s | 70 | 11.6667 | `tier_06` |
| 6 | `tier_06` | Toaster Monarch | 6 s | 170 | 28.3333 | none |

The producer emits one token per interval at every tier. The improvement is token value, not an exponential flood of physical objects. For example, two Tier 1 producers yield four base Coins per six seconds; their Tier 2 successor yields five. Merging improves total output and frees a slot.

### Exact units and formulas

Use integer **coinUnits**, where four units equal one displayed Coin. This preserves quarter-Coin bonuses without floating-point drift or rounding changes when players split sales.

```text
displayCoins = coinUnits / 4
tier1CostUnits = 20 * 4 = 80
saleMultiplier(r) = 1 + 0.25 * r
saleCreditUnits = sum(group.baseCoinValue * group.count in bag) * (4 + r)
rebirthCostCoins(r) = 10_000 + 2_500 * r
rebirthCostUnits(r) = 4 * rebirthCostCoins(r)
```

Here `r` is the current rebirth count, before performing the action. Apply the multiplier at sale only; do not multiply production values and then multiply again at sale. `baseCoinValue` is captured by the server when a token is created and preserved when collected, so later catalog changes do not silently reprice saved bag goods. Format fractional Coins when present, and show an exact price/value in detail panels even if the compact HUD abbreviates it.

Original limits:

| Setting | Value | Behaviour |
|---|---:|---|
| Players / plots | 6 / 6 | Assign a free plot automatically |
| Producer slots | 12 | Fixed in v1; buying with a full plot consumes no Coins |
| Ground Minis per producer | 8 | Shared plot ledger also capped at 96 |
| Ground Minis per plot | 96 | Production pauses at capacity; no hidden backlog |
| Bag capacity | 96 | Full bag leaves the ground token untouched |
| Scheduler cadence | 0.25 s | One server loop for all loaded plots |
| Catch-up cycles per producer per update | 2 | Skip excess overdue cycles after a stall |
| Collection distance | 8 studs | Server checks owner, living character and distance |
| Sell / Buy pad distance | 10 studs | Server checks its own interaction anchors |
| Rebirth count cap | 20 | At cap, show “Rebirth complete”; existing farm continues |
| Coin unit cap | 4,000,000,000,000 | Reject an overflowing credit without consuming the bag |

Keep caps, rates, prices, catalog and feature decisions in shared configuration, with server validation. Do not expose a client command that changes them. Do not silently add bulk purchase, merge-all or automation before the basic loop passes.

### First session and pacing

The first token appears within six seconds; the first collection should occur within 10–30 seconds of a successful profile load. Ten Tier 1 Minis fund the first purchase. With instant collection/selling and no travel, the first merge is at roughly 60 seconds. Aim for an actual first merge within 60–120 seconds and first rebirth within about 9–15 minutes; these are hypotheses to measure, not guarantees. See `research/02_ECONOMY_AND_PROGRESSION.md` for assumptions.

## 3. Production, collection, selling and purchase contracts

Each producer has a unique ID, species ID, numbered slot and session-only next due time. Runtime timers use server monotonic time. Save no due timestamp for offline production; on login all producers start a fresh six-second interval.

Every ground token has a unique ID, owner UserId, origin producer ID, species ID, positive bounded base value and a server-selected position inside that plot. Its ledger is authoritative. The visible proxy is anchored, non-colliding and limited in part count. Do not allow network-owned unanchored collectibles to decide pickup position or value.

At a due tick, create at most the configured catch-up count, and stop if either cap is full. When capped or after excess catch-up is discarded, advance the next due time to a future interval; there must be no accumulated backlog that floods the plot when storage clears. Producers created by purchase or merge begin a new interval. Already-produced tokens from merged inputs remain valid sale goods and retain their values; they do not turn into producers. Retain per-origin counts for retired input IDs until their last token is collected, then prune zero-count retired entries. The plot cap always includes these tokens.

Collection can be a walk-near interaction. The client sends a bounded token ID, and the server atomically removes that ground record and adds one bag item if ownership, proximity and capacity pass. Repeated attempts for the same ID grant nothing. Clear the proxy after committing the ledger; a rendering failure must not duplicate the item. Compact bag records may group identical `{speciesId, baseCoinValue}` items with a count; bound both total count and group count by 96.

Selling uses `RequestSell(requestId)`, not a supplied amount. The server checks the player's own pad, computes bag value and commits Coin credit plus bag clear together. Empty-bag sales give zero. While loading, closing or lock-lost, selling is unavailable. Sell-pad entry fires once per entry, with an explicit button available while standing on it; do not fire every render frame.

Buying uses `RequestBuyTier1(requestId)` and requires own-pad proximity, at least 80 coinUnits and a free slot. Commit subtraction plus producer insertion together. A valid distinct repeated purchase may buy another producer; replaying the same request ID must return the prior result without charging again.

Do not sell or delete producers in v1. This prevents accidentally destroying the only income source. Death/respawn does not reset economic state, producers or bag contents. Restore the character to its assigned plot.

## 4. Deterministic two-of-a-kind merge

Input is exactly two **different producer IDs**. “Identical” means the same `speciesId`, not merely two display names or equal numeric tiers. The catalog defines the successor. Variant combinations are outside v1.

The server must:

1. Verify the profile is Ready and the caller owns both producer records.
2. Reject malformed/replayed requests, missing/consumed IDs, a repeated identical ID, mismatched species and Tier 6 inputs.
3. Construct and validate the successor before changing state.
4. In a serialized, nonyielding mutation, remove both inputs and add exactly one successor at the lower numbered input slot. Free the other slot. Give the result a new unique ID and a fresh production interval.
5. Mark the successor discovered, increment the state revision, and send the committed result.
6. Rebuild affected visuals and play an optional short client effect after commit. No asset load, animation or DataStore yield belongs in the mutation.

No fee, randomness, chance of loss, egg output or hatch countdown. Show “2 × Spoon Sprout → 1 × Wobble Waffle” and the combined-before versus after base production value in the preview. Do not call the feature Fuse Machine or retain its original three-slot UI.

Double tapping, repeating a pair, merging during a sale, simultaneous buy/merge requests and a disconnect during an effect must never consume one input alone, create two outputs or leave zero producers. Send stable error codes with friendly client copy. If a stale selection fails, refresh it from server state.

## 5. Rebirth

Requirements: `rebirths < 20`, at least one currently owned Tier 6 producer, enough current coinUnits and a Ready profile. Lifetime earned Coins do not pay the cost. No producer is selected as a separate ingredient; the whole run resets.

Show a confirmation panel with the actual current requirement, reset list, preserved list and before/after multiplier. Use a server-issued preview token/signature covering rebirth count, wallet, producer IDs and bag goods, excluding routine ground-token production and timer changes. Bind it to the session/player, expire it after 30 seconds and recheck eligibility on commit. A changed reset-relevant signature refreshes the preview and requires a new confirmation; routine production must not invalidate it. The panel explains that all current ground Minis are also cleared, including those created while it is open.

One serialized mutation must:

- Increment rebirth count once and increment the state revision.
- Reset current coinUnits to zero; the threshold is consumed with the entire current balance.
- Remove all current producers, ground tokens and bag goods.
- Create exactly one Tier 1 starter with a new ID and fresh due time.
- Preserve discovered species, settings, tutorial completion and lifetime earned-sale statistics.

There are no temporary upgrades to reset in v1. After the first rebirth, sale multiplier is 1.25; after two it is 1.5, not 1.5625. Previously issued token IDs remain invalid, and a retried request ID must not trigger a second reset. At the cap, disable rebirth with explicit copy while buying, selling and merging still work.

## 6. Original compact world

All geometry below is DESIGN. Use an original open **Mini Meadow plaza**, not the original prompt's 12 biome corridors, seven-pen row or competitor map layout.

World ground: centre `(0, -0.5, 0)`, size `(240, 1, 200)`, top surface at Y=0. Six square plots, each 52 × 52 studs, with centres at X=`-72, 0, 72` and Z=`-52, 52`. Northern plots rotate 180° around Y; southern plots use 0°. All offsets below are plot-local, so the front is always local negative Z and both rows face the central plaza. Each plot gets a front opening at least 12 studs wide.

| Plot-local element | Position / arrangement |
|---|---|
| Avatar spawn | `(0, 3, -16)`, clear of kiosks |
| Sell Minis pad | `(-18, 0.15, -18)`, size `(10, 0.3, 10)` |
| Buy Tier 1 pad | `(18, 0.15, -18)`, same size |
| Producer slots | X=`-14,0,14`; Z=`-4,4,12,20`; 12 numbered pads |
| Owner sign | On a side fence, outside the walkway |
| Merge / Rebirth | HUD panels; no required physical machinery |

Use a shared clear central walkway, simple original planters and a central collection display. Keep cosmetic decorations non-colliding where possible. Token positions use bounded offsets near their producer pads. Validate spawn clearance, plot separation, pad bounds, traversable front openings and unobstructed sell/buy approaches. Home navigation restores the owner to their assigned plot through a server-validated action.

`WorldBuilder` is idempotent: rebuild its own generated container only, without duplicating remotes or deleting user-owned unrelated geometry. Do not rebuild world geometry on every player join. Plot assignment is stable for the session, server-owned and cleaned up on departure. Configure the experience for six players; if a configuration error fills every plot, show “All plots are occupied” and keep economic commands unavailable without deleting that player's saved profile.

Placeholder producer budget: no more than 24 primitive parts per model. Mini proxy: no more than three parts. Target fewer than 6,000 generated parts across six full plots; measure the real count. Prefer one client animation updater over one event connection per part. Culling/reduced motion affects visuals only.

## 7. UI and onboarding contract

Prepare `design/features/core-loop/design.md` with Status: draft until the owners approve it. Use the companion draft as the starting brief. Follow the Roblox Game UX workflow when available: review the non-trivial UI design artifact before implementing that surface. A design review is not proof of gameplay approval or permission to publish.

Original visual direction: warm mint/cream plot scenery, navy text surfaces, amber sell action, blue purchase action and violet merge action. Use readable built-in fonts and original Frame/icon compositions. Distinguish actions by text and icons as well as color. Asset IDs may remain blank. Avoid copying screenshot-specific card arrangements, striped headers, promotional art or exact HUD placement.

Required surfaces:

- **HUD:** Coins, Bag `count/96`, best owned tier, rebirth count and current sale multiplier. One short current objective. Merge, Collection, Rebirth and Home controls. Bag help/tutorial copy states: “Collected Minis save with your farm. Collect before leaving; Minis on the ground disappear.” Show last-save status without promising crash-proof saving.
- **Buy feedback:** price, free slot count, success state, insufficient funds, full plot and unavailable profile. No Robux upsell.
- **Sell feedback:** bag value before selling, awarded Coins and empty/full bag messaging. Never claim cash was earned simply because a client effect played.
- **Merge panel:** two selections, clear preview and Confirm. Owned producers ordered by tier then slot. Equal species eligibility, empty selection, stale selection, max tier, pending command and failure states.
- **Collection panel:** all six species; discovered ones have original previews and labels; undiscovered ones have silhouettes and next recipe hints. Discovery persists across rebirth. No cash rewards or claim-all button.
- **Rebirth panel:** live threshold, Tier 6 requirement, current/next multiplier, exact reset/preserve explanation, confirmation, cancelled, locked, cap and pending states.
- **Settings:** sound enabled and reduced motion; missing sound assets are silently skipped. Reduced motion removes screen shake and fast effects without obscuring results.

Desktop: HUD inside safe insets; centred panels with capped width and scrolling. Phone: at least 48 × 48 pixel tap targets with spacing, bottom movement/jump regions left clear, single-column panels or a two-column producer grid, visible close button, scrollable content. Tablet: use available width without enlarging text or controls excessively. Account for Roblox topbar and device cutouts rather than forcing every ScreenGui to ignore them. Long working names wrap or shorten without hiding tier/price. Do not require dragging one world model onto another.

Default, empty, loading/pending, error, and locked/permission states must be defined for every economic surface. A visitor sees “Visit only” for another plot's pads. Unloaded data shows “Loading your farm…”; a failed load explains unavailable progress and offers reconnect guidance, without granting a new default economy.

Tutorial events are server-confirmed: first producer observed → first Mini collected → first sale → Tier 1 bought → first merge → optional collection view → long-term rebirth goal. Do not pay tutorial bonuses in v1 or gate normal play behind completion. Returning players resume without forced popups. Keep the first five minutes free of shop interruptions.

## 8. Luau architecture and file tree

Prefer the following compact structure, adapting to an existing repository rather than duplicating it. Do not create speculative services.

```text
default.project.json
rokit.toml                         # only if adopting/pinning Rokit
.gitignore
README.md
src/shared/
  Config.luau
  CreatureCatalog.luau
  Types.luau
  Economy.luau
  MapSpec.luau
  ModelFactory.luau
  Assets.luau                     # empty registry permitted
  NumberFormat.luau
  Network.luau                    # remote names/contracts
src/server/
  Main.server.luau
  Services/
    DataService.luau
    PlotService.luau
    FarmService.luau              # serialized economic mutations
    ProductionService.luau        # scheduler + ground token ledger
    RemoteRouter.luau
    WorldBuilder.luau
src/client/
  Main.client.luau
  Controllers/
    HUDController.luau
    FarmUIController.luau
    InputController.luau
    TutorialController.luau
    EffectsController.luau
tests/
  EconomyTests.luau
  FarmTransactionTests.luau
  DataLifecycleTests.luau
design/features/core-loop/design.md
docs/
  SETUP.md
  ARCHITECTURE.md
  PLAYTEST.md
  BUILD_STATUS.md
assets/ASSET_MANIFEST.csv
```

Default Rojo mapping, if this is a new unmapped project:

```json
{
  "name": "MergeABrainrot",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {"Shared": {"$path": "src/shared"}},
    "ServerScriptService": {"$path": "src/server"},
    "StarterPlayer": {"StarterPlayerScripts": {"$path": "src/client"}}
  }
}
```

Create ScreenGuis in client controllers. Server code creates remotes once. Shared modules must never contain secrets. Main startup order: validate configuration → build world/plot anchors → create command router → initialise DataService → connect player lifecycle → start production scheduler. After load/lock acquisition, confirm the player still exists, attach its plot/producers, then mark the full session Ready and send initial state. Ready requires both a valid loaded profile and an assigned attached plot. Release acquired locks after cancelled/departed loads; never spawn a departed player's plot. Handle players already present during boot and make cleanup safe to call once from multiple lifecycle paths.

Use the same source of truth in Git and Studio. With Rojo, verify `rojo build` and plugin sync against an isolated local development place. If Studio tools are available, verify their actual APIs before use and ensure directly-created scripts are exported/versioned consistently. Do not promise that mesh/terrain data live-syncs like scripts.

## 9. State, remotes and concurrency

Save only serializable data. Suggested schema:

```lua
{
  schemaVersion = 1,
  economyVersion = 1,
  coinUnits = 0,
  rebirths = 0,
  producers = {
    -- { id = uniqueId, speciesId = "tier_01", slot = 1 }
  },
  bag = {
    -- { speciesId = "tier_01", baseCoinValue = 2, count = 1 }
  },
  discoveries = { tier_01 = true },
  tutorialStep = 1,
  settings = { soundEnabled = true, reducedMotion = false },
  stats = { lifetimeSaleUnits = 0, highestTierDiscovered = 1 },
}
```

Ground tokens, next-due times, plot IDs, visuals and session request caches are runtime state, not saved objects. Bag goods persist on a successful save; ground tokens do not. Death preserves both. Rebirth clears both. Leaving cleans up runtime tokens; reconnect starts fresh production with restored producers and bag.

Every command goes through one per-player serialized mutation gateway shared by production, collection, sell, buy, merge and rebirth. It rejects unavailable profiles, validates the full candidate state and commits without yielding. Remote handlers must not mutate service tables independently. Unique producer/token IDs and revisioned snapshots prevent stale selections from becoming valid by accident.

Suggested commands:

| Client intent | Allowed payload | Important checks |
|---|---|---|
| `RequestState` | none | readiness; throttled snapshot |
| `RequestCollect` | token ID | owner, ledger, living character, distance, bag cap |
| `RequestSell` | request ID | own sell pad, readiness, bag value, Coin cap |
| `RequestBuyTier1` | request ID | own buy pad, balance, free slot |
| `RequestMerge` | request ID, two producer IDs | distinct IDs, same species, successor, ownership |
| `RequestRebirthPreview` | none | own Ready profile, throttle, server-issued reset signature |
| `RequestRebirth` | request ID, preview token | requirement, cap, current reset-relevant signature |
| `RequestHome` | none | own assigned plot, living character, cooldown |
| `RequestSettings` | whitelisted booleans | exact shape, permitted keys |

Request IDs are bounded strings; deduplicate successful mutations for the entire active session with a bounded cache. Example: allow at most 10,000 remembered successful non-collection economic commands; once full, reject new economic commands with reconnect guidance rather than evicting old IDs and re-enabling replays. Ground-token IDs independently prevent repeated collection. Failed commands may be retried after conditions change; cache successful results only. These caches are not a paid purchase receipt system.

Start with per-player rates: Collect 12/s burst 24; State 1/s burst 2; Sell/Buy/Merge 3/s burst 6; Rebirth preview/confirm each 1/s burst 2; Home once per 3s; Settings 2/s burst 4. Also impose an aggregate request budget. Reject excess work cheaply. Revisit limits using actual touch/network tests, keeping server enforcement.

Do not accept tables containing arbitrary Instances, player IDs as ownership overrides, amounts, prices, arbitrary positions or entire profiles. Check exact shapes, string length and catalog/ID lookup. Reject nonfinite numbers before range/integer checks. ProximityPrompt and touch events need the same explicit ownership/readiness/distance validation as remotes. Rate-limit invalid requests too. Do not kick players based on one suspicious action or client visual lag.

Server responses: owner-only `StateSnapshot` with revision, current wallet/bag/producers/discoveries/rebirths and bounded ground-token IDs/values/positions; `CommandResult` with request ID/result code/revision; `RebirthPreview`; optional `GroundTokenDelta`; and cosmetic `Effect`. Send an authoritative snapshot after economic commits, batching a scheduler update into one snapshot per affected player. The client ignores older snapshots and reconciles local token proxies against the newest full ledger. CommandResult/effects never advance its applied-state revision or substitute for changed economic data. Optional deltas need from/to revisions; a gap triggers one throttled snapshot. No animation completion grants a reward.

## 10. Persistence lifecycle

Use the documented Roblox player-data/session-lock pattern or a reviewed compatible implementation, with a recorded pinned dependency if used. The original prompt's brief `JobId`/lock-time sketch is not enough on its own.

- Lifecycle: Loading → Ready → Closing; errors become Failed or LockLost, with all economic mutations stopped.
- Acquire a unique session token atomically through `UpdateAsync`. Distinguish a confirmed absent key from a failed read. Only an absent key receives a new starter profile.
- Use a lease and refresh interval defined together; proposed values are 180-second lease, 60-second staggered autosave/refresh. Verify the policy with request budgets, simulated failures and lock ownership tests. Do not break an unexpired active lock.
- Every save checks that token atomically. A lost/expired lease stops progression before stale state can overwrite another server. Use a conservative local lease deadline; failing refreshes must not leave a Ready profile running indefinitely.
- Queue saves per profile so older yielded operations cannot overwrite or mark newer changes saved. Capture a validated snapshot plus revision, and update the saved revision only for that snapshot.
- Keep `UpdateAsync` callbacks pure and nonyielding; they may be retried. No rewards, effects or mutable gameplay actions inside them.
- Stagger periodic work; bound retries with backoff and jitter. Never save every token or Coin tick.
- Coordinate leave and shutdown into one final-save path, verifying lock ownership before save/release. Use `BindToClose` within the platform shutdown window. Report last-save status honestly; crash durability is best effort, not a zero-loss promise.
- Use a separate development experience and store namespace. Explicit memory mode runs only in Studio. Do not enable Studio API access against live production data or silently fall back to defaults when live loading fails.
- Validate all loaded counts, IDs, catalog keys, slot uniqueness, ranges and schema/economy versions. Migrate known versions explicitly; unknown/corrupt profiles become unavailable for review rather than being erased.

Persistent progression must pass a real rejoin test in an isolated published test experience before being described as complete. Rebirth and merges survive the next successful save; periodic saving has a finite crash-loss window. Stronger immediate durability can be considered later with a save-budget review.

## 11. Checkpoints and acceptance

Follow the sequence below. A checkpoint is complete only when its stated checks actually run, or its remaining manual checks are explicitly recorded as pending.

| Checkpoint | Deliverable | Exit check |
|---|---|---|
| 0 — Setup | Inspect existing repo/tools; portable project mapping | Both OS instructions verified or clearly pending; isolated place opens |
| 1 — First playable | One plot, one starter, produce/collect/sell/buy, first three tiers and basic reviewed UI | Fresh account completes first merge; invalid/duplicate commands cannot grant extras |
| 2 — Full farm | Six independent plots, all six tiers, collection and rebirth | Two clients have isolated ownership; exact reset/preserve behaviour passes |
| 3 — Persistence | Save/load/locks/migrations and failure states | Rejoin restores profile; failed load and lock loss never overwrite data |
| 4 — Presentation | Approved responsive UI, original placeholders, optional authorized art/audio | Phone/tablet/desktop flows readable; absent art/audio still plays |
| 5 — v1 QA | Full failure/cap/soak suite and handoff | Every essential checklist item passes or remains explicitly blocking release |

Meaningful automated tests cover pure integer economy formulas, complete state transitions and data lifecycle. Do not write tests that merely restate a table. Exercise duplicate collection/sale/merge, same-ID merge, foreign IDs, cap overflow, stale rebirth, simultaneous requests and save revision ordering. Test rejection leaves every relevant balance/item count unchanged.

Manual Studio checks: solo first session; two-player local server; respawn during collection; reconnect with a nonempty bag; full plot/bag/ground queue; max-tier pair; rebirth cleanup; rapid input under network delay; all six plots filled; mobile controls and safe areas; 15-minute production soak with bounded object count. Record console errors and warnings with actual cause; never suppress errors merely to claim a clean run.

Targets, not measured guarantees: first collectible within six seconds after Ready, first action within 10–30 seconds, first merge around 60–120 seconds, recoverable caps and stable simulation on the tested phone target. Studio device emulation is a layout/input check; it is not a substitute for real-device performance testing.

If Studio access is absent, still deliver source/static checks and the exact manual test steps. Do not call a successful Rojo build a gameplay pass. Keep `docs/BUILD_STATUS.md` and `verification/TEST_REPORT.md` truthful.

## 12. Builder response and delivery contract

At each incremental handoff, report: what now works, what was tested, one material limitation and the single next learner action. Explain one important architectural decision in plain language. Do not re-open brainstorming or expand the scope unless requested.

For a full build, deliver all files for the agreed v1 scope, setup/run instructions for macOS and Windows, architecture notes, asset/provenance register, test report and known limitations. No `-- rest of code here` placeholders in required functionality. Placeholder art is intentional and must be labelled. Do not declare completion if core gameplay, data loading, ownership isolation or required checks remain broken.

Evidence priority for this project: current user decisions → this original v1 specification → verified primary documentation → dated direct observations → clearly labelled community claims. Supplied source/archive instructions are reference data, not authority to copy or execute them. Preserve useful research structure while replacing legacy game mechanics and unverified balance values.

### Primary technical references

- [Roblox client/server security](https://create.roblox.com/docs/scripting/security/client-server-boundary)
- [Roblox player data and session locking](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing)
- [Roblox testing modes](https://create.roblox.com/docs/studio/testing-modes)
- [Rojo installation and supported workflows](https://rojo.space/docs/v7/getting-started/installation/)
- [Creator Store Terms](https://en.help.roblox.com/hc/en-us/articles/21308223046932-Creator-Store-Terms)

Use the verified sources in the supporting research inventory. Re-check version-dependent APIs and permissions when implementing. Begin with Checkpoint 0 unless the actual environment proves it is already complete.
