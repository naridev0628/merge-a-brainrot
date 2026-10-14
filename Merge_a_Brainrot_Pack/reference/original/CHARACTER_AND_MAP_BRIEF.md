# Original character and map brief

Status: proposed design only. No model, icon, animation, audio asset or map has been built by this package. All character names are working names without trademark/rights clearance. `../../MERGE_A_BRAINROT_ONE_SHOT_PROMPT.md` is canonical for gameplay, geometry and implementation; this brief explains the intended original visuals.

## Character family

Make absurd, readable combinations of ordinary objects and plant/space shapes. Use Studio primitives for the first playable build; no external mesh, texture, voice clip or asset ID is required. Keep stable species IDs independent of display names. The six concepts in `../../assets/ORIGINAL_CHARACTER_ROSTER.csv` replace the legacy competitor roster.

| ID | Working name | Primitive silhouette | Mini direction |
|---|---|---|---|
| `tier_01` | Spoon Sprout | Round planter body, bent spoon-shaped stem and two leaf hands | Small glowing seed-shaped token |
| `tier_02` | Wobble Waffle | Square waffle body with a shallow geometric grid and mismatched roller feet | Amber cube token |
| `tier_03` | Bubble Boots | Three differently sized spheres wearing oversized rectangular rain boots | Blue bead token |
| `tier_04` | Disco Turnip | Turnip-shaped bulb, orbit-like ring and simple prism shoes | Pink star-like token |
| `tier_05` | Noodle Comet | A segmented curved noodle silhouette orbiting a tiny original moon face | Mint spiral-like token |
| `tier_06` | Toaster Monarch | Box toaster body, toast-shaped crown and simple segmented spring arms | Gold hexagonal token |

These descriptions are new concept proposals, not claims that the names are cleared or that the assets exist. Do not reproduce Tong Tong/cappuccino, recognizable competitor characters, specific meme recordings or another game's promotional artwork. An acquired replacement needs its own permission/provenance review even if its name is familiar.

Production requirements from the prompt: at most 24 primitive parts per producer; at most three per Mini; anchored/non-colliding token proxies; no embedded scripts in art models. Give producers a stable pivot and keep shape/size bounded so twelve slots remain readable. A suggested common envelope is about 6 × 8 × 6 studs; adjust after actual clearance and camera tests without changing plot geometry or gameplay. Model construction may live in the project's own `ModelFactory`; these descriptions are not a completed implementation.

Use silhouette plus label to distinguish tiers. Small original eyes/simple faces are optional. Optional idle motion should be subtle, client-side and compatible with reduced motion. A merge effect follows the server commit; it never grants rewards. A Mini is a sale token, not a hatchable item or new producer. Do not imply free producer growth through baby-token art.

## Mini Meadow world

Build one original open plaza with six independent square plots. The exact master-prompt geometry is:

- Ground center `(0,-0.5,0)`, size `(240,1,200)`; walk surface Y=0.
- Plot size 52 × 52 studs; centers at X=`-72,0,72` and Z=`-52,52`.
- Northern row rotates 180° around Y; southern row uses 0°. Local negative Z is the front, so both rows face the central plaza.
- Front opening at least 12 studs wide; clear central walkway and simple non-colliding decorative planters.
- Local spawn `(0,3,-16)`; Sell Minis pad `(-18,0.15,-18)` and Buy Tier 1 pad `(18,0.15,-18)`, each `(10,0.3,10)`.
- Twelve producer slots: X=`-14,0,14`; Z=`-4,4,12,20`. Place owner signage outside the walkway. Merge/Rebirth use HUD panels rather than a required machine.

Use warm mint/cream scenery, navy text surfaces, amber Sell, blue Buy and violet Merge. This palette is original direction, with final accessibility checked in the actual UI. Pair colors with words/icons; never rely on color alone. Do not reuse the supplied striped headers, shop cards, map corridors, icons, badges or promotional art.

Before calling the map complete, verify plot separation, spawn clearance, pad bounds, front openings, token containment and unobstructed pad approaches. The world generator rebuilds only its own container; unrelated user geometry is preserved. Model scale and feedback must remain usable with six full farms and up to 96 ground Minis per plot. Record the measured generated part count; fewer than 6,000 is a target, not a measured result here.

## Art handoff and evidence

Build the playable loop first. Later original concept art can use these descriptions without borrowed image pixels; keep the prompt, maker and output provenance. Do not require art generation for progression. Write approved asset IDs/dependencies to `../../assets/ASSET_MANIFEST.csv` only after evidence and experience access checks exist. Capture the actual prototype under `../own_playtests/` rather than producing mock screenshots labelled as gameplay.
