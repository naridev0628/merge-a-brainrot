# Chicken Farm reference implementation — 2026-10-20

The twelve-frame annotated board in `docs/reference/chicken-farm-video/index.html` now records each applied adaptation, with local implementation captures. No source-game screenshot is mapped into the Roblox build.

## Behavior and presentation

- `TextStyle` shares Fredoka One, cream action text, lime prices and dark outlines across HUD and world signs. Species labels wrap inside their bay rather than overlapping adjacent Brainrots.
- The rear shelf grows from 67 to 101 logical studs across the 112-stud conveyor area. End trees remain outside the widened bays. Existing mirrored utilities, fences, bridge landings and full red tray remain intact.
- The group-board text sits on a separate unobstructed front face. Its message remains honest about the unconfigured reward. Processor text shows queue/rate without an unimplemented friend boost.
- Lucky remains nonmodal, with real 75/20/5 odds and cost. Its content scrolls on short portrait layouts instead of collapsing reward rows or losing Unlock/Discard.
- The larger woven basket has a cream total inset. Gold pickup gains aggregate into no more than six reusable popups and expire.
- Cash effects cap at 150 parts, with smaller repeated claims. Deposit portraits cap at six and replace the previous layer. Purchase previews cap at four. Discovery shows the reward portrait and name without “You have received” prose.
- Tier accents run at 10 Hz for at most sixteen nearby eligible producers, with two parts each. They never attach permanent effects to Minis and clear on removal or distance culling.
- `FeedbackAudio` reuses three Sounds, throttles repeated events, stays silent for rejected purchases and uses quiet pitch patterns from the already-cleared project cue. Video audio was not extracted or audited.

## Verification performed

- All 46 source files compiled with the local Luau compiler.
- All 22 standalone test files passed, including the 50 producer/token caps, exact shared affordability quotes, immediate pad entry and slower held repeat, production cadence, pickup aura and replay/ownership checks.
- `studio-layout.client.luau` passed at 640×280, 390×690, 390×700, 640×450, 390×844, 1440×900, 320×480, 390×440, 360×568 and 390×600. It checks content bounds, nonblocking Lucky behavior, price/odds, readable reward text, scroll reachability, pickup aggregation/expiry and actual rebirth rewards.
- `studio-environment.server.luau` passed for geometry, protected corridors, board face, widened shelf and decoration limits. Existing mirrored-plot and pad-affordability fixtures also passed during this implementation pass.
- `studio-producer-grounding.client.luau` passed for both standard and sideways procedural pivots throughout the production animation.
- `studio-effects.client.luau` passed for repeated cash/deposit budgets, expiry, tier culling and grounded producer bounds.
- `studio-audio.client.luau` passed after fixing default voice volume and reusing the pool across repeat initialization. The asset reports loaded in Studio; this is not a subjective audio comparison with Chicken Farm.
- Visual checks inspected the populated ten-bay row, world signs, farmer/deposit, desktop Lucky card, compact portrait scroll viewport and rebirth panel. Temporary UI states and display specimens were removed afterward.

## Limits

Studio viewport fixtures are not physical-device or multiplayer load tests. Persistence, configured purchases/group reward, global rankings, owner asset permissions and release validation remain separate work. The experience has not been published by this pass. Precise source-game font, timing and sound assets are not claimed to be identical.
