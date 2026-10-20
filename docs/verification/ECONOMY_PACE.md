# Economy benchmark — 2026-10-19 latest refinement

The current configuration supersedes the earlier $1 million rebirth benchmark. First rebirth is $25,000 plus owned Level 6; each later rebirth adds $25,000. The first two single purchases are $5; subsequent base purchases add $1 to the next price. Merging does not reset the purchase counter. Bulk quotes sum the same price sequence, with higher-tier purchases consuming the equivalent base-unit count.

Run `tools/simulate_progression.luau` with Luau 0.743. This uses the real core, normal commands, actual earned money and production timing. It models an active player with two-second travel legs, a 0.8-second step-off before repeated purchases, aura pickup, automatic merging, and one affordable early processor upgrade. It buys until Level 6, then saves for rebirth. It assumes the baseline 1.00x event multiplier and no paid boosts or Lucky rewards; it is not a prediction for every player or for random multiplier sequences.

| Milestone | Simulated elapsed time |
|---|---:|
| First merge / Level 2 | 0:31.05 |
| Processor 5/s, paid $10 | 0:50.75 |
| Level 3 | 1:18.30 |
| Level 4 | 1:54.85 |
| Level 5 | 2:35.40 |
| Level 6 | 3:19.95 |
| First rebirth | 17:39.55 |

At rebirth: 34 purchases, 32 merges, 345 collected Minis, $25,709 gross revenue, one $10 upgrade, 242 cached transaction requests. No queue-capacity wait or ground-cap time occurred in this run. Continuing to spend every payout instead of saving materially delays rebirth.

Processor speeds are 2/5/10/18/31/52 Minis per second; upgrades cost $10/$30/$90/$250/$750. Bag and processor goods use compact batches, with a practical capacity of 2,147,483,647 items each and a separate finite money bound. A million-item payout regression checks arithmetic without instantiating a million objects. The ground still shows at most 96 Minis for rendering performance.

The shared event updates every 90 seconds. Its next value differs by 0.10–0.30, stays within 0.50–1.50, and moves inward at either endpoint. Production preserves fractional credit across cycles. Automated tests exhaust all 101 hundredth values and a 10,000-update random walk.
