# Checkpoint 1 verification — 2026-10-19

Scope: one Studio plot, three tiers, memory only. This report describes executed implementation checks; the supplied pack's reports remain historical document checks.

## Automated checks

- Luau 0.743: all 13 tests in `tests/run.luau` pass. They cover earning the first merge and Tier 3 without grants, integer sales, replayed collection/sale/buy/merge, request-ID misuse, invalid/dead/distant requests, foreign IDs, full bag/plot, overflow, capped production and catchup, retired tokens, closing sessions, cache limits and token-bucket throttling.
- Strict standalone analysis passes for FarmCore, RateLimiter, Config and CreatureCatalog. Roblox-dependent modules are not claimed to pass standalone type analysis without Roblox definitions.
- All 10 source files compile with `luau-compile --null`.
- Rojo 7.7.1 builds `build/MergeABrainrot-FirstPlayable.rbxlx` successfully.
- `tests/studio-layout.client.luau` runs successfully in the Studio Client: at a 640×280 safe area, the scroll viewport is 68 pixels tall and cards are 48 pixels tall; feedback renders above the merge overlay.

## Interactive Studio evidence

- Fresh session starts with one Spoon Sprout, zero Coins and an empty bag. Actual scheduled production and proximity collection were observed. The exact six-second boundary is covered by domain tests; first-token latency was not separately timed in Studio.
- Walked the avatar to Minis, then the Sell pad: nine Minis paid 18 Coins. Collected and sold three more for a balance of 24 Coins.
- Walked to Buy and clicked the real contextual button: balance became 4 Coins with two Tier 1 producers.
- Clicked Merge, selected both actual cards, inspected the preview (4 → 5 base Coins / 6s, no fee), and confirmed. Result: one Wobble Waffle in slot 1, balance still 4 Coins, Tier 2 discovered.
- Respawned the actual player: Waffle and coin balance survived; character returned to the home position.
- Fresh-session remote probe: foreign producer IDs returned MissingProducer. A burst of 70 malformed Buy messages produced six BadRequest replies; the rest were silently throttled. Wallet stayed zero and producer count stayed one. An initial probe incorrectly expected InvalidPayload and explicit RateLimited replies; inspection corrected the probe expectation, with no production code change.
- Restarted after final changes. Visually verified spawn faces the starter farm, and ran the saved UI regression script successfully.
- Inspected desktop and iPhone 17 Pro simulator screenshots in landscape and portrait. Landscape safe area: 750×323, card 300×48, list 616×111. Portrait safe area: 401×720, card 345×64, list 353×400. Replaced an unsupported close glyph with plain X.
- Independent code review found hidden feedback behind the merge modal and insufficient list height on very short screens. Both were reproduced, fixed and regression checked.
- Fixed an initial client startup race by waiting for replicated UI/config modules before requiring them.

## Build and synchronization

Source lives on `codex/first-playable`. Opened the Rojo-generated place in a separate Studio instance. During iteration, copied exact filesystem source into that place's Edit DataModel through the Studio connector; no separate handwritten Studio source was maintained. Rebuilt the final file from disk. This first-playable window is not claimed to have an active Rojo live-sync connection.

## Limitations and unrelated console output

No persistence, published server test, six-client test, physical-device test, Mac execution, latency simulation or performance soak was run. The first-merge pacing was not measured because tool interaction introduced pauses. Tier 3 progression is verified in the domain suite, not a second full interactive playthrough. The live-server refusal is present in source; no experience was published to test it.

The installed `cloud_9643911698.Superpower.LocalScript` still reports a syntax error. Studio CorePackages produced UIBlox FoundationProvider warnings and an avatar asset-type mismatch for asset 203785492. Project models use no external asset IDs. These unrelated messages were not suppressed; no globally clean-console claim is made.

Next learner action: open the generated first-playable place, press Play, and try collecting ten Minis for your first merge. Progress resets when Play stops.
