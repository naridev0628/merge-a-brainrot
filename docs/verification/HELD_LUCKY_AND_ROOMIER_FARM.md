# Held Lucky Blocks, roomier farm and pad colors — 2026-10-19

This pass supersedes the prior hold-to-repeat behavior. The latest user instruction requires an immediate action on pad entry, once per visit, without repeated spending while stationary.

## Changes

- Lucky Blocks enter a server-owned held state through proximity pickup. A welded, noncolliding block follows the avatar with raised arms. Its compact studded card leaves gameplay active; Unlock uses the authoritative cost and 75/20/5 reward table, Close drops it, and Discard removes it.
- Mini pickup uses the same fall, slide and arc positions as the conveyor animation. Players can catch drops beside producers. Future drops and remote landing points remain invalid collection targets.
- Plot depth increases to 87.1 world studs, with a 72.8-stud rear width. Purchase, conveyor and producer rows move together, retaining connected bridges and clear paths. Decor placements remain deterministic across six plots.
- Producer platforms are thicker; the farmer is 5.5 world studs tall. Mini signage, deposit glow, board supports and logs, and rounded outlined labels are larger. The hub mascot clears the nearby tree; the multiplier sits higher.
- Home uses a cyan studded panel. The 2x Cash offer has an animated rainbow glow and displays a real configured price when available. No incremental cash offers were added. Lucky rewards show the character and name without the redundant received sentence.
- Pad colors previously remained at their creation defaults. Buy 1/5/10/100 and Upgrade now update the slab, studs and edge trim from current cost, wallet, unlock and capacity. Insufficient-funds notices are suppressed.

## Executed verification

- All 19 non-Studio Luau test files pass, including held Lucky state/ownership/replay, airborne pickup, one-second production and immediate entry-only pads. All 42 source files compile.
- Studio environment checks pass across all six plots: pad and decor clearance, connected expanded floor/chute, farmer height, thicker stands, label styling, consistent decorations and walkable island/lily geometry.
- The new Studio pad regression tests balances one unit below, equal to, and above every Buy 1/5/10/100 price, followed by spending back to zero. It verifies both directions for surfaces, studs and trim, plus Buy 100 unlock and processor upgrade/max states. Removing the color-refresh calls makes the regression fail with stale Buy1 affordability; restoring them passes.
- Real client entry bought one starter and then five while holding a Lucky Block with its panel open. Remaining stationary left the producer count unchanged at six. Nearby collection continued with the card open; the overlay was transparent and inactive.
- Clicking Unlock consumed the held block, charged its cost and added one producer. The refined textured block rendered visibly in the avatar's hands and in its card preview. The farmer/sign/glowing deposit and expanded farm were visually inspected.
- Real client Close and Discard actions both succeeded. Close removed the held mesh and returned the block; Discard consumed the held block. The Rojo build and whitespace check pass.

QA cash and temporary scripts were confined to Play. Progress remains memory-only. Gamepass IDs and group reward configuration are still unset, so paid offers honestly show Coming soon. No live game publication or merge was performed. Existing installed-plugin syntax warnings are unrelated to project scripts. A raw ContentProvider preload probe reported an asset-type error; actual MeshPart rendering was subsequently confirmed visually in Play.
