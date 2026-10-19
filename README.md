# Merge a Brainrot

Six-player, memory-only Roblox Studio prototype with compact brick farms, six Brainrot tiers, stacking, timed mini sales, merging, Lucky Blocks and rebirth. Source files in Git are the source of truth. No live experience has been published.

Start with $5 and walk onto BUY 1 to get Tong Tong. Each producer makes a Mini every six seconds. Collect three $2 Minis from the conveyor tray, deposit them, then walk onto Collect Cash. Buy a second $5 Tong Tong and merge the pair. There is no welcome modal; the small tutorial guides the first loop. Hold Shift to sprint, or use the touch Sprint button.

Each plot has 100 producer slots across ten rows. Plots are 56 by 56 studs, half the earlier width and depth. Minis tumble into separate layered pile positions and producers hop when creating them. The HUD includes gradient cash, a collection index, merge-weighted Total Brainrots and an eligible-rebirth badge. Original Blender characters, brick scenery, nests and Lucky Blocks include editable sources.

Build with Rojo 7.7.1:

```sh
rojo build default.project.json -o build/MergeABrainrot-StackedFarm.rbxlx
```

Create `build/` first, open the generated place in Studio and press Play. The map generates at runtime. For live editing use `rojo serve default.project.json` and connect the Studio Rojo plugin. `setup.project.json` is the historical setup scaffold.

Run all non-Studio `tests/*.luau` scripts with Luau 0.743. Run `tests/studio-layout.client.luau` in the Studio Client command bar during Play. `tools/simulate_progression.luau` exercises the real economy with a timed active-player benchmark.

Stopping Play resets progress. Persistence, live release, friend boosts and configured monetization remain pending. Gamepass IDs are unset, so paid offers display Coming soon rather than invented Robux prices. First rebirth retains the specified $1 million plus Level 6 requirement; the [economy audit](docs/verification/ECONOMY_PACE.md) records its substantial manual progression burden.

See [build status](docs/BUILD_STATUS.md), [current verification](docs/verification/STACKED_FARM.md), [asset sources and imports](assets/README.md), and [setup instructions](docs/SETUP.md). The original handoff remains unchanged in `Merge_a_Brainrot_Pack/`; subsequent explicit user requests govern the current prototype.
