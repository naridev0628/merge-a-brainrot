# Blender HUD sculptures

Original models authored by `tools/build_hud_icons.py`, generated with Blender 5.2.
The red/gold book, pink/cyan rebirth arrows, blue gear and three-to-one merge
sculpture have `.blend`, GLB and transparent preview exports in `blender/`.

The matching `roblox/*.model.json` files contain the exact authored boxes and
triangular prisms as bounded native Roblox models. Preview/GLB exports add small
bevels; native parts preserve the sculpture, color, pose and volume without uploads.
Rojo maps them to `ReplicatedStorage.UIModels`. `Icon3D` clones them into isolated
fixed-camera ViewportFrames; unknown/missing models use the existing BrickArt
fallback. No render-step callbacks or external image IDs are used.

Regenerate:
`blender --background --threads 4 --python tools/build_hud_icons.py`
