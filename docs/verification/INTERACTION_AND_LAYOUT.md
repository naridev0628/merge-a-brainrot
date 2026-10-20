# Interaction and layout verification — 2026-10-19

This pass supersedes earlier six-second production, seven-stud pickup, and entry-only Buy/Upgrade behavior.

## Changes

- Rectangular cream/gold studded brick platforms replace nests under every producer. Stacked rows retain their spacing and unlock logic.
- Buy and Upgrade trigger on entry, wait two seconds, then repeat at 0.1-second intervals. Leaving, death, modal interactions and rejection reset or stop the hold. Client requests stay serialized; server rate limits allow the intended cadence.
- Shared rectangular pad geometry includes the visible base and border. Cash collection no longer depends on distance to its label or pad center.
- Ground Minis are 2.4 times their previous size, with their resting height adjusted. Pickup uses the same three-dimensional 12-world-stud sphere on client and server, including readiness and capacity checks.
- Every producer has a one-second base cycle; species value and the shared Mini Multiplier still apply. Lucky chance is 1% per produced Mini, including production while the ordinary ground tray is full; one active Lucky Block remains the limit.
- Processor upgrades show a short chip burst and rising text, with cleanup after 1.5 seconds.
- Six plots use identical local decoration positions, with clear paths around pads, display bays and conveyor. Three tree silhouettes remain in use. Ownership badges sit higher and rise with additional producer rows.
- Larger crates contain varied imported Minis. The farmer has a raised Mini-and-arrow sign; the deposit pad has stronger glow, trim and studs. Fixed hub shrubs and denser grass/plaza studs add detail.
- Lily pads and rock islands have collision and query enabled.

## Executed checks

- All 17 pure Luau test files pass, including new aura, full-footprint, pad-hold and production-pace regressions.
- Source compilation and the Rojo build pass.
- Studio environment regression passes: all six plot decorations match in local coordinates, pad/conveyor/display clearances hold, ownership anchors are elevated, and all 30 lily pads plus three rock islands are collidable.
- Actual client walk-on collection succeeded at all four cash-pad corners, each 0.1 world studs beyond the colored slab but inside its visible base. The first seeded 400-unit claim emptied pending cash and increased coins by 400.
- Actual upgrade-pad hold completed all five upgrades and stopped at MaxProcessor. The effect module created its burst and cleaned it up. Buy hold also purchased repeatedly without stepping off during the earlier play check.
- Standing ten world studs to the side of the tray collected seven ready Minis through the automatic aura without walking onto them.
- The player physically landed and rested on a lily pad and a rock island; vertical velocity settled near zero instead of falling through.
- Visual inspection covered the larger crates, deposit pad, fixed plot scenery and producer display. QA currency and temporary scripts were confined to Play and cleared by restarting it.

The official Roblox Classic Obby tutorial was located as a reference: https://create.roblox.com/docs/tutorials/curriculums/building. No external obby kit was imported. Global rankings, persistence and production purchases remain outside this presentation pass; no live experience was published.
