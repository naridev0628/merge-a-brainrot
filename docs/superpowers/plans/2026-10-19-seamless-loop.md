# Seamless farm loop implementation plan

> Execute inline using executing-plans; validate transactions with test-driven-development and obtain one final independent review.

Goal: quick early progress and mobile-friendly walk-on interactions, with rising purchase costs and clearer plot/lobby layout.

Design: retain six-second production and $5 first two purchases. Each subsequent purchase adds $1 to the next price, based on purchases since rebirth, never current producer count. Bulk prices sum that same sequence. Processor upgrades cost $10/$30/$90/$250/$750. A seven-stud pickup aura collects all eligible nearby Minis in one server transaction. Merge pad combines every available matching pair atomically, with distance/replay protection. Deposit and cash pads repeat only when goods/payouts exist; buy/upgrade trigger once per entry.

The user explicitly authorized these refinements and autonomous balancing; implementation proceeds without another approval gate. Existing worktree and draft PR are reused. Water texture is deferred until the user supplies one.

- [x] Core and shared quotes: purchase counter, bulk price sum, rebirth reset; aura collection and merge-all commands. Tests cover replay, distance, capacity, in-transit exclusion, no-pair rejection, cap and merge-independent pricing.
- [x] Client: walk-on interactions, no merge chooser, no bag cash label, TungTung spelling, purchase celebration, brick pass cards with honest Coming soon prices.
- [x] World: side-facing processor clear of buy pads; deposit beside inward-facing barn to the right when approaching the bridge; wider fence opening; solid roots/trunk/branches and pass-through leaves; irregular tree placement; circular inward-facing leaderboards and landscaped lobby.
- [x] Verification: all regression suites, compile/build, updated economy simulation, Studio desktop/phone interaction and geometry checks, independent review; update draft PR.

Review focus: bulk quote vs actual charge; merging must not reduce prices; aura may not collect foreign/in-transit goods; standing on a purchase pad must not spend repeatedly; rotated plots must share matching logical positions.

## Additional approved refinements implemented

- Compact bag and processor batches hold millions without per-item allocation; queue timing/FIFO and upgrade retiming have regressions.
- Buy 5/10 require no rebirth. Buy 100 advances the species one tier per rebirth on the existing pad.
- Octagonal hub, circular center, six bridges, T-shaped plot, taller producer rows, three gradient tree shapes, corner lighthouse and Blender-derived stall detail.
- Server-owned 90-second 0.50–1.50x Mini event with 0.10–0.30 moves and fractional production carry.
- Three reference-styled wood leaderboards with avatars, rank medal colors, colored headings and personalized bracketed values.
- Eleven original Blender main/Mini pairs imported into Roblox with textures, saved as Rojo templates, and verified in Studio. All eleven Mini variants populate farmer crates. New gameplay-tier assignment remains separate follow-up work.
- White upgrade rate label, larger green price, and eight cash bundles with sparks that disappear in two seconds.

Verification evidence is tracked in `docs/verification/SEAMLESS_FARM.md`. Group reward is a labeled Coming soon board until a group/reward configuration exists. Current-server rankings do not claim persistent global data. No live publish.
