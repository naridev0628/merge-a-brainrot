# Merge a Brainrot — core loop UI design brief

Status: draft

Version: 1.0 · 2026-10-14

Scope: HUD, contextual buy/sell feedback, two-of-a-kind merge, collection index, rebirth, settings and first-session objectives. This is a design contract for a future Roblox interface, not implemented UI or a playtest report. The master `MERGE_A_BRAINROT_ONE_SHOT_PROMPT.md` is canonical for gameplay, data and formulas. All visual choices here are original design defaults. This task produces the draft; it does not request approval or begin implementation. The future workflow reviews this artifact before implementing a non-trivial UI surface.

## User goal and experience

A first-time player should understand one useful action immediately: collect the Mini made by their starter. They then see that selling fills their wallet, buying adds another producer and merging improves production. Players can read the next benefit without learning a complex inventory system. A returning player sees their restored farm and can resume the loop without introductory popups.

The game is solo progression within a six-player shared server. Other farms are visible social displays. A visitor cannot collect, buy, sell or merge another player's goods. The first five minutes prioritize movement and the core loop. No Robux upsells, claim rewards, events, daily calendars, stealing or competitive leaderboard surfaces belong in this brief.

## Visual language and reusable patterns

Use simple rounded panels, readable built-in fonts, original Frame/icon compositions and team-created primitive creature previews. Create a playful garden/workshop feel with cream and mint scenery, dark navy panels and clear action colors. A missing icon, preview image or sound must leave a complete text-labelled interface. Do not trace competitor cards, striped headers, screenshot-specific HUD placement, proprietary creatures, voices or promotional art.

| Role | Proposed color | Use |
|---|---|---|
| Mint | `#B6DFCA` | Plot scenery and quiet decorative surfaces |
| Cream | `#FFF4DC` | Warm scene accents; light text on dark panels |
| Navy | `#18323F` | Panel backgrounds and text on light action buttons |
| Deep navy | `#122530` | Short shadows and modal backdrop |
| Amber | `#F5BC48` | Sell action, with navy text |
| Blue | `#77B9F5` | Buy action, with navy text |
| Violet | `#6E4BC4` | Merge action and selected cards, with cream text |
| Soft red | `#FFADAD` | Error callouts, with navy text and an explanatory label |
| Muted slate | `#56727D` | Quiet borders and disabled surfaces; lock/reason text remains readable |

Use text plus a simple icon or shape to identify every action. Color alone must not communicate affordability, selection, error or permission. Rebirth uses an explicit reset/loop icon and the word “Rebirth,” so its violet-accented panel is distinguishable from Merge. Give Confirm and Cancel visibly different emphasis without hiding Cancel.

Body and button text target 16–18 rendered pixels; key values target 20–24. Supporting labels may use 14 only if they remain readable in the phone checks. Avoid shrinking all text to fit a panel. Long working names wrap to two lines; tier, value and action stay visible. Use consistent number alignment and spacing. An enabled, pressed, pending, selected and disabled appearance must be distinguishable without motion.

## Responsive layout and safe areas

Use the available safe content rectangle after accounting for Roblox's topbar, device cutouts and system gesture areas. Keep at least 12 pixels of additional breathing room inside safe edges on phone and 16 on larger surfaces. Do not solve layout by forcing all ScreenGuis to ignore insets.

| Surface | Phone | Tablet | Desktop |
|---|---|---|---|
| HUD | Compact top farm bar: Coins and Bag prominent, then a readable secondary line for best owned tier, rebirth count and multiplier. One objective below. Arrange labelled actions in one or two short rows according to safe width. | Spread farm values across a top bar; objective below or alongside. Keep actions together and leave the centre view open. | Farm values at upper left, current objective near upper centre, menu actions grouped at upper right. Keep the farming area visible. |
| Menus | One centred surface at a time, max width 520 pixels, fitting the safe rectangle with 12-pixel margins. Scroll body content; header and close button remain visible. | Centred panel, max width about 720; use two or three columns where cards remain readable. | Centred panel, max width about 840; grids may use three or four columns. No screen-wide modal just because space exists. |
| Merge grid | One column on narrow portrait widths; two columns only if each card still has readable name/tier and a full touch target. Selection/preview remains above or outside the scrolling list. | Two or three columns with stable selection summary. | Three or four columns; preview and action footer remain visible. |
| Contextual Buy/Sell | One short context card near the lower middle of the usable view, above native movement/jump controls. If that region is obstructed, move it upward; do not overlap native controls. | Compact context card above the active world pad, with a stable large action button. | Compact pad/context card with keyboard hint and clickable button. |
| Confirmation footer | Within the safe panel; stacked full-width actions if side-by-side buttons would be cramped. | Side-by-side Confirm and Cancel with generous space. | Side-by-side actions, matching the tablet order. |

All actionable touch targets, including close buttons, settings toggles and producer cards, are at least **48 × 48 rendered pixels**, with at least 8 pixels between neighbouring targets. A small drawn icon still needs the full hit area. Measure after scaling. Keep the bottom-left movement area, bottom-right jump area and device gesture strip clear. Opening a panel must not cover its own close control or require precision dragging, right click or hover.

On a short landscape phone, compress secondary HUD spacing before sacrificing touch targets or body text; scroll modal content instead of clipping it. On portrait phone, let action rows and producer grids reflow naturally. Support the tested phone/tablet orientations in the UI; record any untested orientation. Modal input must not click through to a world pad. Close/Cancel returns to the same farm view and restores the player's prior list position. Desktop Escape closes the topmost ordinary panel; clicking Confirm never relies on Escape behavior.

## Exact values and copy contract

The UI displays authoritative server values. A pending animation does not grant Coins or a producer. Show the last confirmed value while a command is pending; disable only the affected action. Reconcile from the latest server snapshot after success, rejection or reconnect.

| Item | UI contract |
|---|---|
| Wallet | Four integer `coinUnits` equal one displayed Coin: `Coins = coinUnits / 4`. Show quarter fractions when present (`6.25`, `6.5`, `6.75`); whole numbers need no `.00`. Compact abbreviations are allowed in the HUD, with exact values in details. |
| Purchase | “Buy Tier 1 · 20 Coins.” Cost is 80 coinUnits. Show free slots out of 12. Buying requires the owner's Buy pad and a free slot. |
| Production | One Mini per producer every six seconds. Tier values are 2, 5, 12, 29, 70 and 170 base Coins. Wallet value increases on selling, not merely on production. |
| Bag | Total individual Mini count, not number of groups: `sum(group.count) / 96`. A grouped bag's base value is `sum(group.baseCoinValue * group.count)`. |
| Sale | For `r` completed rebirths: `saleCreditUnits = bagBaseValue * (4 + r)`; displayed sale Coins are `saleCreditUnits / 4`. Apply the bonus once at sale. |
| Rebirth | Requires one currently owned Tier 6 and `10,000 + 2,500*r` current Coins; max 20 completed rebirths. Current sale bonus is `1 + 0.25*r`. First transition is `1× → 1.25×`; next is `1.25× → 1.5×`. |
| Goods lifecycle | Bag goods persist after a successful save. Ground Minis are session-only. Death keeps the bag and ground goods. Rebirth clears both. No offline production occurs. |
| Capacities | 12 producers, 8 ground Minis per originating producer, 96 ground Minis per plot, 96 in the bag. Production pauses at capacity and has no hidden backlog. |
| Wallet cap | 4,000,000,000,000 coinUnits, equal to 1,000,000,000,000 Coins. An overflowing sale is rejected and leaves the bag intact. |

Working species names: Tier 1 Spoon Sprout, Tier 2 Wobble Waffle, Tier 3 Bubble Boots, Tier 4 Disco Turnip, Tier 5 Noodle Comet, Tier 6 Toaster Monarch. Stable species IDs determine recipes; editable names and original placeholder previews must not affect saved identity.

Use short, specific copy: “Bag full — sell your Minis,” “No free slots — merge a matching pair,” “Visit only,” “Choose two matching producers,” “Already collected,” and “That selection changed — choose again.” Use “Coins,” “Mini,” “producer,” “Merge,” and “Rebirth” consistently. Do not call producers eggs, imply Minis can be merged, or call Merge the old three-slot Fuse Machine.

## HUD and current objective

Required HUD facts: Coins, Bag `count/96`, best currently owned tier, completed rebirth count, current sale multiplier and one short objective. Required controls: Merge, Collection, Rebirth, Home and Settings. Home returns to the assigned plot through the server; never pretend a teleport succeeded before confirmation. The collection progress indicator may read `1/6 discovered` beside Collection, without a reward badge.

| State | Presentation and behavior |
|---|---|
| Default | Confirmed farm facts, clear action labels and one objective. A brief `+2 Coins` or `Collected 1 Mini` feedback resolves quickly without blocking movement. |
| Empty | `0 Coins`, `Bag 0/96`, starter's tier and `1/6 discovered` are meaningful values, not an error. No producer is selected by default. An unexpected missing producer/profile is unavailable state, not permission to grant a starter locally. |
| Loading/pending | “Loading your farm…” with quiet placeholders until profile and plot are Ready. Home/economic controls are unavailable. Pending commands keep existing totals visible; avoid a fullscreen spinner. |
| Error | A compact persistent message for load/lock/save trouble. Failed load: “Your farm could not load. Rejoin to try again.” Keep economic commands unavailable. Save delay: “Saving is delayed” with the actual last-save status, without claiming progress is safely stored. |
| Locked/permission | Full bag: “Sell your Minis.” Full ground: “Collect Minis to resume production.” Another plot's context reads “Visit only.” At rebirth cap, show completed count and keep ordinary farming controls available. |

Bag help includes: “Collected Minis save with your farm. Collect before leaving; Minis on the ground disappear.” Show `Last saved …` only from actual save confirmation; Studio memory mode displays “Studio test — progress is not saved.” Avoid “All progress saved” before a successful save or a promise that crashes cannot lose progress.

## Buy Tier 1

Use one contextual card at the owner's Buy pad. Show the 20-Coin price, Tier 1 preview, `used/12` slots and current affordability. Purchase is an explicit button/keyboard interaction; standing near the pad must not buy repeatedly. After confirmed success, briefly highlight the new producer's slot and show “Spoon Sprout added.” A new intentional click may buy another producer if eligible.

| State | Presentation and behavior |
|---|---|
| Default | Enabled “Buy Tier 1 · 20 Coins” when funds, readiness, own-pad distance and slot checks pass. |
| Empty | At zero Coins, retain the price and preview with “Sell Minis to earn Coins.” Do not replace the card with a blank panel. |
| Loading/pending | Disable purchase while profile loads or one purchase is awaiting its result. Show “Buying…”; no local wallet subtraction or duplicate charge. |
| Error | Show the server's friendly failure reason. If distance changed: “Return to your Buy pad.” Preserve wallet and producer state until the server confirms changes. |
| Locked/permission | Insufficient funds: show exact shortfall. Full plot: “12/12 slots — merge a matching pair.” Visitor: “Visit only.” LockLost/Failed profile: unavailable message, no purchase prompt. |

Desktop may offer E while the own-pad interaction is active, alongside the clickable button. Touch uses the same labelled large button. Rapid taps are a single pending purchase, with the same request identity on retries. No bulk buy or Robux alternative.

## Sell Minis

Within own-pad range, show bag count, exact total sale value and current multiplier before sale. Entering the actual Sell pad triggers one whole-bag sale per entry; an explicit “Sell Minis” button remains available while standing there. Do not sell every frame. After confirmation, show the awarded amount, clear the displayed bag through server state and briefly highlight the wallet.

| State | Presentation and behavior |
|---|---|
| Default | “Sell 10 Minis · 20 Coins” at rebirth zero, adjusted to the actual bag and multiplier. Explain the award before the action without a modal. |
| Empty | “Bag empty — collect Minis.” Sale action disabled; entering the pad awards nothing. |
| Loading/pending | “Selling…” with prior bag/wallet visible until confirmed. A replayed success does not replay a second award animation as if it earned again. |
| Error | Distance/readiness/command error keeps goods intact unless newer server state proves a committed sale. Reconcile before allowing a new retry. |
| Locked/permission | Visitor: “Visit only.” Wallet overflow: “Wallet limit reached — your Minis are still in your bag.” Bag full elsewhere points to this pad, not an extra purchase. |

Bag tokens from merged producers remain sale goods at their captured base value. The UI never reprices them from current art, tier labels or a later catalog change. No individual token-price editing, selling producers or delete-producer control exists.

## Merge

Order owned producer cards by tier and then slot. Each shows an original preview, name, tier, numbered slot and base output per six seconds. The player selects two distinct matching producers by tapping/clicking cards. Selected cards get numbered markers `1` and `2`, a visible border and a Remove action. Never depend on dragging world models.

Keep the recipe preview and Confirm visible outside the scrolling card list. Example: “2 × Spoon Sprout → 1 × Wobble Waffle,” then “Together now: 4 base Coins / 6 s · After merge: 5 base Coins / 6 s.” Explain “Frees 1 slot · No merge fee.” The two selected IDs, not display names, determine the request.

| State | Presentation and behavior |
|---|---|
| Default | One selection narrows/highlights eligible identical species. Two eligible selections reveal exact output and enable Confirm. Cards remain inspectable. |
| Empty | No selected pair: “Choose two matching producers.” With only one producer: “Buy another Tier 1 to make your first pair.” A farm with no matching pair shows a useful next-buy hint. |
| Loading/pending | Farm loading uses skeleton/text placeholders. During merge, keep the preview visible and disable selection/Confirm for that request; allow the panel to close without cancelling an already submitted server action. |
| Error | Stale/consumed IDs: “That selection changed — choose again.” Clear invalid selections and refresh owned state. Failed command does not remove a card locally or leave half a pair. |
| Locked/permission | Tier 6: “Highest tier — keeps producing Minis.” Mismatched species or same producer twice cannot confirm. Another player's producer never enters the selectable list. Unavailable profile blocks the action. |

Confirmed success removes both inputs and inserts the successor from server state. The successor occupies the lower numbered input slot and starts a fresh six-second interval. A short glow/pulse can draw attention to the result; reduced motion uses a static highlight. Close/Cancel before submission consumes nothing. Ground Minis from those inputs remain collectible and saleable.

## Collection index

Show exactly six cards and `discovered/6`. This panel teaches the ladder and preserves progress across rebirth. Discovered cards show original previews and name/tier/base Mini value; undiscovered cards show a silhouette plus next recipe hint. There is no cash reward, claim-all button, limited tab, loot odds or paid unlock.

| State | Presentation and behavior |
|---|---|
| Default | Show discovered cards clearly and the next recipe: two Tier 1 → Tier 2, through two Tier 5 → Tier 6. Tier 6 says “Highest tier.” |
| Empty | No search/filter results are not needed in this six-card v1. A not-yet-discovered card is a silhouette with a recipe hint, not an empty asset slot. |
| Loading/pending | “Loading your collection…” until authoritative discovery state arrives. Do not make unrevealed previews briefly visible. |
| Error | A missing preview falls back to the name/tier and original simple shape. A profile error leaves collection progress unavailable instead of resetting discovery to zero. |
| Locked/permission | Undiscovered cards may be inspected for the recipe, but cannot claim/unlock anything. The index is the player's own persistent record, not authority over a visited farm. |

Optional card inspection opens an inline detail area rather than stacking a second fullscreen modal. A discovery notification is brief and names the new species. Return to farming without forcing the player to open the index.

## Rebirth and confirmation

Show current Coins versus the exact current threshold, owned Tier 6 requirement, completed rebirth count and current/next sale multiplier. Do not imply lifetime earned Coins pay the threshold. The first requirement is 10,000 current Coins and an owned Tier 6. The cost at one completed rebirth is 12,500 Coins. At 20, show “Rebirth complete — keep building your farm.”

The final confirmation explains the entire reset: wallet becomes zero, every producer and every ground/bag Mini is removed, then one new Tier 1 starter appears. Any balance above the threshold is also reset. Preserve discoveries, preferences, tutorial completion and lifetime earned-sale statistics. Give Cancel a full touch target alongside the explicit “Rebirth and reset farm” action.

| State | Presentation and behavior |
|---|---|
| Default | Eligible farm shows exact requirements, reset/preserve list and a server-issued confirmation preview. Show `1× → 1.25×` for the first rebirth. |
| Empty | With no eligible Tier 6, show “Merge toward Tier 6.” With low wallet, show the exact Coin shortfall. Do not hide the future benefit. |
| Loading/pending | “Checking your farm…” while obtaining the preview. “Rebirthing…” after submission; no local reset until the result and authoritative farm state arrive. |
| Error | Expired or changed preview: “Your farm changed — review the reset again.” Refresh the relevant totals and require a new explicit confirmation. Failed action preserves the current farm. |
| Locked/permission | Missing Tier 6, insufficient funds, unavailable own profile or count 20 disables Confirm with the actual reason. Visiting another plot does not expose a rebirth action for its owner. |

The preview token is bound to the player's active session, expires after 30 seconds and covers rebirth count, wallet, producer IDs and bag goods. Routine ground production and timer ticks do not invalidate confirmation. The panel states that all current ground Minis, including new ones produced while it is open, will be cleared. A wallet/bag/producer change requires a refreshed preview. Cancel before submission changes nothing; closing after submission does not reverse a committed rebirth. A retried request cannot reset twice.

## Settings

Offer only Sound and Reduced motion in v1. Use labelled toggle rows with a full touch target, visible On/Off state and one-line explanations. Reduced motion removes fast pulses, screen shake and sweeping effects; it must retain selection, confirmation, error and success information. Sound is optional and disabled assets are skipped silently; do not claim a SoundId is available when it is not.

| State | Presentation and behavior |
|---|---|
| Default | “Sound: On/Off” and “Reduced motion: On/Off,” reflecting confirmed preferences. No volume mixer or graphics presets required. |
| Empty | No audio asset is configured: “Sounds will play when available.” Both rows remain understandable and reduced motion stays usable. |
| Loading/pending | Mark preferences as loading or “Updating…” while awaiting their confirmed state. Local accessibility presentation can respond immediately, with persistence status kept distinct. |
| Error | If preference persistence is unavailable, retain a clear local/session presentation choice and say “Preference is not saved yet.” Never portray a failed profile write as saved. |
| Locked/permission | No paid or role lock. During profile failure, local presentation preferences remain usable, while saving them is unavailable. A visitor changes only their own preferences. |

Settings must not grant progress or mutate a farm. Close returns to the previously active farm view; do not reopen the tutorial.

## One-objective onboarding

Show a single short objective at a time, plus a restrained world marker when helpful. Move the objective forward from server-confirmed progress; opening a menu alone cannot claim an economic action happened. These objectives are teaching hints, not gates or reward claims.

| Stage | Objective copy | Marker/feedback |
|---|---|---|
| Starter available | “Your Spoon Sprout makes a Mini every 6 seconds.” | Point toward the starter; keep the waiting instruction brief. |
| First Mini available | “Walk near your Mini to collect it.” | Highlight one owner token, not every object in the server. |
| First collection | “Sell your Minis at the amber pad.” | Own Sell pad marker; show exact bag value. |
| First sale | “Save 20 Coins, then buy another Spoon Sprout.” | Own Buy pad marker; normal collection/selling remains available. |
| First purchase | “Merge two matching producers.” | Gentle emphasis on Merge, without forcing it open. |
| First merge | “Discover the next tier with matching pairs.” | Optional “View Collection” suggestion; no blocking modal. |
| Longer-term goal | “Reach Tier 6 and save for your first rebirth.” | Actual current threshold in the Rebirth panel, no constantly flashing badge. |

First useful action target: 10–30 seconds after a successful load. First merge target: approximately 60–120 seconds. First rebirth target: roughly 9–15 minutes. These are hypotheses, not measured guarantees. Returning players resume their saved stage without replaying introductions. A capped bag/ground queue temporarily replaces the objective with its recovery action, then resumes the progression hint.

## Ownership, asynchronous work and feedback rules

The UI never consumes a Mini, charges Coins, advances discovery or resets the farm on its own. A pending command keeps the previous confirmed state visible. A success response and updated authoritative state resolve the pending control together. Older snapshots cannot replace newer data; cosmetic effects cannot advance applied state. A timeout says the result is being checked, asks for authoritative state and avoids creating a fresh purchase/reset just because the first response was late.

Visited pads show their owner and “Visit only”; no actionable Buy/Sell button or misleading affordance. Own-pad distance failure returns a navigation hint. Bag full and ground full are recoverable information, not purchases or punishments. Short reward toasts do not cover targets, interrupt movement or accumulate off-screen. One persistent data-status message takes priority over transient toasts.

Player collections remain visible across the plaza through readable world labels/previews. The private HUD does not mirror another owner's wallet or expose their private bag. Discovery and best currently owned tier are different facts: rebirth may reduce the owned tier to 1 while discovery stays 6/6.

## Verification plan for a future implementation

These checks are planned, not passed. Record actual devices, orientation, viewport, input conditions and observations when the interface is implemented.

- **First-action time:** fresh profile, starter visible, one objective, first collection within the target range; no setup wall, forced menu or shop popup before play.
- **Friction:** ten Tier 1 Minis fund the first purchase; exact prices and merge before/after values are understandable without an external guide. Cancel is safe and discoverable.
- **Phone and tablet:** safe insets, 48-pixel rendered touch targets, 8-pixel spacing, visible close/Confirm buttons, scrolling, long names, portrait/landscape reflow, and no overlap with movement/jump/system gestures.
- **Desktop:** clickable controls, contextual keyboard hint, predictable close behavior, legible exact values and no required hover/right click.
- **Every state:** empty bag, one producer, no pair, max tier, full plot/bag/ground, insufficient Coins, rebirth cap, visitors, profile load failure, lock loss, delayed saves and missing art/audio are understandable and recoverable where applicable.
- **Delay/retry:** double tap, late response, replay, out-of-order snapshot, stale pair and changed rebirth preview neither grant extra resources nor leave false success feedback.
- **Persistence communication:** bag/ground distinction is visible; memory mode is labelled; last-save copy matches actual confirmed saves; reconnect restores allowed state without replaying the introductory flow.
- **Progression and social signals:** production value, slot recovery, discovery progress and rebirth benefit remain clear; visitors can admire other farms without controls suggesting authority over them.
- **Reduced motion and sound:** success/error/selection remain understandable with animation and sound removed; no missing asset blocks a control.

Future UX review should report first-action time, friction before play, mobile-control risks, missing progression signals, social visibility gaps and any interruption to the loop, with priority fixes ranked by their impact on completing the first session. Layout/input emulation does not establish real-device performance. Implementation and live release remain separate checkpoints from this draft.
