"""Original Blender-authored Brainrot market cast, GLBs and exact native geometry.
Run Blender --background --threads 4 --python tools/build_brainrot_market.py.
Native layout retains the authored solids; exported meshes add edge bevels.
"""
import bpy, json, math
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/map/brainrot_market"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
COLORS = {
    "wood": (.57,.25,.065), "grain": (.29,.105,.025),
    "cream": (.96,.86,.65), "white": (1,1,1),
    "ink": (.018,.014,.025), "coffee": (.17,.065,.025),
    "pink": (.82,.16,.29), "mint": (.13,.58,.42),
    "blue": (.055,.25,.65), "gold": (.96,.61,.055),
    "darkblue": (.035,.075,.19), "red": (.72,.055,.075),
}
mats = {}
for key, color in COLORS.items():
    mat = bpy.data.materials.new(key)
    mat.diffuse_color = (*color,1)
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*color,1)
    mats[key] = mat
parts, records = [], []

def cube(name, pos, size, color, rotation=(0,0,0), bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.rotation_euler = rotation
    obj.data.materials.append(mats[color])
    records.append((obj, size, color))
    if bevel:
        mod = obj.modifiers.new("Toy edge", "BEVEL")
        mod.width, mod.segments = min(bevel,min(size)*.2), 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    parts.append(obj)
    return obj

def face(z, y, spread, smile=True):
    for side in (-1,1):
        cube("Eye white", (side*spread,y,z), (.46,.09,.47), "white")
        cube("Pupil", (side*spread-.045,y-.065,z-.025), (.19,.055,.24), "ink", bevel=.005)
        cube("Eye glint", (side*spread-.09,y-.10,z+.035), (.055,.025,.07), "white", bevel=0)
        cube("Eyebrow", (side*spread,y,z+.35), (.48,.09,.09), "grain", (0,side*.12,0))
    cube("Grin", (0,y-.02,z-.61), (.70,.08,.13), "ink")
    if smile:
        cube("Buck tooth", (-.13,y-.08,z-.58), (.18,.05,.14), "white", bevel=.005)

def log_keeper():
    cube("Wooden log head and body", (0,0,3.35), (1.85,1.25,3.65), "wood", bevel=.065)
    for side in (-1,1):
        cube("Wooden leg", (side*.53,0,.72), (.40,.48,1.25), "wood")
        cube("Market boot", (side*.53,-.21,.19), (.71,1.05,.38), "darkblue")
        cube("Arm", (side*1.18,0,2.45), (.40,.45,1.65), "wood", (0,side*.13,0))
        cube("Hand", (side*1.29,-.12,1.65), (.46,.48,.48), "wood")
        cube("Apron strap", (side*.52,-.68,3.16), (.22,.10,1.20), "mint")
        for z in (3.7,4.05,4.8):
            cube("Wood grain", (side*.77,-.637,z), (.045,.025,.25), "grain", bevel=0)
    cube("Vendor apron", (0,-.70,2.26), (1.60,.15,1.43), "mint")
    cube("Apron pocket", (0,-.80,2.21), (.75,.09,.47), "cream")
    cube("Pocket mini face", (0,-.86,2.23), (.31,.03,.11), "wood", bevel=0)
    face(4.22,-.68,.43)
    cube("Log nose", (0,-.78,3.93), (.28,.24,.35), "wood")
    cube("Vendor visor", (0,-.20,5.22), (2.31,1.94,.22), "mint")
    cube("Vendor cap", (0,.08,5.49), (1.85,1.29,.40), "mint")
    cube("Cap badge", (0,-.60,5.47), (.42,.06,.26), "gold")
    cube("Coin tray", (1.42,-.48,1.63), (.95,.84,.13), "gold")
    for x in (1.15,1.57):
        cube("Coin stack", (x,-.48,1.81), (.27,.27,.23), "gold")

def coffee_keeper():
    for side in (-1,1):
        cube("Barista leg", (side*.45,0,.73), (.36,.43,1.17), "cream")
        cube("Barista shoe", (side*.45,-.21,.19), (.69,1.00,.37), "pink")
        cube("Sleeve", (side*1.02,0,2.52), (.47,.66,.92), "pink", (0,side*.17,0))
        cube("Hand", (side*1.14,-.12,1.94), (.41,.47,.43), "cream")
    cube("Barista body", (0,0,2.14), (1.48,.95,1.78), "pink")
    cube("Striped apron", (0,-.53,2.09), (1.24,.13,1.37), "cream")
    for x in (-.42,0,.42):
        cube("Apron stripe", (x,-.61,2.09), (.14,.035,1.31), "mint", bevel=0)
    cube("Coffee cup head", (0,0,3.95), (2.24,1.70,2.05), "cream", bevel=.09)
    cube("Cup rim", (0,0,5.03), (2.44,1.89,.22), "white")
    cube("Coffee surface", (0,0,5.17), (2.12,1.56,.065), "coffee", bevel=.045)
    for side in (-1,1):
        cube("Latte heart", (side*.19,-.02,5.23), (.48,.54,.08), "cream", (0,0,side*.38))
    for pos,size in [((1.46,0,4.63),(.65,.43,.28)),((1.76,0,4.13),(.27,.43,1.18)),((1.46,0,3.61),(.65,.43,.28))]:
        cube("Cup handle", pos, size, "cream")
    face(4.20,-.89,.49)
    cube("Bow center", (0,-.62,2.94), (.23,.18,.28), "mint")
    for side in (-1,1):
        cube("Bow", (side*.26,-.59,2.94), (.39,.17,.41), "mint", (0,side*.3,0))
    for i in range(3):
        cube("Steam curl", (-.5+i*.37,.35,5.48+i*.21), (.16,.18,.32), "white", (0,(-1)**i*.35,0))

def market_sign():
    for side in (-1,1):
        cube("Sign foot", (side*2.2,0,.15), (1.35,1.6,.30), "darkblue")
        cube("Sign post", (side*2.2,0,2.0), (.35,.45,3.8), "blue")
    cube("Market sign frame", (0,0,3.1), (5.3,.50,2.45), "darkblue")
    cube("Market sign face", (0,-.28,3.1), (4.95,.10,2.10), "mint")
    # A three-faced mini motif reads as a Brainrot market symbol without text.
    for x,color,height in [(-1.55,"wood",1.2),(0,"cream",1.0),(1.55,"blue",.9)]:
        cube("Mini icon", (x,-.40,3.0), (1.1,.20,height), color)
        for side in (-1,1):
            cube("Icon eye", (x+side*.22,-.53,3.18), (.18,.04,.20), "white", bevel=0)
            cube("Icon pupil", (x+side*.22,-.56,3.16), (.08,.03,.11), "ink", bevel=0)
    for x in (-1.7,-.85,0,.85,1.7):
        cube("Sign top stud", (x,0,4.42), (.35,.35,.17), "gold")

def srgb(c):
    return 12.92*c if c<=.0031308 else 1.055*c**(1/2.4)-.055

palette = bpy.data.images.new("BrainrotMarketPalette", width=64, height=64, alpha=True)
pixels=[]
colors=list(COLORS.values()) + [(1,1,1)]*4
for y in range(64):
    for x in range(64): pixels.extend((*colors[(y//16)*4+x//16],1))
palette.pixels=pixels
palette.filepath_raw=str(OUT/"BrainrotMarketPalette.png")
palette.file_format="PNG"
palette.save()
atlas=bpy.data.materials.new("BrainrotMarketAtlas")
atlas.use_nodes=True
tex=atlas.node_tree.nodes.new("ShaderNodeTexImage")
tex.image=palette
tex.interpolation="Closest"
atlas.node_tree.links.new(tex.outputs["Color"], atlas.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
stats, models, runtime, centers = {}, [], {}, {}
for name,builder in [("BrainrotLogKeeper",log_keeper),("BrainrotCoffeeKeeper",coffee_keeper),("BrainrotMarketSign",market_sign)]:
    parts.clear(); records.clear(); builder()
    manifest=[]
    swap=lambda v: Vector((v.x,v.z,v.y))
    for obj,size,color in records:
        r=obj.rotation_euler.to_matrix()
        rr=Matrix([swap(r@Vector(v)) for v in ((1,0,0),(0,0,1),(0,1,0))]).transposed()
        manifest.append({"name":obj.name,"size":[size[0],size[2],size[1]],"cf":list(swap(obj.location))+[rr[i][j] for i in range(3) for j in range(3)],"color":[srgb(c) for c in COLORS[color]]})
    runtime[name]=manifest
    (OUT/(name+"-layout.json")).write_text(json.dumps(manifest,indent=2))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts: obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    obj=bpy.context.object;obj.name=name
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    for layer in list(obj.data.uv_layers): obj.data.uv_layers.remove(layer)
    uv=obj.data.uv_layers.new(name="UVMap");uv.active_render=True
    keys=list(COLORS)
    for poly in obj.data.polygons:
        index=keys.index(obj.data.materials[poly.material_index].name)
        for li in poly.loop_indices: uv.data[li].uv=((index%4+.5)/4,(index//4+.5)/4)
        poly.material_index=0
    obj.data.materials.clear();obj.data.materials.append(atlas)
    obj.data.calc_loop_triangles()
    mesh_data={
        "vertices":[[v.co.x,v.co.z,v.co.y] for v in obj.data.vertices],
        "faces":[],
        "size":[obj.dimensions.x,obj.dimensions.z,obj.dimensions.y],
    }
    center=sum((Vector(corner) for corner in obj.bound_box),Vector())/8
    mesh_data["center"]=[center.x,center.z,center.y]
    centers[name]=mesh_data["center"]
    for triangle in obj.data.loop_triangles:
        order=(0,2,1)
        mesh_data["faces"].append({
            "vertices":[triangle.vertices[i] for i in order],
            "uv3":[list(uv.data[triangle.loops[i]].uv) for i in order],
            "normal":[triangle.normal.x,triangle.normal.z,triangle.normal.y],
        })
    (OUT/(name+"-mesh.json")).write_text(json.dumps(mesh_data,separators=(",",":")))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+".glb")),export_format="GLB",use_selection=True,export_apply=True)
    stats[name]={"triangles":len(obj.data.loop_triangles),"native_parts":len(manifest),"dimensions_blender":list(obj.dimensions),"uv_layers":1,"materials":1}
    models.append(obj)
for i,obj in enumerate(models): obj.location.x=(i-1)*6
bpy.ops.object.camera_add(location=(10,-24,14))
camera=bpy.context.object
camera.rotation_euler=(Vector((0,0,2.8))-camera.location).to_track_quat("-Z","Y").to_euler()
camera.data.type="ORTHO";camera.data.ortho_scale=21
scene=bpy.context.scene;scene.camera=camera
for pos,power in [((-8,-8,12),1700),((8,-4,10),1300),((0,6,12),1800)]:
    bpy.ops.object.light_add(type="AREA",location=pos)
    lamp=bpy.context.object;lamp.data.energy=power;lamp.data.size=7
    lamp.rotation_euler=(Vector((0,0,3))-lamp.location).to_track_quat("-Z","Y").to_euler()
scene.render.engine="CYCLES";scene.cycles.samples=24
scene.world.color=(.20,.22,.27)
scene.render.resolution_x=1500;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.render.filepath=str(OUT/"BrainrotMarketPreview.png")
scene.view_settings.view_transform="AgX"
palette.pack();bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"BrainrotMarket.blend"))
bpy.ops.render.render(write_still=True)
(OUT/"mesh-stats.json").write_text(json.dumps(stats,indent=2))
lines=["--!strict","-- Generated from original Blender solid layouts; rebuild tools/build_brainrot_market.py.","local Factory=require(script.Parent.ModelFactory)","local data={"]
numbers=lambda values: ",".join(f"{v:.7g}" for v in values)
for key,manifest in runtime.items():
    lines.append(key+"={")
    for p in manifest:
        lines.append("{Vector3.new("+numbers(p["size"])+"),CFrame.new("+numbers(p["cf"])+"),Color3.new("+numbers(p["color"])+")},")
    lines.append("},")
lines+=["}","local centers={"]
for key,center in centers.items(): lines.append(key+"=Vector3.new("+numbers(center)+"),")
lines+=["}","local Market={}","function Market.place(parent: Instance,key: string,cf: CFrame,scale: number?): Model",
    "local model=Instance.new('Model');model.Name=key;model.WorldPivot=CFrame.identity",
    "model:SetAttribute('BlenderAuthored',true)",
    "local templates=game:GetService('ReplicatedStorage'):FindFirstChild('MapModels')",
    "local template=templates and templates:FindFirstChild(key)",
    "if template and template:IsA('MeshPart') then",
    "local mesh=template:Clone();mesh.Name='AuthoredMesh';mesh.CFrame=CFrame.new((centers :: any)[key])",
    "mesh.Anchored=true;mesh.CanCollide=false;mesh.CanQuery=false;mesh.CanTouch=false;mesh.Parent=model",
    "else",
    "for _,p in (data :: any)[key] do",
    "local part=Factory.part(model,'AuthoredDetail',p[1],p[2],p[3]);part.CanQuery=false",
    "end","end","model:ScaleTo(scale or 1);model:PivotTo(cf);model.Parent=parent;return model","end","return table.freeze(Market)"]
(ROOT/"src/shared/BrainrotMarket.luau").write_text("\n".join(lines)+"\n")
print("MARKET_STATS",json.dumps(stats),flush=True)
