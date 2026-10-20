# Merge a Brainrot

Six-player, memory-only Roblox Studio prototype with six Brainrot tiers, stacked farms, timed Mini processing, automatic merging, Lucky Blocks and rebirth. Source files in Git are the source of truth. No live experience has been published.

Start with $5 and walk onto Buy 1 to get Tung Tung. Every producer has a one-second base Mini cycle, adjusted by the shared 0.50–1.50x Mini Multiplier; higher tiers retain their larger Mini values. Minis within a 12-stud sphere around your character enter your bag automatically, including while falling and sliding. Walk onto the farmer's deposit pad, collect processed cash anywhere on the green pad, buy another Tung Tung, and step onto Merge to combine all available pairs. Pads act immediately, then repeat every half-second after a two-second hold. Buy and Upgrade surfaces, studs and trim turn green when available and affordable, red otherwise. Buy 5 and Buy 10 need no rebirth. Buy 50 unlocks at rebirth 1 and advances one species tier per rebirth on the same pad.

Each plot is capped at 50 Brainrots in five rows and 50 ordinary conveyor Minis total, including airborne drops. Buy50 fills only the available spaces. Farmer/barn and utility boards are mirrored left/right; the larger stall and continuous front fences leave the connected bridge as the plot entrance. The conveyor center is fully red and producer animation keeps feet grounded.

Walk near a Lucky Block to hold it. Its compact side card shows actual rewards, odds and cost without dimming the screen or stopping movement, Mini pickup or pad actions. Unlock consumes the held block; closing the card drops it back, and Discard removes it. Larger plots leave an open forecourt and spaced purchase pads. Raised brick stands, an avatar-size farmer, an enlarged Mini sign, glowing deposit border, outlined rounded lettering and a studded Home button complete the presentation pass.

Purchases gradually cost more, even after merging. The first processor upgrade costs $10. First rebirth requires $25,000 and an owned Level 6 Brainrot. Shift and touch Sprint are supported. There is no welcome modal or interaction-key requirement for farm pads.

Six T-shaped plots connect by bridges to an octagonal hub with a circular center. Three wood leaderboards show current-server Net Worth, Time Played and Total Brainrots, including avatars, medal colors and personal bracketed values. Three gradient tree shapes, a corner lighthouse, mixed Mini crates and cash props decorate the map. Producer rows are spaced farther apart. Cash claims scatter eight small cash bundles and sparks for two seconds.

Build with Rojo 7.7.1:

```sh
rojo build default.project.json -o build/MergeABrainrot-StackedFarm.rbxlx
```

Create `build/` first, open the generated place in Studio and press Play. The map generates at runtime. For editing use `rojo serve default.project.json` and connect the Studio Rojo plugin. Run non-Studio `tests/*.luau` with Luau 0.743, and `tests/studio-layout.client.luau` in Studio Client during Play.

Progress resets on Stop. Persistence, global leaderboards, group rewards, friend boosts and configured monetization remain pending. Paid offers show Coming soon. Eleven additional original Blender characters and eleven matching Minis are imported with textures in `ReplicatedStorage.ExpansionModels`; their saved templates ship in every Rojo build. All eleven Mini variants decorate the farmer crates. These assets are available for future progression; the existing six gameplay tiers remain unchanged.

See [current verification](docs/verification/FIFTY_CAP_AND_CONNECTED_PLOTS.md), [economy benchmark](docs/verification/ECONOMY_PACE.md), [asset sources](assets/README.md), and [setup](docs/SETUP.md). The original handoff remains unchanged in `Merge_a_Brainrot_Pack/`; subsequent explicit user requests govern this prototype.
