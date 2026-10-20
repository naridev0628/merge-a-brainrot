"""Blender-authored vendor crates and gold stash, with exact primitive placement manifests.
Run: blender --background --threads 4 --python tools/build_stall_props.py
"""
import bpy, math, json
from mathutils import Vector,Matrix
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets'/'map'/'stall_props';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
P={'wood':(.32,.12,.035),'woodlight':(.48,.20,.060),'wooddark':(.18,.065,.018),'edge':(.58,.27,.085),
 'iron':(.075,.08,.075),'gold':(.96,.53,.015),'goldlight':(1,.76,.055),'golddark':(.60,.28,.008),
 'bag':(.75,.54,.25),'baglight':(.91,.73,.40),'bagshade':(.54,.34,.13),'rope':(.35,.20,.055),
 'mark':(.025,.32,.065),'black':(.02,.018,.01),'floor':(.085,.14,.17),'shine':(1,.91,.38)}
M={}
for n,c in P.items():
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*c,1);m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.58;M[n]=m
pieces=[];records=[]
def cube(name,pos,size,color,rotation=(0,0,0),bevel=.012):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.rotation_euler=rotation;o.data.materials.append(M[color])
 if bevel:
  mod=o.modifiers.new('Toy edge','BEVEL');mod.width=bevel;mod.segments=1;bpy.ops.object.modifier_apply(modifier=mod.name)
 pieces.append(o);records.append((o,'Block',size,color));return o
def cyl(name,pos,r,depth,color,rotation=(0,0,0)):
 bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=depth,location=pos);o=bpy.context.object;o.name=name;o.rotation_euler=rotation;o.data.materials.append(M[color]);pieces.append(o);records.append((o,'Cylinder',(r*2,r*2,depth),color));return o
def beam(name,a,b,w,d,color):
 a,b=Vector(a),Vector(b);o=cube(name,(a+b)/2,(w,d,(b-a).length),color)
 z=(b-a).normalized();x=Vector((0,1,0)).cross(z)
 if x.length<.00001:x=Vector((1,0,0))
 x.normalize();y=z.cross(x).normalized();o.rotation_euler=Matrix((x,y,z)).transposed().to_euler();return o
def stud_grid(name,center,nx,ny,spacing,color):
 for x in range(nx):
  for y in range(ny):cube(name,(center[0]+(x-(nx-1)/2)*spacing,center[1]+(y-(ny-1)/2)*spacing,center[2]),(.14,.14,.055),color,bevel=0)

def keycrate():
 # Open top allows the game to put assorted existing mini models inside.
 for i in range(6):cube('Crate floor slat',((i-2.5)*.49,0,.12),(.46,1.91,.20),'woodlight')
 for x in (-1.42,1.42):
  for y in (-.90,.90):cube('Corner upright',(x,y,.80),(.16,.16,1.60),'wooddark')
 for course in range(4):
  z=.32+course*.35
  for side in (-1,1):
   cube('Long crate plank',(0,side*.96,z),(3.03,.16,.29),'woodlight' if course%2 else 'wood')
   cube('End crate plank',(side*1.49,0,z),(.16,1.82,.29),'wood' if course%2 else 'woodlight')
   if course in (0,2,3):
    for x in (-1.29,1.29):cube('Square iron nail',(x,side*1.05,z),(.055,.024,.055),'iron',bevel=0)
   # Narrow contrasting endgrain marks make the stacked slats readable.
   cube('Plank edge seam',(side*.73,-1.05,z+.105),(.55,.015,.018),'edge',bevel=0)
 for side in (-1,1):
  cube('Top long rim',(0,side*.97,1.58),(3.14,.20,.14),'edge')
  cube('Top short rim',(side*1.49,0,1.58),(.20,1.81,.14),'edge')
 # Outer straps leave the interior completely open and usable.
 for x in (-.97,.97):cube('Front wooden strap',(x,-1.08,.80),(.14,.08,1.34),'wooddark')
 return {'interior_bounds_blender':[[-1.34,-.79,.23],[1.34,.79,1.51]],'recommended_mini_slots_blender':[[-.87,0,.24],[0,.03,.24],[.87,0,.24]],'purpose':'Open wooden display container for existing Brainrot mini models.'}

def shippingcrate():
 # Hollow open crate with clearly visible crossed front and rear braces.
 for i in range(5):cube('Shipping crate floor',((i-2)*.42,0,.12),(.39,1.78,.20),'wooddark')
 for side in (-1,1):
  for i in range(5):cube('Vertical side slat',(side*1.03,(i-2)*.35,.94),(.15,.32,1.64),'wood')
  for z in (.31,1.61):cube('End horizontal rail',(side*1.13,0,z),(.14,1.92,.19),'woodlight')
  for i in range(5):cube('Front vertical slat',((i-2)*.42,side*.91,.94),(.39,.12,1.64),'wooddark')
  for z in (.25,1.67):cube('Front horizontal border',(0,side*1.01,z),(2.31,.17,.21),'woodlight')
  for x in (-1.02,1.02):cube('Front vertical border',(x,side*1.02,.96),(.20,.19,1.62),'woodlight')
  beam('Crossed diagonal brace',(-.88,side*1.13,.40),(.88,side*1.13,1.51),.22,.12,'edge')
  beam('Crossed diagonal brace',(-.88,side*1.145,1.51),(.88,side*1.145,.40),.22,.12,'woodlight')
  for x in (-.83,.83):
   for z in (.43,1.48):cube('Dark brace nail',(x,side*1.22,z),(.065,.025,.065),'iron',bevel=0)
 for side in (-1,1):cube('Side top lip',(side*1.06,0,1.78),(.21,1.94,.15),'woodlight')
 return {'interior_bounds_blender':[[-.88,-.77,.23],[.88,.77,1.70]],'purpose':'Tidy empty wooden shipping crate with crossed plank braces and an open top.'}

def bag(x,y,angle):
 # Stepped block silhouette, gathered neck and tied rope match the toy world.
 start=len(pieces)
 cube('Cash bag base',(0,0,.23),(.85,.70,.43),'bag',bevel=.045)
 cube('Cash bag broad body',(0,0,.59),(1.00,.80,.44),'baglight',bevel=.045)
 cube('Cash bag shoulders',(0,0,.91),(.78,.65,.25),'bag',bevel=.025)
 cube('Gathered bag neck',(0,0,1.14),(.45,.40,.26),'bagshade',bevel=.025)
 cube('Bag folded mouth',(0,0,1.36),(.66,.54,.22),'baglight',bevel=.02)
 cube('Bag mouth dark inset',(0,-.01,1.48),(.40,.29,.025),'bagshade',bevel=.01)
 for yy in (-.23,.23):cube('Bag neck rope',(0,yy,1.15),(.54,.075,.10),'rope')
 for xx in (-.25,.25):cube('Bag neck rope',(xx,0,1.15),(.07,.44,.10),'rope')
 cube('Rope knot',(0,-.30,1.15),(.17,.13,.15),'rope',bevel=.02)
 for a,b in [((-.04,-.32,1.13),(-.18,-.36,.93)),((.05,-.32,1.13),(.18,-.36,.91))]:beam('Loose rope tail',a,b,.065,.055,'rope')
 # Pixel dollar sign is actual raised geometry and transfers to native Parts.
 for p,s in [((0,-.413,.63),(.055,.026,.58)),((.015,-.425,.83),(.32,.027,.065)),((-.14,-.425,.73),(.065,.027,.20)),((0,-.425,.63),(.31,.027,.065)),((.14,-.425,.53),(.065,.027,.20)),((-.015,-.425,.43),(.32,.027,.065))]:cube('Green dollar mark',p,s,'mark',bevel=0)
 for side in (-1,1):cube('Fabric crease',(side*.43,-.404,.67),(.025,.026,.25),'bag',rotation=(0,side*.12,0),bevel=0)
 rot=Matrix.Rotation(angle,4,'Z')
 for o in pieces[start:]:o.location=rot@o.location+Vector((x,y,0));o.rotation_euler=(rot.to_3x3()@o.rotation_euler.to_matrix()).to_euler()

def cashstash():
 cube('Gold pile base',(0,0,.10),(3.35,2.14,.20),'golddark',bevel=.03)
 for layer in range(2):
  for i in range(3-layer):
   for j in range(2):
    x=(i-(2-layer)/2)*.88;y=(j-.5)*.72;z=.29+layer*.34
    cube('Gold bullion bar',(x,y,z),(.84,.67,.32),'gold',rotation=(0,0,(i-j)*.025),bevel=.035)
    cube('Bullion top plate',(x,y,z+.17),(.66,.49,.055),'goldlight',bevel=.015)
    if layer==1:stud_grid('Gold bar square studs',(x,y,z+.215),2,1,.28,'goldlight')
 # Coin stacks deliberately use true cylinders, recorded as cylinders in manifest.
 for x,y,n,r in [(-.95,-.42,4,.26),(.37,-.55,3,.30),(.97,.31,5,.25),(-.38,.40,4,.28),(.26,.26,3,.24)]:
  for k in range(n):
   z=.91+k*.075;cyl('Stacked gold coin',(x,y,z),r,.065,'goldlight' if k%2 else 'gold')
  cyl('Coin embossed face',(x,y,.91+(n-1)*.075+.041),r*.75,.02,'shine')
 for x,y,a in [(-1.45,-.55,.13),(1.35,-.50,-.15),(.60,-.91,.20)]:cyl('Loose gold coin',(x,y,.25),.24,.07,'goldlight',rotation=(a,0,a))
 bag(-2.08,.04,-.16);bag(2.08,.20,.13)
 return {'purpose':'Gold bullion, stacked and loose coins, and two tied beige dollar-marked cash bags.'}

img=bpy.data.images.new('StallPropsPalette',width=64,height=64,alpha=True);colors=list(P.values());pixels=[]
for y in range(64):
 for x in range(64):pixels.extend((*colors[(y//16)*4+x//16],1))
img.pixels=pixels;img.filepath_raw=str(OUT/'StallPropsPalette.png');img.file_format='PNG';img.save()
atlas=bpy.data.materials.new('StallPropsAtlas');atlas.use_nodes=True;tex=atlas.node_tree.nodes.new('ShaderNodeTexImage');tex.image=img;tex.interpolation='Closest';atlas.node_tree.links.new(tex.outputs['Color'],atlas.node_tree.nodes['Principled BSDF'].inputs['Base Color']);atlas.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.58
def srgb(c):return 12.92*c if c<=.0031308 else 1.055*c**(1/2.4)-.055
def swap(v):return Vector((v.x,v.z,v.y))
def manifest(name,metadata):
 bpy.context.view_layer.update();result=[]
 for o,shape,size,col in records:
  r=o.rotation_euler.to_matrix();p=o.location;rgb=P[col]
  # Cubes swap local Y/Z; Roblox cylinders are X-axis while Blender cylinders are Z-axis.
  basis=[swap(r@Vector(v)) for v in ([(1,0,0),(0,0,1),(0,1,0)] if shape=='Block' else [(0,0,1),(0,1,0),(1,0,0)])]
  rr=Matrix(basis).transposed();rs=(size[0],size[2],size[1]) if shape=='Block' else (size[2],size[0],size[1])
  result.append({'name':o.name,'type':shape,'material':'SmoothPlastic','palette':col,'color_linear':list(rgb),'color_srgb':[round(srgb(c),6) for c in rgb],'position_blender':list(p),'size_blender':list(size),'rotation_euler_blender':list(o.rotation_euler),'position_roblox':list(swap(p)),'size_roblox':list(rs),'rotation_matrix_roblox':[round(rr[i][j],8) for i in range(3) for j in range(3)]})
 out={'name':name,'schema_version':1,'coordinates':'Blender Z-up; Roblox values already converted X,Z,Y. Use position_roblox and row-major rotation_matrix_roblox directly in CFrame.new. Cylinder size X is its thickness. All parts anchored; cosmetic parts CanCollide=false.','parts':result,'metadata':metadata}
 (OUT/(name+'-layout.json')).write_text(json.dumps(out,indent=2));return len(result)
def join(name):
 bpy.ops.object.select_all(action='DESELECT')
 for o in pieces:o.select_set(True)
 bpy.context.view_layer.objects.active=pieces[0];bpy.ops.object.join();o=bpy.context.object;o.name=name;bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 for layer in list(o.data.uv_layers):o.data.uv_layers.remove(layer)
 uv=o.data.uv_layers.new(name='UVMap');uv.active_render=True;names=list(P)
 for poly in o.data.polygons:
  idx=names.index(o.data.materials[poly.material_index].name);c,r=idx%4,idx//4
  for j,li in enumerate(poly.loop_indices):
   dx,dy=((.3,.3),(.7,.3),(.7,.7),(.3,.7))[j%4];uv.data[li].uv=((c+dx)/4,(r+dy)/4)
  poly.material_index=0
 o.data.materials.clear();o.data.materials.append(atlas);o.data.calc_loop_triangles();bpy.context.view_layer.update()
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
 return o,{'triangles':len(o.data.loop_triangles),'dimensions_xyz':list(o.dimensions),'mesh_objects':1,'material_slots':1,'uv_layers':['UVMap']}
models=[];stats={}
for key,build in [('KeyCrate',keycrate),('ShippingCrate',shippingcrate),('CashStash',cashstash)]:
 pieces.clear();records.clear();meta=build();count=manifest(key,meta);o,s=join(key);s['native_primitives']=count;stats[key]=s;models.append(o)
for i,o in enumerate(models):o.location.x=(i-1)*5.3
pieces.clear();records.clear();cube('Display',(0,0,-.12),(18,7,.24),'floor',bevel=.04)
bpy.ops.object.camera_add(location=(9,-18,13));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,.65))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=18;bpy.context.scene.camera=camera
for p,e in [((-6,-6,9),1400),((7,-3,7),1100),((0,5,9),1500)]:
 bpy.ops.object.light_add(type='AREA',location=p);o=bpy.context.object;o.data.energy=e;o.data.size=6;o.rotation_euler=(Vector((0,0,.7))-o.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene;scene.render.engine='BLENDER_EEVEE';scene.world.color=(.26,.29,.35);scene.view_settings.view_transform='AgX';scene.render.resolution_x=1800;scene.render.resolution_y=900;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'StallPropsPreview.png');img.pack();bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'StallProps.blend'));(OUT/'mesh-stats.json').write_text(json.dumps(stats,indent=2));bpy.ops.render.render(write_still=True)
for i,key in enumerate(['KeyCrate','ShippingCrate','CashStash']):
 x=(i-1)*5.3
 for j,o in enumerate(models):o.hide_render=i!=j
 camera.location=(x+5,-8,6);camera.rotation_euler=(Vector((x,0,.75))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=6.9 if i==2 else 4.5;scene.render.resolution_x=1100;scene.render.resolution_y=900;scene.render.filepath=str(OUT/(key+'Preview.png'));bpy.ops.render.render(write_still=True)
(OUT/'README.md').write_text('''# Blender stall props\n\nOriginal brick-style props authored from the user references. `KeyCrate.glb` is an open slatted crate with mini-placement slots documented in its manifest. `ShippingCrate.glb` is a tidy empty open crate with crossed plank braces. `CashStash.glb` includes bullion bars, coin stacks, loose coins, and two tied beige cash bags with raised green dollar marks.\n\nEach GLB has one mesh, one material, an embedded palette, and only TEXCOORD_0. Rebuild with tools/build_stall_props.py. The editable combined Blender scene, palette, review renders, and exact counts are included.\n\nThe `*-layout.json` files record every primitive before join. Use type Block/Cylinder, size_roblox, position_roblox, rotation_matrix_roblox (row-major), and color_srgb for native Roblox Parts. Coordinates have already been converted from Blender Z-up to Roblox Y-up. Cylinder size X is its thickness, matching Roblox Cylinder geometry. Blender edge bevels and 16-sided coin facets are the only appearance differences from native smooth-edged Parts; all placements/colors are preserved. Crate manifests include interior bounds/placement slots in Blender coordinates.\n''')
print('STALL_STATS',json.dumps(stats),flush=True)
