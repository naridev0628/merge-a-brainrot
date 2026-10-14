# Implementation research and requirements

Verified primary documentation on 2026-10-14. Game-specific choices are defined by the master prompt, not claimed as Roblox rules.

Roblox advises validating client input, ownership, distance and timing, rejecting malformed/nonfinite values, and applying server-side rate limits. Proximity/touch interactions also need server checks. Use anchored collectible proxies with a server ledger. [Client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary).

For this game, keep one serialized nonyielding economic mutation path. It commits production, pickup, sale, purchase, merge and rebirth. Prepare/validate replacement state before consuming inputs; apply visuals afterward. Distinct IDs prevent same-item merges and repeated pickup. Clients send intent, never amounts or result tiers. UI debouncing improves feedback but does not protect state.

DataStore APIs persist between sessions; `UpdateAsync` callbacks cannot yield and may retry. The player-data guide describes session locking and active server-memory profiles. [Data stores](https://create.roblox.com/docs/cloud-services/data-stores), [Player-data implementation](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing).

Implement acquisition, readiness, lock refresh, token checks on saves, lock loss, ordered snapshots and final release as one lifecycle. Distinguish absent profiles from failed loads. A successful save is not a guarantee against crash loss since the last save. Use a separate test experience/store and bounded retries, observing budget/throttling limits. [DataStore errors and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits).

Typed modules clarify contracts, but runtime checks still guard remotes and stored profiles. Keep configuration, economy helpers and client presentation separate. [Luau types](https://luau.org/types/).

Rojo provides a CLI/server and Studio plugin, with Mac and Windows installation routes. Inspect existing setup and pin a shared version; do not assume an editor extension makes the CLI available. Use relative paths and an isolated local place on each computer. [Installation](https://rojo.space/docs/v7/getting-started/installation/), [New game workflow](https://rojo.space/docs/v7/getting-started/new-game/), [Project format](https://rojo.space/docs/v7/project-format/).

Decide which files Git/Rojo manages before syncing, and preserve manually authored owned assets. Some properties cannot live-sync like script source. [Recommended workflows](https://rojo.space/docs/v7/workflows/), [Sync details](https://rojo.space/docs/v7/sync-details/).

Verify solo client/server behaviour, a two-client server, layout/input through device simulation and real-device performance separately. A source build proves neither gameplay nor persistence. [Studio testing modes](https://create.roblox.com/docs/studio/testing-modes).

The original architecture's server authority, modular services and testable build order are useful. Remove its combat/speed services, global clocks, giant numeric economy, copied config, premium receipt system and mandatory image tooling. Strengthen the abbreviated session-lock sketch rather than copying it verbatim.
