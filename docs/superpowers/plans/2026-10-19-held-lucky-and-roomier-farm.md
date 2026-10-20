# Held Lucky Blocks and roomier farm implementation plan

**Goal:** Walk up to a Lucky Block, carry it with a compact nonblocking reward card, and keep collecting Minis while moving. Improve plot spacing, rounded outlined lettering, brick stands, farmer scale and deposit glow using the supplied references.

**Architecture:** The server owns each block's ground/held state, pickup distance, unlock cost, discard and reward. A replicated noncolliding held mesh follows the avatar; the client poses arms and opens a nonmodal side card on pickup. Shared Mini trajectory coordinates make falling Minis collectible at their visible positions. Existing six-tier economy and 75/20/5 odds stay intact.

**Tech stack:** Luau, Roblox Studio, Rojo, Blender Python.

- [x] Add regressions for Lucky pickup/hold/unlock/drop/discard, ownership and replay, then implement the server state flow and client automatic pickup.
- [x] Replace modal Lucky behavior with the reference side card; movement, pad actions and Mini pickup continue. Show actual odds and cost, with Unlock and Discard.
- [x] Share airborne Mini positions between rendering and pickup; test collecting beside the producer and rejecting distant/future tokens.
- [x] Expand rear footprint and move conveyor/display/buy rows together. Add thick stands, full-size farmer, larger sign, brighter glow, board logs and stronger rounded type; correct Tung Tung naming and raise the multiplier.
- [x] Refine Lucky Block in Blender, export and import the textured mesh, then verify its presentation in Studio.
- [x] Run pure tests, compile, build and Studio gameplay/visual checks; record evidence for the existing draft PR.

Latest steering incorporated: pads act immediately once per entry, without hold-to-repeat. Purchase and upgrade pads change slab, studs and trim green/red with current affordability and eligibility. Home is a cyan studded panel; the permanent 2x Cash promo has rainbow glow and uses the configured Robux price. No incremental cash offers or redundant Lucky received sentence.

The user's supplied behavior and image references are the design brief. The paid-luck button in the reference is not added as a nonfunctional purchase. Closing the card puts the block back; Discard removes it. Cosmetic layout and model work run independently while the state flow is implemented.
