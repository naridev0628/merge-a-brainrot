# Stacked farm implementation plan

Goal: implement the user's 2026-10-19 farm, UI, character and animation references on `codex/stacked-brainrot-farm`, based on `codex/first-playable`.

The final user requests supersede the initial one-plot plan: six plots; 100 slots; $5 starter and purchase price; six tiers valued $2/$5/$12/$29/$70/$170; six-second production; first rebirth $1 million plus owned Level 6, then $500k more per rebirth. Buy quantities 1/5/10/100 unlock at rebirth 0/1/2/3. Buy 100 fills remaining capacity and charges only that amount. Plot width/depth are halved to 56 studs. No live publication.

Architecture: preserve server-owned transactions, replay protection, integer quarter-dollar units and shared layout coordinates. Render anchored rows and individually tracked Minis; client animation follows server-authoritative centers. Rebirth resets the active economy while retaining discoveries/permanent pass ownership. The prototype remains Studio-only and memory-only.

Implementation checklist:

- [x] Core: atomic purchases/merges/rebirth, six independent plots, processing queues/upgrades, Lucky odds, capacity/replay/ownership validation.
- [x] Map: compact pads, brick fences/dividers, original Blender characters/nests/scenery, inclined studded conveyor, noncolliding tree meshes.
- [x] UI: no welcome modal; tutorial text/path, gradient cash/rebirth, weighted count, Index/rebirth icons, Lucky odds card, transparent cash feedback, phone layouts.
- [x] Animation: staggered random deposit rain, producer hops, falling/tumbling Minis and layered pile settling; Shift/touch sprint.
- [x] Verification: pure regression suites, source compilation, Studio interaction and desktop/phone visual checks, independent code review, economy simulations.
- [x] Final build and regression checks; preserve the worktree and fresh Studio preview. Delivery uses a draft PR against first-playable.

Remaining release scope is documented in BUILD_STATUS: saving, live monetization IDs, friend boost, real device/multiplayer load testing and later economy tuning. Simulation does not substitute for a human retention test.
