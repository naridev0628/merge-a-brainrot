# Merge a Brainrot

BUILD_MODE: INCREMENTAL. Current scope: Checkpoint 1 (first playable).

Shared repository: [naridev0628/merge-a-brainrot](https://github.com/naridev0628/merge-a-brainrot) (private).

The original handoff is preserved in `Merge_a_Brainrot_Pack/`. Its canonical specification is `Merge_a_Brainrot_Pack/MERGE_A_BRAINROT_ONE_SHOT_PROMPT.md`.

The first playable has one plot, three original producer species, automatic Mini collection, an amber Sell pad, a blue Buy pad, and two-input merging. Start with one Spoon Sprout and zero Coins. Collect ten Minis, sell them for 20 Coins, buy another Sprout, then select both in Merge. Two Wobble Waffles merge into Bubble Boots.

This is a Studio-only memory prototype. Stopping Play resets progress. Persistence, six plots, rebirth, later tiers and release polish belong to later checkpoints.

Build with Rojo 7.7.1: `rojo build default.project.json -o build/MergeABrainrot-FirstPlayable.rbxlx` (create `build/` first). Open that file in Studio and press Play. The world is generated when Play starts. `setup.project.json` is the historical setup scaffold.

Run the 13 domain tests with Luau 0.743: `luau tests/run.luau`. See [first-playable verification](verification/FIRST_PLAYABLE.md) for Studio checks and limitations.

See [setup instructions](docs/SETUP.md), [build status](docs/BUILD_STATUS.md), and [verification](verification/TEST_REPORT.md).

Source files in Git are the source of truth. Change scripts here and rebuild, or run `rojo serve default.project.json` and connect the Studio Rojo plugin. Avoid separate edited copies in Studio.
