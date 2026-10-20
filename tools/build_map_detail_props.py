"""Drop-in toy-brick scenery with unchanged native template envelopes.

Blender --background --threads 4 --python tools/build_map_detail_props.py
Only writes assets/map/detail_props. Ground and Roblox asset IDs are untouched.
"""
import bpy, math, json, struct, zlib, hashlib
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets/map/detail_props"
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
PALETTES={
 "Wood":((65,38,24),(165,105,54),(224,166,92)),
 "Rail":((71,42,25),(179,116,60),(237,183,111)),
 "Support":((33,24,20),(93,55,32),(154,101,57)),
 "Bolt":((24,23,21),(74,66,50),(147,131,96)),
 "Cut":((95,54,27),(188,136,76),(241,198,126)),
 "Leaf":((24,61,26),(75,137,37),(151,194,64)),
 "LeafLight":((34,75,28),(103,160,43),(176,207,82)),
 "LeafShade":((17,46,23),(46,98,31),(99,148,43)),
}
colors=[]
for stops in PALETTES.values():
 for i in range(16):
  t=i/15*2;k=min(1,int(t));f=t-k
  colors.append(tuple(round(stops[k][c]*(1-f)+stops[k+1][c]*f) for c in range(3)))
def chunk(kind,data):
 return struct.pack(">I",len(data))+kind+data+struct.pack(">I",zlib.crc32(kind+data)&0xffffffff)
rows=[]
for y in range(64):
 row=7-y//8;pixels=bytearray()
 for x in range(128):
  level=max(0,min(15,(x+.5)/8-.5));lo=int(level);hi=min(15,lo+1);f=level-lo
  pixels.extend(round(colors[row*16+lo][c]*(1-f)+colors[row*16+hi][c]*f) for c in range(3))
 rows.append(b"\x00"+pixels)
png=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",128,64,8,2,0,0,0))+chunk(b"sRGB",b"\x00")+chunk(b"IDAT",zlib.compress(b"".join(rows),9))+chunk(b"IEND",b"")
(OUT/"MapDetailPalette.png").write_bytes(png)
image=bpy.data.images.load(str(OUT/"MapDetailPalette.png"));image.pack()
material=bpy.data.materials.new("ToyBrickDetailAtlas");material.use_nodes=True
shader=material.node_tree.nodes["Principled BSDF"];shader.inputs["Roughness"].default_value=.76
texture=material.node_tree.nodes.new("ShaderNodeTexImage");texture.image=image;texture.interpolation="Linear"
material.node_tree.links.new(texture.outputs["Color"],shader.inputs["Base Color"])
pieces=[];part_counts={}

def cube(name,pos,size,family="Wood",shade=10,bevel=.025,rotation=(0,0,0)):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos)
 obj=bpy.context.object;obj.name=name;obj.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 obj.rotation_euler=rotation
 if bevel:
  modifier=obj.modifiers.new("Moulded bevel","BEVEL")
  modifier.width=min(bevel,min(size)*.20);modifier.segments=1
  bpy.ops.object.modifier_apply(modifier=modifier.name)
 obj.data.materials.append(material)
 uv=obj.data.uv_layers.active or obj.data.uv_layers.new(name="UVMap")
 row=list(PALETTES).index(family)
 for face in obj.data.polygons:
  center=face.center
  assert face.normal.dot(center)>0,"Box winding must face outward"
  directional=face.normal.z*1.25-face.normal.y*.55+face.normal.x*.3
  for loop in face.loop_indices:
   co=obj.data.vertices[obj.data.loops[loop].vertex_index].co
   value=max(.2,min(15,shade+directional+.35*co.x/size[0]+.2*co.y/size[1]))
   uv.data[loop].uv=((value+.5)/16,(row+.5)/8)
 pieces.append(obj);part_counts[name]=part_counts.get(name,0)+1
 return obj

def bar(name,a,b,width,depth,family,shade,bevel=.025):
 a,b=Vector(a),Vector(b)
 obj=cube(name,(a+b)/2,(width,depth,(b-a).length),family,shade,bevel)
 obj.rotation_euler=(b-a).to_track_quat("Z","Y").to_euler()
 return obj

def bridge():
 # The original deck's top is .5 above its envelope bottom. Keep that plane,
 # its 13.6-wide walk surface, 21 planks and ±31.45 deck endpoints exactly.
 for i in range(21):
  y=(i-10)*3
  shade=10.3+.75*math.sin(i*1.31)+.35*math.cos(i*.57)
  cube("Beveled deck plank",(0,y,.25),(13.6,2.90,.5),"Wood",shade,.045)
  # A shallow mould line accentuates each seam without introducing grain.
  cube("Plank seam shadow",(0,y-1.425,.38),(13.42,.018,.17),"Support",7,0)
  for x in [-4.8,-3.2,-1.6,0,1.6,3.2,4.8]:
   cube("Deck square stud",(x,y,.524),( .29,.29,.048),"Wood",shade+.4,.006)
  for side in [-1,1]:
   cube("Recessed square washer",(side*5.8,y,.5075),(.34,.34,.015),"Support",5,0)
   cube("Square deck peg",(side*5.8,y,.5305),(.18,.18,.031),"Bolt",8,.004)
 # Visible through plank gaps and under open ends; entirely within old envelope.
 for x in [-5.85,0,5.85]:
  cube("Longitudinal support",(x,0,.12),(.48,64,.24),"Support",6,.025)
 for y in range(-30,31,10):
  cube("Cross support",(0,y,.145),(13.45,.70,.29),"Support",7,.025)
 for side in [-1,1]:
  x=side*6.8
  for z,width,height,shade in [(2.8,.45,.45,11.2),(1.6,.38,.32,9.2)]:
   # Rail seams align with posts; the two-stud end sections retain ±32 ends.
   for center,length in [(-31,2),(-25,10),(-15,10),(-5,10),(5,10),(15,10),(25,10),(31,2)]:
    cube("Joined handrail",(x,center,z),(width,length-.025,height),"Rail",shade,.025)
   # Tiny end caps set the envelope to the original full64 length.
   for end in [-1,1]:
    cube("Rail end grain",(x,end*31.985,z),(width,.030,height),"Cut",9,.003)
  for y in range(-30,31,10):
   cube("Studded bridge post",(x,y,1.70),(.8,.8,3.4),"Support",8.5,.035)
   cube("Post crown inset",(x,y,3.405),(.61,.61,.01),"Support",5,0)
   cube("Post square stud",(x,y,3.43175),(.42,.42,.0435),"Rail",11,.006)
   for z in [1.6,2.8]:
    cube("Mortise collar",(x,y,z),(.795,.83,.16),"Support",5.5,.01)
    cube("Outer joinery bolt",(side*7.175,y,z),(.045,.20,.20),"Bolt",10,.004)
  for y in [-25,-5,15]:
   # Small diagonal braces read clearly from the bridge approach.
   bar("Rail diagonal brace",(side*6.79,y-4.5,.72),(side*6.79,y+4.5,2.55),.18,.21,"Support",8,.015)

def bush():
 for pos,size,family,shade in [((0,0,.70),(3.7,2.7,1.4),"Leaf",10),
  ((-.4,.3,1.70),(2.6,2,1),"LeafLight",11)]:
  x,y,z=pos;sx,sy,sz=size
  cube("Rounded foliage brick",pos,size,family,shade,.075)
  for xx in range(max(1,int(sx/.60))):
   for yy in range(max(1,int(sy/.60))):
    px=x+(xx-(int(sx/.60)-1)/2)*.60;py=y+(yy-(int(sy/.60)-1)/2)*.60
    # Omit studs hidden beneath the upper canopy.
    if z<1 and -1.7<px<.9 and -.7<py<1.3:continue
    cube("Bush crown stud",(px,py,z+sz/2+.024),(.22,.22,.048),family,shade+.35,.006)
  for xx in range(max(1,int(sx/.60))):
   for zz in range(max(1,int(sz/.55))):
    px=x+(xx-(int(sx/.60)-1)/2)*.60;pz=z+(zz-(int(sz/.55)-1)/2)*.55
    cube("Bush shaded face stud",(px,y-sy/2-.024,pz),(.22,.048,.22),family,shade-.4,.006)
  for yy in range(max(1,int(sy/.60))):
   for zz in range(max(1,int(sz/.55))):
    py=y+(yy-(int(sy/.60)-1)/2)*.60;pz=z+(zz-(int(sz/.55)-1)/2)*.55
    cube("Bush side stud",(x+sx/2+.024,py,pz),(.048,.22,.22),"LeafShade",12,.006)
 # A narrow darker course adds depth between the two stacked blocks.
 cube("Foliage course shadow",(-.4,.3,1.37),(2.65,2.04,.08),"LeafShade",8,.018)

def log():
 angle=.16;rotation=Matrix.Rotation(angle,3,"Z")
 def local(name,pos,size,family,shade,bevel=.018):
  return cube(name,rotation@Vector(pos),size,family,shade,bevel,(0,0,angle))
 local("Moulded fallen log",(0,0,.65),(3.7,1.25,1.25),"Wood",8.8,.045)
 for side in [-1,1]:
  for depth,width,family,shade in [(1.848,.99,"Support",6),(1.871,.86,"Cut",12),(1.891,.64,"Support",7),(1.907,.48,"Cut",11),(1.92,.24,"Support",7.8)]:
   local("Square cut growth ring",(side*depth,0,.65),(.018,width,width),family,shade,.007)
 for x in [-1.5,-.9,-.3,.3,.9,1.5]:
  for y in [-.31,.31]:
   local("Log crown stud",(x,y,1.298),(.19,.19,.046),"Wood",10,.005)
  local("Log side stud",(x,-.649,.65),(.20,.048,.20),"Wood",8.8,.006)
 for y in [-.51,.51]:
  local("Long moulded bark seam",(0,y,1.27),(3.52,.035,.025),"Support",7,0)

def grass():
 for index,(x,y,h) in enumerate([(-.4,0,.7),(0,.15,1.1),(.38,-.1,.85),(.15,-.4,.55)]):
  angle=x*.25
  cube("Grass brick blade",(x,y,h/2),(.20,.20,h),"LeafLight",10.5+index*.5,.015,(0,angle,0))
  cube("Grass face ridge",(x,y-.104,h*.55),(.07,.014,h*.66),"LeafLight",13,.002,(0,angle,0))
  cube("Grass dark root",(x,y,.10),(.22,.22,.20),"LeafShade",8.5,.012)
  cube("Grass tip cap",(x+math.sin(angle)*h/2,y,h),(.18,.18,.025),"LeafLight",14,.004,(0,angle,0))

models=[];stats={}
for name,builder in [("BrickBridge",bridge),("BrickBush",bush),("BrickLog",log),("BrickGrass",grass)]:
 pieces=[];part_counts={};builder()
 bpy.ops.object.select_all(action="DESELECT")
 for obj in pieces:obj.select_set(True)
 bpy.context.view_layer.objects.active=pieces[0];bpy.ops.object.join()
 obj=bpy.context.object;obj.name=name
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
 # Exact drop-in envelope, centered in X/Y with pivot at its ground plane.
 template=json.loads((ROOT/"assets/map/roblox"/(name+".model.json")).read_text())
 native=template["properties"]["Size"];target=(native[0],native[2],native[1])
 lo=[min(v.co[i] for v in obj.data.vertices) for i in range(3)]
 hi=[max(v.co[i] for v in obj.data.vertices) for i in range(3)]
 scales=[target[i]/(hi[i]-lo[i]) for i in range(3)]
 for vertex in obj.data.vertices:
  vertex.co=Vector(((vertex.co.x-(lo[0]+hi[0])/2)*scales[0],
   (vertex.co.y-(lo[1]+hi[1])/2)*scales[1],(vertex.co.z-lo[2])*scales[2]))
 obj.data.update();obj.data.calc_loop_triangles()
 assert all(t.area>1e-12 for t in obj.data.loop_triangles)
 assert all(t.normal.dot(obj.data.polygons[t.polygon_index].normal)>.999 for t in obj.data.loop_triangles)
 measured=[max(v.co[i] for v in obj.data.vertices)-min(v.co[i] for v in obj.data.vertices) for i in (0,2,1)]
 assert all(abs(a-b)<.00001 for a,b in zip(measured,native)),name+" envelope changed"
 stats[name]={"triangles":len(obj.data.loop_triangles),"vertices":len(obj.data.vertices),
  "robloxSize":measured,"expectedRobloxSize":native,"sourceParts":part_counts,"pivot":"ground-center"}
 assert stats[name]["triangles"]<20000
 if name=="BrickBridge":
  stats[name]["deckTopFromBottom"]=.5*scales[2]
  stats[name]["deckWidth"]=13.6*scales[0]
  stats[name]["deckEndpoints"]=[-31.45*scales[1],31.45*scales[1]]
  assert abs(stats[name]["deckTopFromBottom"]-.5)<.000001
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+".glb")),export_format="GLB",use_selection=True,export_apply=True)
 models.append(obj);obj.location=(len(models)*22,0,0)

bpy.ops.object.select_all(action="DESELECT")
for obj in models:obj.select_set(True)
bundle=OUT/"MapDetailImport.glb"
bpy.ops.export_scene.gltf(filepath=str(bundle),export_format="GLB",use_selection=True,export_apply=True)
raw=bundle.read_bytes();length=struct.unpack_from("<I",raw,12)[0];document=json.loads(raw[20:20+length])
assert len(document["meshes"])==4 and len(document["images"])==1
assert "bufferView" in document["images"][0]
(OUT/"mesh-stats.json").write_text(json.dumps(stats,indent=2))
(OUT/"import-audit.json").write_text(json.dumps({"bundle":bundle.name,"sha256":hashlib.sha256(raw).hexdigest(),
 "meshCount":4,"totalTriangles":sum(s["triangles"] for s in stats.values()),"envelopesPreserved":True,
 "bridgeWalkPlanePreserved":True,"embeddedPalette":True},indent=2))

scene=bpy.context.scene;scene.render.engine="CYCLES";scene.cycles.samples=32
scene.render.resolution_x=1280;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG";scene.render.film_transparent=True
scene.view_settings.view_transform="Standard";scene.view_settings.look="Medium High Contrast"
scene.world.use_nodes=True;scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value=.55
bpy.ops.object.camera_add(location=(20,-28,25));camera=bpy.context.object;camera.data.type="ORTHO";scene.camera=camera
for location,power,size in [((-15,-20,35),2400,15),((20,15,25),1800,12)]:
 bpy.ops.object.light_add(type="AREA",location=location);lamp=bpy.context.object
 lamp.data.energy=power;lamp.data.size=size
 lamp.rotation_euler=(-lamp.location).to_track_quat("-Z","Y").to_euler()
bpy.ops.object.light_add(type="SUN");sun=bpy.context.object;sun.data.energy=1.1;sun.rotation_euler=(.4,-.5,-.6)
for obj in models:obj.hide_render=True
for obj in models:
 obj.hide_render=False;obj.location=(0,0,0)
 if obj.name=="BrickBridge":
  camera.location=(32,-46,34);camera.data.ortho_scale=73;target=Vector((0,0,1.3))
 else:
  camera.location=(6,-9,6);camera.data.ortho_scale=max(obj.dimensions)*2.15;target=Vector((0,0,obj.dimensions.z*.48))
 camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
 scene.render.filepath=str(OUT/(obj.name+".png"));bpy.ops.render.render(write_still=True)
 if obj.name=="BrickBridge":
  camera.location=(16,-42,18);camera.data.ortho_scale=25;target=Vector((0,-23,1.1))
  camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
  scene.render.filepath=str(OUT/"BrickBridgeJoinery.png");bpy.ops.render.render(write_still=True)
  obj.scale.y=39/64
  camera.location=(25,-37,29);camera.data.ortho_scale=49;target=Vector((0,0,1.3))
  camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
  scene.render.filepath=str(OUT/"BrickBridgeGameplay.png");bpy.ops.render.render(write_still=True)
  obj.scale.y=1
 obj.hide_render=True
for index,obj in enumerate(models):obj.hide_render=False;obj.location=(index*22,0,0)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"MapDetailProps.blend"))
print("MAP_DETAIL_READY",json.dumps(stats),flush=True)
