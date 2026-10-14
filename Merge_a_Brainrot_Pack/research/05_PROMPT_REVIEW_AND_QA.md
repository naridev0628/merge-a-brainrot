# Prompt review and QA

Document review is separate from running the game. All runtime tests below are pending until a builder executes them. Use the master prompt's checkpoint sequence.

| Test | Required outcome |
|---|---|
| New player | Exactly one Tier 1, zero Coins, assigned plot, first Mini in six seconds |
| Full loop | Collect → sell → buy → first merge without admin help or paid assets |
| Repeated collection | One token credited once; wrong owner/distance grants nothing |
| Repeated sale | Bag credited/cleared once; same successful request ID never recredits |
| Repeated purchase | Same successful request ID never charges twice; a new valid request can buy again |
| Invalid merge | Same ID twice, mismatched species, foreign/stale IDs and max tier preserve inputs |
| Valid merge | Exactly two consumed, one successor, one freed slot, new production clock |
| Combined actions | Concurrent sell/buy/merge/production cannot create negative Coins or partial state |
| Caps/stalls | Full bag/plot/ground queue and long frames remain bounded and recoverable |
| Rebirth | Actual threshold checked; reset and preserved data match confirmation; one starter and one increment |
| Stale rebirth | Changed reset-relevant signature refreshes; harmless ground production does not invalidate confirmation |
| Two clients | Economic ownership isolated even when players overlap in the same plot |
| Death/rejoin | Death retains economy; successful rejoin restores allowed saved state, no offline accrual |
| Data failure | Failed load, active foreign lock, expired/lost lease and corrupt schema never overwrite with defaults |
| Save ordering | Old snapshots cannot overwrite newer ones; leave/shutdown share one final-save path |
| Mobile | Large targets, readable values, scrolling/close controls, no blocked movement/jump regions |
| Missing assets | Every required flow still works with empty art/sound IDs |
| Soak | Fifteen-minute production run and six full plots remain within object budgets |

Automate economy and transaction invariants where possible. Manually verify Studio behaviour, rejoin persistence in a separate test experience and device layout/input. Record test environment, result, date, expected/observed behaviour and evidence path. “Not run,” “blocked,” “failed” and “passed” are different statuses.

The source prompt's old 74-item review/fix log cannot be inherited as a pass. The new build is not complete while first-session progress, ownership, profile integrity, mobile interactions or essential checks remain broken.
