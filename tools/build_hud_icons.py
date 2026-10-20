"""Original Blender HUD sculptures and portable Roblox native-solid templates."""
import bpy, json, math
from pathlib import Path
from mathutils import Matrix, Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets/ui/blender"
NATIVE=ROOT/"assets/ui/roblox"
OUT.mkdir(parents=True,exist_ok=True)
NATIVE.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
palette={
 "red":(.82,.035,.075),"rededge":(.43,.012,.035),"gold":(1,.64,.065),
 "page":(1,.9,.62),"cream":(1,.99,.91),"pink":(1,.10,.50),
 "cyan":(.12,.86,1),"blue":(.055,.39,.96),"lightblue":(.24,.68,1),
 "darkblue":(.025,.12,.37),"wood":(.65,.31,.105),"grain":(.30,.12,.045),
 "ink":(.025,.018,.025),"green":(.31,.80,.10),"banana":(1,.77,.075)
}
materials={}
for name,color in palette.items():
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(*color,1)
 m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value=.32
 materials[name]=m
swap=Matrix(((1,0,0),(0,0,1),(0,1,0)))
objects=[];records=[];groups={}

def solid(name,pos,size,color,angle=0,wedge=False):
 # Authored in Roblox XYZ, converted to Blender XZY for exact native export.
 if wedge:
  x,y,z=(v/2 for v in size)
  vertices=[(-x,-y,-z),(x,-y,-z),(-x,-y,z),(x,-y,z),(-x,y,z),(x,y,z)]
  faces=[(0,2,3,1),(2,4,5,3),(0,4,2),(1,3,5),(0,1,5,4)]
  mesh=bpy.data.meshes.new(name)
  mesh.from_pydata([(x,z,y) for x,y,z in vertices],[],[tuple(reversed(f)) for f in faces])
  obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
 else:
  bpy.ops.mesh.primitive_cube_add(size=1)
  obj=bpy.context.object;obj.dimensions=(size[0],size[2],size[1])
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 obj.name=name;obj.location=swap@Vector(pos)
 # Rotation about front-facing Roblox Z axis.
 r=angle if isinstance(angle,Matrix) else Matrix.Rotation(angle,3,"Z")
 obj.rotation_euler=(swap@r@swap).to_euler()
 obj.data.materials.append(materials[color])
 cf=list(pos)+[r[i][j] for i in range(3) for j in range(3)]
 records.append({"className":"WedgePart" if wedge else "Part","name":name,
  "properties":{"Size":list(size),"CFrame":cf,"Color":list(palette[color]),
  "Anchored":True,"CanCollide":False,"CanTouch":False,"CanQuery":False,
  "Material":"SmoothPlastic","TopSurface":"Smooth","BottomSurface":"Smooth"}})
 objects.append(obj)
 bevel=obj.modifiers.new("Soft toy edge","BEVEL");bevel.width=min(.045,min(size)*.18);bevel.segments=2
 bpy.context.view_layer.objects.active=obj
 bpy.ops.object.modifier_apply(modifier=bevel.name)
 return obj

def book():
 solid("Dark red lower cover",(0,0,.20),(2.55,3.10,.18),"rededge")
 solid("Cream page block",(.08,0,0),(2.30,2.88,.32),"page")
 for y in [-1.25,-.95,-.65,-.35,.0,.35,.65,.95,1.25]:
  solid("Page edge",(.10,y,-.17),(2.26,.018,.024),"gold")
 solid("Red upper cover",(0,0,-.25),(2.55,3.10,.18),"red")
 solid("Gold spine",(-1.11,0,-.27),(.25,3.12,.25),"gold")
 for y in [-1.33,1.33]:
  solid("Gold cover border",(.12,y,-.37),(2.03,.09,.09),"gold")
 solid("Gold cover fore-edge",(1.10,0,-.37),(.09,2.72,.09),"gold")
 solid("Raised book crest",(.12,.14,-.41),(.85,.85,.15),"gold",math.pi/4)
 solid("Crest ruby",(.12,.14,-.51),(.42,.42,.07),"red",math.pi/4)
 solid("Ribbon",(.63,-1.47,-.39),(.29,.62,.10),"rededge")

def arrow_head(tip,direction,color,width=.60,length=.70):
 # Two triangular prisms form an actual solid extruded arrowhead.
 dx,dy=direction;theta=math.atan2(dy,dx)-math.pi/2
 rotation=Matrix.Rotation(theta,3,"Z")
 for side in [-1,1]:
  offset=rotation@Vector((side*width/4,-length/2,0))
  solid("Arrow head prism",(tip[0]+offset.x,tip[1]+offset.y,-.03),
   (.45,length,width/2),color,rotation@Matrix.Rotation(-side*math.pi/2,3,"Y"),True)

def rebirth():
 for start,color in [(18,"pink"),(198,"cyan")]:
  for i in range(13):
   a=math.radians(start+i*10)
   solid("Flowing arc",(1.13*math.cos(a),1.13*math.sin(a),0),(.30,.43,.40),color,a)
  a=math.radians(start+132)
  tip=(1.13*math.cos(a),1.13*math.sin(a))
  arrow_head(tip,(-math.sin(a),math.cos(a)),color,.90,.75)
 # Small glossy facets reinforce volume at tiny HUD sizes.
 for a,color in [(math.radians(60),"cream"),(math.radians(240),"lightblue")]:
  solid("Arc highlight",(1.13*math.cos(a),1.13*math.sin(a),-.225),(.11,.53,.035),color,a)

def gear():
 for i in range(16):
  a=i*math.tau/16
  solid("Gear ring",(1.0*math.cos(a),1.0*math.sin(a),0),(.33,.47,.43),"blue",a)
 for i in range(8):
  a=i*math.tau/8
  solid("Gear tooth",(1.40*math.cos(a),1.40*math.sin(a),0),(.63,.51,.49),"lightblue",a)
 # Recessed dark inner wall; the center remains a real open hole.
 for i in range(12):
  a=i*math.tau/12
  solid("Recess wall",(.76*math.cos(a),.76*math.sin(a),.12),(.16,.43,.24),"darkblue",a)

def log_face(x,y,s):
 solid("Tung Tung log",(x,y,0),(.62*s,.91*s,.42*s),"wood")
 for side in [-1,1]:
  solid("Eye white",(x+side*.16*s,y+.11*s,-.235*s),(.22*s,.26*s,.065*s),"cream")
  solid("Pupil",(x+side*.16*s,y+.09*s,-.278*s),(.10*s,.15*s,.04*s),"ink")
 solid("Smile",(x,y-.23*s,-.26*s),(.25*s,.07*s,.05*s),"ink")
 solid("Wood grain",(x-.24*s,y-.21*s,-.23*s),(.035*s,.26*s,.03*s),"grain")

def merge():
 for x in [-.9,0,.9]: log_face(x,-.95,1.05)
 solid("Upgrade arrow shaft",(0,.01,-.10),(.26,.52,.30),"gold")
 arrow_head((0,.49),(0,1),"gold",.80,.65)
 solid("Upgraded green head",(0,1.10,0),(1.05,.92,.52),"green")
 solid("Banana crown",(0,1.68,0),(1.28,.24,.52),"banana",-.10)
 solid("Cream face",(0,1.10,-.30),(.82,.64,.12),"page")
 for side in [-1,1]:
  solid("Upgraded eye",(side*.23,1.20,-.38),(.14,.18,.06),"ink")
 solid("Upgrade grin",(0,.94,-.38),(.36,.09,.06),"rededge")

for name,builder in [("Book",book),("Rebirth",rebirth),("Gear",gear),("Merge",merge)]:
 objects=[];records=[];builder()
 groups[name]=list(objects)
 (NATIVE/(name+".model.json")).write_text(json.dumps({"className":"Model","children":records},indent=2))
 bpy.ops.object.select_all(action="DESELECT")
 for obj in objects: obj.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+".glb")),export_format="GLB",use_selection=True)
 print("HUD_ICON",name,len(records))

# A preview of each actual sculpture, using the same camera as the Roblox viewer.
scene=bpy.context.scene
scene.render.engine="BLENDER_EEVEE"
scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.film_transparent=True
scene.world.color=(.45,.45,.45)
bpy.ops.object.camera_add(location=(4,-12,6))
camera=bpy.context.object
camera.rotation_euler=(Vector((0,0,0))-camera.location).to_track_quat("-Z","Y").to_euler()
camera.data.type="ORTHO";camera.data.ortho_scale=4.1;scene.camera=camera
for position,power,size in [((-4,-7,8),950,6),((5,-3,4),700,5),((1,4,5),1000,4)]:
 bpy.ops.object.light_add(type="AREA",location=position)
 lamp=bpy.context.object;lamp.data.energy=power;lamp.data.shape="DISK";lamp.data.size=size
 lamp.rotation_euler=(-lamp.location).to_track_quat("-Z","Y").to_euler()
scene.view_settings.view_transform="Standard"
for name,group in groups.items():
 for other,items in groups.items():
  for obj in items: obj.hide_render=other!=name
 scene.render.filepath=str(OUT/(name+".png"));bpy.ops.render.render(write_still=True)
for items in groups.values():
 for obj in items:obj.hide_render=False
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"BrainrotHUD.blend"))
