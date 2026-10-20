"""Build seamless blue skybox textures in Blender; the meshes only import images."""
import bpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/map/reference_sky"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
zenith = (47 / 255, 171 / 255, 241 / 255)
horizon = (178 / 255, 222 / 255, 247 / 255)
for index, name in enumerate(("SkySide", "SkyTop", "SkyBottom")):
    image = bpy.data.images.new(name, width=512, height=512, alpha=True)
    pixels = []
    for y in range(512):
        # Horizon is the vertical center of each cubemap side.
        t = max(0, (y / 511 - .5) * 2)
        t = t * t * (3 - 2 * t)
        color = tuple(a + (b - a) * t for a, b in zip(horizon, zenith))
        if name == "SkyTop":
            color = zenith
        elif name == "SkyBottom":
            color = horizon
        pixels.extend((*color, 1) * 512)
    image.pixels = pixels
    image.filepath_raw = str(OUT / (name + ".png"))
    image.file_format = "PNG"
    image.save()
    image.pack()
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    node = material.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = image
    material.node_tree.links.new(node.outputs["Color"], material.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    bpy.ops.mesh.primitive_plane_add(size=2, location=(index * 3, 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.data.name = name
    obj.data.materials.append(material)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=str(OUT / "SkyImport.glb"), export_format="GLB", use_selection=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "ReferenceSky.blend"))
print("REFERENCE_SKY_READY")
