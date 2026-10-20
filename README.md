# Merge a Brainrot

Six-player, memory-only Roblox Studio prototype with six Brainrot tiers, stacked farms, timed Mini processing, automatic merging, Lucky Blocks and rebirth. Source files in Git are the source of truth. No live experience has been published.

Start with $5 and walk onto BUY 1 to get TungTung. Every producer has a one-second base Mini cycle, adjusted by the shared 0.50–1.50x Mini Multiplier; higher tiers retain their larger Mini values. Ready Minis within a 12-stud sphere around your character enter your bag automatically. Walk onto the farmer's deposit pad, collect processed cash anywhere on the green pad, buy another TungTung, and step onto MERGE to combine all available pairs. Buy and Upgrade act on entry; after standing for two seconds they repeat every 0.1 seconds until you leave or reach a limit. Buy 5 and Buy 10 need no rebirth. Buy 100 unlocks at rebirth 1 and advances one species tier per rebirth on the same pad.

Purchases gradually cost more, even after merging. The first processor upgrade costs $10. First rebirth requires $25,000 and an owned Level 6 Brainrot. Shift and touch Sprint are supported. There is no welcome modal or interaction-key requirement for farm pads.

Six T-shaped plots connect by bridges to an octagonal hub with a circular center. Three wood leaderboards show current-server Net Worth, Time Played and Total Brainrots, including avatars, medal colors and personal bracketed values. Three gradient tree shapes, a corner lighthouse, mixed Mini crates and cash props decorate the map. Producer rows are spaced farther apart. Cash claims scatter eight small cash bundles and sparks for two seconds.

Build with Rojo 7.7.1:

```sh
rojo build default.project.json -o build/MergeABrainrot-StackedFarm.rbxlx
```

Create `build/` first, open the generated place in Studio and press Play. The map generates at runtime. For editing use `rojo serve default.project.json` and connect the Studio Rojo plugin. Run non-Studio `tests/*.luau` with Luau 0.743, and `tests/studio-layout.client.luau` in Studio Client during Play.

Progress resets on Stop. Persistence, global leaderboards, group rewards, friend boosts and configured monetization remain pending. Paid offers show Coming soon. Eleven additional original Blender characters and eleven matching Minis are imported with textures in `ReplicatedStorage.ExpansionModels`; their saved templates ship in every Rojo build. All eleven Mini variants decorate the farmer crates. These assets are available for future progression; the existing six gameplay tiers remain unchanged.

See [current verification](docs/verification/SEAMLESS_FARM.md), [economy benchmark](docs/verification/ECONOMY_PACE.md), [asset sources](assets/README.md), and [setup](docs/SETUP.md). The original handoff remains unchanged in `Merge_a_Brainrot_Pack/`; subsequent explicit user requests govern this prototype.
