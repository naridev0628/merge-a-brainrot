# Economy pace audit — 19 October 2026

This is a deterministic, optimistic active-play benchmark against the actual `FarmCore` command and production logic. It is not a human playtest or a claim about typical session length. No economy values were changed for this audit.

Run from the repository root:

```powershell
& './.tools/luau/luau.exe' 'tools/simulate_progression.luau'
```

## Assumptions

- Starting wallet $5; single producer purchase $5. One displayed dollar is four stored coin units.
- Every producer emits one mini every six seconds; minis take four more seconds to reach the tray.
- The starting processor handles two minis per second. The first two runs keep it unchanged; the third buys upgrades using earned money under the policy below. No game passes or Lucky windfalls are used.
- Two seconds of travel between each station: tray, intake, payout, single-buy pad, merge area, then tray again. Purchasing and merging each take 0.25 seconds.
- Collection is limited to three minis per 0.25 seconds, matching the client's request ceiling. The simulated player stands on the ground beside each collected mini; intra-tray movement and UI reading time are omitted. This makes it an optimistic benchmark.
- The first harvest waits for three Tong Tong minis. Later visits collect every ready mini that fits in the bag; an empty visit waits for the next arrival.
- A full processor queue forces the player to wait at intake until the whole carried bag fits. Payout claims only completed sales. Production continues during travel, queue waits, buying, and merging.
- Purchases always use the single-buy command. At each merge visit, all available equal-tier pairs are merged. All strategies finish the current merge visit after the first tier-six result.
- In the upgrade run, an actual wait for intake capacity triggers an upgrade check after the next payout. If the next upgrade is affordable, it takes priority over producer purchases. Buy at most one upgrade per affected circuit, then measure whether a backlog remains on the following circuit. The upgrade visit adds two seconds of travel plus 0.25 seconds of input time. There is no free money, credit, or upgrade granted in advance.
- The server's real ground limits, bag limits, spatial pickup checks, readiness checks, sale queue, request cache, and rebirth requirements remain enabled. The simulation issues normal commands and reads resulting state; it does not grant money, inject producers, skip conveyor time, or replace payout math.

## Measured milestones

All three strategies have the same opening. The first upgrade-triggering queue blockage occurs after the first tier-six producer appears.

| Milestone | Elapsed simulated play |
| --- | ---: |
| First Tong Tong purchased | 0:00.00 |
| First merge / Chimpanzini Bananini, tier 2 | 0:30.50 |
| Ballerina Cappuccina, tier 3 | 0:52.00 |
| Tralalero Tralala, tier 4 | 1:14.50 |
| Skibidi Toilet, tier 5 | 1:40.00 |
| Bombardiro Crocodilo, tier 6 | 1:58.50 |

The first three Tong Tong minis become ready at 10, 16, and 22 seconds. They sell for $6 total, which buys a second $5 Tong Tong and leaves $1. Travel, sale processing, and input cadence produce the 30.5-second first merge above.

| First-rebirth strategy | Time to successful rebirth | Producer mix just before rebirth | Minis collected | Time waiting for intake space |
| --- | ---: | --- | ---: | ---: |
| Stop buying after the first tier-six visit; save all earnings | 9:27:12 | One tier 1, one tier 2, one tier 6 | 16,977 | 0:00 |
| Continue buying and merging whenever affordable | 1:00:38.50 | One tier 1, one tier 3, one tier 4, 87 tier 6 | 6,840 | 14:33.75 |
| Continue expanding; prioritize affordable upgrades after an intake blockage | 0:46:13.50 | One tier 1, one tier 3, one tier 4, 87 tier 6 | 6,840 | 0:06.50 |

The expanding strategy bought 2,797 starters and performed 2,707 merges. It reached a $1,013,603 wallet before rebirth. The tray was at its 96-mini cap for 2,772.75 simulated seconds, about 76% of the run; production that cannot fit is discarded by the real Core rules. The saving strategy bought 35 starters, performed 32 merges, and reached $1,000,327. Neither strategy hit the 10,000 cached-request limit: the runs ended with 5,665 and 6,544 cached requests, respectively.

The upgrade strategy purchased the first processor upgrade at **3:34**, paying **$100** from earned cash for **five minis per second**. Its wallet after that purchase was $1,150. It encountered no further intake blockage, so the policy did not buy an unnecessary second upgrade. It reached rebirth with $1,012,352, using the same 2,797 starter purchases and 2,707 merges as the unupgraded expanding run. Ground-cap time fell to 1,892 seconds, about 68% of this shorter run. The run completed with 5,666 cached requests.

## Interpretation

Early unlocking is fast: the first top species appears in roughly two minutes in this uninterrupted benchmark. The $1 million first-rebirth requirement then creates a much longer second phase. Continued expansion reduces the measured first rebirth from more than nine hours to about one hour; using an earned-cash processor upgrade brings it to about 46 minutes, before learning time or interruptions.

At the starting processor speed, even an endless supply of only tier-six minis would sell at at most $340 per second: two minis multiplied by $170. Earning $1 million at that ideal steady rate alone takes about 49 minutes, before building the farm, travel effects, or earlier spending. A single tier-six producer emits $170 every six seconds, about $28.33 per second, so saving with a small farm is inherently much slower.

The unupgraded expanding run spends almost fifteen minutes waiting for processor intake capacity and remains at the ground cap for most of the session. The first processor upgrade removes almost all that intake waiting and makes this run **23.8% faster**, saving **14:25**. It therefore fixes the observed queue bottleneck, but it does not eliminate the long gap after the first tier-six unlock.

After that upgrade, continuing expansion and interacting with stations account for much of the remaining time. At 0.25 seconds each, the 2,796 subsequent single purchases and 2,707 merge inputs alone consume **22:55.75** of simulated time. Collection cadence and repeated station travel consume additional time. First-rebirth bulk-buy pads are locked by the existing rebirth requirements, so this run cannot replace those clicks with bulk purchases. Faster processor upgrades cannot remove this input or travel overhead once the queue already clears between visits.

This is one understandable player strategy, not an optimizer. A player who stops expanding at a different farm size, changes routes, or interacts at different speeds could reach rebirth at a different time. These measurements establish that the first processor upgrade substantially helps the specified loop; they do not establish the minimum possible rebirth time or prove that changing the rebirth price is the only remedy.

Potential tuning decisions should be reviewed with the owner: desired first-rebirth session length, whether the processor-upgrade tutorial makes its value clear, and whether rapid species unlocks followed by prolonged cash accumulation is the intended progression. This audit does not change purchase costs, production intervals, payouts, processor rates, or rebirth pricing.

## Validation

The final script completed all three runs through a successful real `Rebirth` dispatch. Every purchase, pickup, deposit, claim, merge, upgrade, and rebirth success is checked, and the script stops on an unexpected result or request-limit failure. Results are reproducible because Lucky rewards are disabled through the Core's supplied random function and time advances deterministically at the configured cadence.
