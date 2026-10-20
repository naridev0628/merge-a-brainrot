# Seamless farm refinement verification — 2026-10-19

Scope: refinement of the stacked farm branch, extending draft PR #2. Roblox Studio on Windows, Rojo 7.7.1 and Luau 0.743. This remains a Studio-only memory prototype.

## Automated evidence

All 13 non-Studio test scripts pass: conveyor, event-production, lucky, mini-event, onboarding, progression, queue-batches, review-regressions, run (13 core cases), sales, seamless, stacked and tier-values. All 35 source files compile. Strict analysis passes for FarmCore, Economy, Tutorial and MiniEvent. The Rojo place build succeeds.

The new cases cover rising quotes independent of merges, compact million-item bag/processor payouts, FIFO preservation across redeposits, matured sales during an upgrade between ticks, atomic merge-all, aura readiness/distance/capacity/replay, immediate Buy5/10 and same-pad Buy100 tier progression, fractional multiplier production and exhaustive random-walk bounds. See ECONOMY_PACE.md for the fresh deterministic benchmark.

## Studio evidence

- A fresh client loads BrainrotHUD. Startup replication races in Main and PurchaseEffects were corrected with dependency waits.
- Walking onto BUY 1 charged $5 and spawned TungTung; remaining on the pad did not buy repeatedly. Aura pickup collected multiple nearby ready Minis in a single result. Walk-on deposit and cash claim completed, and a walk-on processor upgrade charged $10. A later walk onto MERGE combined two TungTungs into one tier_02 producer. Holding the purchase pad with enough money for more did not repeat the purchase.
- Six bridge floors and their barriers span radial 94–131. A real Humanoid walk crossed from the bridge entrance toward the farmer, past the previous obstruction, reaching X=13.05.
- Three board models use Fredoka One. Live Net Worth showed the real player avatar, username, wallet value and rank footer. Gold/silver/bronze row colors were asserted. Temporarily removing the local row identity verified the exact unranked text and green `[$5]` value, then restored the real identity.
- Visual checks covered the octagonal hub, six radial bridges, T-shaped plots, mixed trees, side processor, stall crates and upgrade label. Upgrade text has a white outlined rate increase and a larger green price.
- The isolated Studio client layout regression passes at 640×280 and 390×844. It verifies million-Mini count sizing, hidden bag cash value, non-clickable walk-on controls, unlocked Buy5, locked Buy100 and no merge chooser. It asserts eight non-colliding ground cash bundles and confirms their removal after two seconds.
- QA found that setting TextWrapped=false disables Roblox TextScaled; the conflicting assignment was removed. Temporary UI fixtures are destroyed after testing.

An independent review rechecked queue arithmetic/timing, aura, AutoMerge, purchases, event production, startup and leaderboard integration. Its actionable findings were fixed; the final review found no further important issue in the upgrade labels, cash burst or bridge changes.

## Assets and limits

Eleven new main characters and eleven matching Minis are uploaded and saved as Roblox MeshPart templates in `ReplicatedStorage.ExpansionModels`. The combined import scene contains 22 named meshes and two embedded palette materials. The manifest records every mesh ID, texture ID and imported size. ContentProvider preload returned 44 successful mesh/texture references and zero failures in both Edit and Play. A Studio gallery visually confirmed the textured main/Mini pairs. A fresh Play session verified 36 anchored, non-colliding crate Minis covering all eleven variants. Wide silhouettes are uniformly reduced to fit individual crate slots and aligned with their heads above the rim. The updated modules compile and the Rojo place rebuilds with all 22 templates.

Original Blender source, individual GLBs, palettes, previews and geometry validation remain included. The new main characters are reusable assets, not newly assigned production tiers; the existing six-tier economy remains unchanged. Three Blender-authored stall props are represented by generated native parts. New trees/lighthouse are native original geometry.

Current-server rankings are not persistent global leaderboards. Saving, group reward fulfillment, friend boost, configured paid products, water texture replacement and live publishing remain pending. Real six-client load and physical phone/Mac testing are not claimed. The new layout test uses UI dimensions, not a physical touch device.

Studio continues to emit unrelated installed Superpower plugin syntax errors, FoundationProvider warnings and a pre-existing asset-type warning. No unrelated plugin was modified. Build artifacts are local and excluded from Git.
