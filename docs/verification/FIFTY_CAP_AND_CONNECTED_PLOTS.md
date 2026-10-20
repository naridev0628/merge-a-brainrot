# 50-item caps and connected plots — 2026-10-19

The latest user request restores holding: pads act immediately, wait two seconds, then repeat every half-second. This supersedes the previous entry-only setting.

## Implementation

- Each plot has at most 50 producers (five rows) and 50 ordinary Mini tokens total, counting both in-flight and landed tokens. Full plots reject purchases/Lucky rewards without charging; merging frees space. Skipped drops do not accumulate into a later burst.
- Buy50 replaces Buy100 and fills only the remaining slots. `Economy.purchaseQuote` centralizes amount, tier, cost and eligibility for server purchases, HUD and pad colors. Monetary values and rebirth-tier behavior are retained.
- Visible bridge landings overlap the deck and plot instead of meeting at the inset mesh edge. Front fence spans close the side gaps around the bridge; the mirrored farmer alcove is enclosed. Access to the water features remains through the central hub.
- Farmer/barn and cash-processing/group-reward boards are mirrored left/right, as confirmed by the user. Interactive positions derive from Config through MapSpec. The farmer stall is 25% wider and deeper, with a larger alcove; the NPC retains its 5.5-stud height.
- The red conveyor center spans the full belt depth, filling the gap between the two slopes. Producer animation now turns around world Y without moving feet off the stand, including procedural fallback models with sideways pivots.

## Verification

- New cap and shared-purchase tests cover fixed/partial batches, full-cap Lucky rejection, merging to free a slot, the combined flight/ground cap and absence of drop backlog. All 21 pure test files pass.
- Studio checks pass for all six mirrored layouts, pad/decoration clearance, larger booth/NPC scale, complete red center coverage and front/alcove fence coverage. Bridge raycasts cover the visible seam at three lateral positions. The avatar physically walked from the bridge onto the plot without falling.
- Live Buy1 hold timing: first repeat at about 2.05 seconds, subsequent purchases about 0.52–0.57 seconds apart. Initial entry remains immediate; leaving and reentering resets the delay. Insufficient funds/cap errors stop repeated requests until reentry.
- The bridge and producer-grounding regressions failed against the prior implementation and passed after their fixes. The sideways-pivot fixture also caught the local-axis animation issue identified in independent review.
- Studio affordability and compact/portrait UI tests pass with Buy50 and shared partial-batch pricing. Pure suites, source compilation, build and whitespace validation are rerun before delivery.

Temporary QA currency and instrumentation exist only in Play and are cleared afterward. This remains a memory-only Studio preview, with configured monetization and live publication still pending.
