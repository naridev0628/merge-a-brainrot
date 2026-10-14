# Original economy and progression

Status: DESIGN defaults, mathematically reviewed; no Roblox playtest performed. The master prompt is canonical if wording differs elsewhere.

| Tier | Mini value (base Coins) | Coins/minute at r=0 | Starter equivalents | Merge output gain versus two inputs |
|---|---:|---:|---:|---:|
| 1 | 2 | 20 | 1 | — |
| 2 | 5 | 50 | 2 | 25.00% |
| 3 | 12 | 120 | 4 | 20.00% |
| 4 | 29 | 290 | 8 | 20.83% |
| 5 | 70 | 700 | 16 | 20.69% |
| 6 | 170 | 1,700 | 32 | 21.43% |

Every producer emits one Mini every six seconds. Rate measures produced sale value; the wallet changes only when selling. Tier 1 costs 20 Coins. Two matching species merge without a fee or randomness. One Tier 6 requires 31 purchases from the free starter: 620 Coins spent. The twelve-slot cap is sufficient for a sequential merge ladder.

## Quarter-Coin ledger

Store integer coinUnits, four per Coin. For a bag with total base value B and r completed rebirths, sale credit is `B * (4 + r)` units. Purchase costs 80 units. This applies the bonus exactly once and gives the same reward for one large sale or several small sales. A Tier 1 Mini after one rebirth is worth 10 units = 2.5 Coins.

Rebirth needs an owned Tier 6 plus `10,000 + 2,500*r` current Coins; cap r at 20. Reset wallet, all producers and all ground/bag Minis; create one new Tier 1. Preserve discovery, tutorial completion, settings and lifetime earned-sale units. The multiplier progresses 1x → 1.25x → 1.5x, adding 25 percentage points each time.

Ground cap is eight per originating producer and 96 per plot. Bag cap is 96. Caps pause production without a hidden backlog. Ground Minis from merged producers remain sale goods and count toward the plot cap. The per-origin cap is independent of how many producers still exist. Selling and collecting remain available while buying/merging is capped. Ground goods are session-only; bag goods persist after a successful save. Make this visible in leave/save guidance. No normalization or offline generation is implied.

## Transparent pace check

An illustrative six-second event model assumes immediate collection/sale, no travel/UI delay, purchasing whenever affordable, merging matching pairs immediately, and stopping new purchases once the first Tier 6 exists. New and merged producers start fresh clocks. It is not an optimal-strategy claim.

| Milestone | Illustrative elapsed time |
|---|---:|
| First Tier 2 | 60 s |
| First Tier 3 | 102 s |
| First Tier 4 | 138 s |
| First Tier 5 | 168 s |
| First Tier 6 | 192 s |
| First rebirth | 546 s (9 m 6 s) |

At the final merge, 620 Coins have been spent and 89 remain. Fifty-nine additional Tier 6 Minis produce 10,030 Coins, reaching 10,119 at 546 seconds. Actual travel, collection caps, input, buying extra producers and save/loading time change the pace. Real first-session targets: first action within 10–30 seconds, first merge around 60–120 seconds, first rebirth around 9–15 minutes.

Because rebirth price and multiplier increase by the same linear factor, saving with one Tier 6 takes approximately the same time each run; rebuilding gets faster. This is an initial simplicity choice, not a finished retention strategy. Measure boredom, production stalls and whether buying versus saving is understandable before adding progression layers.

No-softlock checks: the last producer cannot be sold/deleted; merging always creates a replacement; rebirth creates a starter; max-tier producers still earn; full plot does not disable collection/selling; invalid actions preserve all balances/items; failed profile reads never reset a saved economy.
