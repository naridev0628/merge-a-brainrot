# First playable implementation plan

Goal: a fresh Studio player completes produce → collect → sell → buy → merge on one original plot with three tiers.

Spec: `Merge_a_Brainrot_Pack/MERGE_A_BRAINROT_ONE_SHOT_PROMPT.md`, Checkpoint 1. The existing written specification and user's instruction to proceed define this implementation; no redesign is needed.

Architecture: a pure Luau transaction core owns integer economy, token ledger and producer records. A Studio-only runtime supplies validated character positions, one scheduler, ownership, throttling and snapshots. Original primitive models and a responsive client present confirmed state.

Constraints: 6-second production, 20-Coin Tier 1 purchases, two distinct identical inputs, 12 slots, 8 tokens per producer, 96 ground/bag limits, 2-cycle catchup cap. No persistence, publishing, six-player claim or rebirth in this checkpoint. Memory mode must refuse live servers.

## Task 1: Transaction core
- [x] Write and run failing tests for a complete first merge, replayed requests, forged IDs, distance, full bag/plot, overflow and capped/stalled production.
- [x] Implement Config, CreatureCatalog, MapSpec and FarmCore with nonyielding candidate validation and commit.
- [x] Run the standalone Luau suite; expect all tests to pass.

## Task 2: Studio integration
- [x] Add server startup, original ModelFactory/WorldBuilder, remote router and one production loop.
- [x] Validate payload shape before expensive work, rate-limit all inputs, preserve economy on respawn, clean up on departure.
- [x] Build using Rojo and run a fresh Studio session; observe production and verify remote rejection behavior. Exact six-second timing is covered by the domain test; Studio first-token latency was not timed.

## Task 3: Basic playable UI
- [x] Implement the supplied draft's core-loop subset: navy/cream HUD, Coin/bag/objective text, contextual blue Buy and amber Sell, violet Merge, two selections and exact preview, Home and memory-mode notice.
- [x] Keep 48px targets and native movement/jump areas clear; use scrolling for short viewports. Later collection/rebirth/settings surfaces remain deferred.
- [x] Exercise the full loop through the real client, inspect desktop and phone layout, record unrun checks honestly.

## Task 4: Review and handoff
- [x] Run full suite, Rojo build, source compilation and independent code review; fix material findings.
- [x] Document actual test evidence, limitations and one learner action. Commit and push feature branch for review.

Review focus: replay ID reused across different actions; dead/nonfinite character positions; retired producer tokens; stalled production without backlog; stale merge selections and pending commands. Tests and runtime checks must cover these boundaries.
