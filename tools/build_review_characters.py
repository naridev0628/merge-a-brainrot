"""Build the nine review characters as actual Blender meshes and EditableMesh manifests.
Run: blender --background --python tools/build_review_characters.py
"""
import bpy, math, json, struct
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
# Reuse the exact 32-color atlas and proven geometry/export helpers, not a new palette.
helper=(ROOT/'tools/build_expansion_a.py').read_text().split('stats={};models=[]')[0]
# Avoid changing the original pack while loading its definitions.
helper=helper.replace("OUT=ROOT/'assets/characters/expansion_a'", "OUT=ROOT/'assets/characters/review_pack'")
exec(compile(helper,str(ROOT/'tools/build_expansion_a.py'),'exec'),globals())
MINI=False
original_cube=cube
original_studs=studs
def cube(name,pos,size,color,rotation=None,bevel=.025):
 return original_cube(name,pos,size,color,rotation,0 if MINI else min(bevel,min(size)*.2))
def studs(o,mini=False,spacing=.60,faces=('front','top')):
 return original_studs(o,mini,spacing,faces)
def limb(n,a,b,w,c): return bar(n,a,b,w,w,c,bevel=.02)
def feet(z=0.20,x=.48,c='pinklight'):
 for s in (-1,1):
  cube('Foot',(s*x,-.25,z),(.53,.85,.36),c)
def smile(z,y,w=.5):
 cube('Happy mouth',(0,y,z),(w,.045,.08),'ink',bevel=0)
 for s in (-1,1):cube('Smile corner',(s*w/2,y,z+.06),(.07,.045,.13),'ink',bevel=0)
def shades(z,y,x=.33,mini=False):
 for s in (-1,1):
  cube('Dark glasses frame',(s*x,y,z),(.60,.11,.39),'ink')
  cube('Blue black lens',(s*x,y-.065,z),(.46,.03,.25),'lens',bevel=0)
  if not mini:cube('Lens glint',(s*x-.12,y-.085,z+.05),(.16,.02,.035),'silver',bevel=0)
 cube('Glasses bridge',(0,y-.02,z+.03),(.16,.08,.08),'ink',bevel=0)
def animal_face(z=3.7,y=-.65,m=False,fur='tan',ears=True):
 cube('Animal head',(0,y+.50,z),(1.58,1.04,1.04),fur,bevel=.08)
 for s in (-1,1):
  if ears:
   disk('Round ear',(s*.68,y+.48,z+.60),.31,.23,fur,vertices=8)
   disk('Pink ear center',(s*.68,y+.34,z+.60),.19,.04,'pink',vertices=8)
  cube('Cream cheek',(s*.34,y-.06,z-.22),(.63,.23,.39),'cream',bevel=.05)
  cube('Bright dark eye',(s*.39,y-.07,z+.15),(.25,.08,.27),'ink',bevel=.025)
  cube('Eye glint',(s*.39-.04,y-.12,z+.21),(.065,.025,.07),'white',bevel=0)
  if not m:
   for i in (-1,1):limb('Whisker',(s*.29,y-.21,z-.15),(s*.83,y-.22,z-.13+i*.12),.025,'cream')
 cube('Pink nose',(0,y-.24,z-.04),(.22,.12,.16),'pink')
 for s in (-1,1):cube('Buck tooth',(s*.075,y-.21,z-.43),(.13,.07,.16),'white',bevel=.005)

def santa(m=False):
 for s in (-1,1):
  plate('Green noob leg',(s*.46,0,.88),(.83,.83,1.72),'greenlight',m)
  plate('Yellow noob arm',(s*1.24,0,2.52),(.66,.87,1.61),'yellowlight',m)
 plate('Blue vest',(0,0,2.53),(1.76,.95,1.60),'cyan',m)
 cube('Jacket opening',(0,-.49,2.53),(.10,.035,1.43),'cyandark',bevel=0)
 cube('Noob head',(0,0,3.89),(1.20,1.0,1.02),'yellowlight')
 for s in (-1,1):cube('Smiling eye',(s*.26,-.52,4.0),(.13,.04,.22),'ink',bevel=.004)
 smile(3.64,-.52)
 # Asymmetric falling Santa cap reads as a red hat rather than a block tower.
 cube('Fluffy hat brim',(0,0,4.48),(1.46,1.14,.25),'white')
 cube('Santa hat lower',(0,.03,4.79),(1.18,.98,.43),'red')
 cube('Santa hat bent tip',(.28,.02,5.08),(.73,.78,.35),'red',rotation=(0,.30,0))
 cube('Santa pompom',(.70,-.01,5.12),(.38,.43,.43),'white',bevel=.08)
 # Visible multicolor lights across jacket front and arms.
 for i,(x,z) in enumerate([(-1.25,2.94),(-.82,3.10),(-.43,2.90),(0,2.74),(.43,2.90),(.82,3.10),(1.25,2.94)]):
  if i:limb('Light cord',(px,-.56,pz),(x,-.56,z),.045,'greendark')
  cube('Christmas bulb',(x,-.59,z-.10),(.16,.13,.22),('redlight','yellowlight','greenlight','blue')[i%4],bevel=.02)
  px,pz=x,z

def pig(m=False):
 # Wide pink pig, four sturdy legs, projecting snout and strapped bomb pack.
 body=plate('Pig block body',(0,.15,2.17),(2.05,1.66,1.60),'pinklight',m)
 for s in (-1,1):
  for y in (-.39,.76):
   limb('Pig leg',(s*.65,y,1.59),(s*.65,y,.49),.46,'pinklight')
   cube('Cloven hoof',(s*.65,y-.08,.25),(.55,.69,.42),'dark')
   cube('Hoof split',(s*.65,y-.435,.24),(.035,.02,.31),'ink',bevel=0)
 cube('Pig head',(0,-.34,3.31),(1.69,1.20,1.18),'pinklight',bevel=.08)
 for s in (-1,1):
  cube('Triangular looking ear',(s*.67,-.21,4.02),(.42,.37,.74),'pinklight',rotation=(0,s*.25,0),bevel=.04)
  cube('Pink ear inset',(s*.67,-.41,4.04),(.23,.035,.42),'pink',rotation=(0,s*.25,0),bevel=0)
  cube('Pig eye',(s*.44,-.96,3.51),(.17,.045,.23),'ink',bevel=.015)
 cube('Pig snout',(0,-1.08,3.13),(.94,.42,.56),'pink',bevel=.07)
 for s in (-1,1):cube('Snout nostril',(s*.23,-1.30,3.16),(.14,.025,.20),'dark',bevel=.015)
 # Pack rises visibly behind head, with black canister and lit fuse.
 plate('Bomb backpack',(0,1.05,3.02),(1.64,.90,1.76),'dark',m)
 cube('Bomb top',(0,1.05,4.01),(.91,.69,.23),'ink')
 for s in (-1,1):bar('Backpack strap',(s*.73,-.69,3.02),(s*.73,-.69,1.79),.16,.10,'olive')
 limb('Fuse',(0,1.04,4.12),(.24,1.04,4.49),.10,'tan')
 cube('Fuse spark',(.25,1.04,4.53),(.24,.22,.26),'yellowlight',rotation=(0,.45,0))
 for i in range(4):limb('Curly pig tail',(.97,.77+i*.12,2.27+i*.05),(1.19,.89+i*.12,2.32+i*.05),.11,'pink')

def kiwi(m=False):
 # Flat kiwi cross-section is the torso; seeds and cream core read at Mini size.
 disk('Kiwi brown skin',(0,0,2.64),1.44,.91,'brown',vertices=12)
 disk('Kiwi green flesh',(0,-.48,2.64),1.32,.045,'greenlight',vertices=12)
 disk('Kiwi core',(0,-.52,2.64),.50,.035,'cream',vertices=10)
 for i in range(12):
  a=i*math.tau/12; x=.84*math.cos(a);z=2.64+.84*math.sin(a)
  cube('Kiwi seed',(x,-.56,z),(.10,.035,.21),'ink',rotation=(0,-a+math.pi/2,0),bevel=0)
 for s in (-1,1):
  limb('Human leg',(s*.55,.07,1.44),(s*.55,-.03,.37),.35,'pinklight')
  cube('Bare foot',(s*.55,-.30,.17),(.51,.87,.30),'pinklight')
  limb('Raccoon arm',(s*1.25,0,2.85),(s*1.53,-.10,2.16),.26,'fur')
 animal_face(4.02,-.57,m,'fur')
 for s in (-1,1):
  cube('Raccoon eye mask',(s*.39,-.65,4.17),(.54,.045,.37),'ink')
  cube('Raccoon eye',(s*.39,-.685,4.19),(.16,.025,.19),'white',bevel=.005)
  cube('Raccoon pupil',(s*.39,-.705,4.19),(.075,.015,.14),'ink',bevel=0)

def turtle(m=False):
 # Eight long articulated legs span a raised, layered turtle shell.
 disk('Shell base',(0,.18,2.28),1.32,.59,'brown',axis='Z',vertices=10)
 disk('Shell crown',(0,.18,2.79),1.05,.57,'green',axis='Z',vertices=10)
 disk('Shell top',(0,.18,3.14),.68,.24,'greenlight',axis='Z',vertices=8)
 for s in (-1,1):
  for j,y in enumerate((-.73,-.16,.43,1.0)):
   bend=(s*(1.95+(.15 if j in (1,2) else 0)),y*1.65,1.73)
   end=(s*(2.34+(.22 if j in (1,2) else 0)),y*2.05,.15)
   limb('Spider thigh',(s*.95,y,2.41),bend,.26,'greendark');limb('Spider shin',bend,end,.20,'green')
   cube('Sharp spider foot',end,(.24,.33,.24),'brown')
 cube('Turtle head',(0,-1.12,2.31),(1.13,.81,.78),'greenlight',bevel=.09)
 for s in (-1,1):
  cube('Turtle eye white',(s*.35,-1.55,2.49),(.27,.07,.29),'white')
  cube('Turtle pupil',(s*.35,-1.60,2.49),(.13,.03,.22),'ink',bevel=0)
  limb('Downward fang',(s*.28,-1.57,2.11),(s*.24,-1.69,1.61),.16,'cream')
 if not m:
  for a in range(8):
   t=a*math.tau/8
   cube('Shell tile',(.82*math.cos(t),.18+.82*math.sin(t),3.08),(.42,.42,.13),'olive',rotation=(0,0,t),bevel=.02)
 cube('Small turtle tail',(0,1.60,2.20),(.28,.70,.28),'green',rotation=(.35,0,0))

def corn(m=False):
 # Rounded corn ear with actual yellow kernel grid, green folded husks and hamster face.
 cube('Corn cob',(0,0,2.44),(1.62,1.13,2.45),'gold',bevel=.16)
 for x in (-.56,-.19,.19,.56):
  for row in range(6):cube('Golden corn kernel',(x,-.62,1.42+row*.38),(.34,.22,.33),'yellowlight' if row%2 else 'yellow',bevel=.04)
 for s in (-1,1):
  bar('Green husk leaf',(s*.50,.14,.98),(s*1.03,-.08,2.99),.47,.20,'green',bevel=.03)
  bar('Husk fold',(s*.45,-.67,1.04),(s*.99,-.51,2.57),.35,.12,'greenlight',bevel=.02)
  limb('Small arm',(s*.96,0,2.70),(s*1.32,-.23,2.16),.22,'tan')
  cube('Hamster paw',(s*1.31,-.26,2.08),(.27,.32,.25),'pinklight')
  limb('Hamster leg',(s*.45,0,1.15),(s*.48,-.02,.40),.28,'tan')
 feet(c='pinklight')
 animal_face(3.98,-.58,m,'sand')

def shrimp(m=False):
 # Cat face fused to a deep orange segmented shrimp with shell tail and antennae.
 for i in range(5):
  cube('Shrimp shell segment',(0,.08+i*.36,2.57-i*.30),(1.54-i*.15,.55,1.22-i*.11),'gold' if i%2 else 'pink',rotation=(i*.12,0,0),bevel=.08)
 for s in (-1,1):
  cube('Shrimp tail fan',(s*.34,1.94,.94),(.69,.63,.20),'gold',rotation=(.35,0,s*.4))
  limb('Shrimp cat leg',(s*.49,.07,1.99),(s*.52,-.18,.42),.33,'gold')
  cube('Cat paw',(s*.52,-.43,.20),(.55,.83,.35),'cream')
  for j in range(3):limb('Shrimp feeler leg',(s*.67,.40+j*.38,2.10-j*.24),(s*1.14,.40+j*.38,1.55-j*.24),.10,'pinklight')
 cube('Orange cat head',(0,-.35,3.59),(1.72,1.16,1.25),'gold',bevel=.09)
 for s in (-1,1):
  cube('Cat ear',(s*.64,-.18,4.33),(.47,.50,.64),'gold',rotation=(0,s*.22,0))
  cube('Ear inner',(s*.64,-.45,4.34),(.26,.04,.39),'pink',rotation=(0,s*.22,0),bevel=0)
  cube('Square yellow cat eye',(s*.42,-.95,3.75),(.49,.07,.43),'yellowlight')
  cube('Cat pupil',(s*.42,-1.0,3.76),(.095,.025,.32),'ink',bevel=0)
  cube('Cat muzzle',(s*.25,-.99,3.33),(.48,.20,.32),'cream',bevel=.04)
  limb('Long antenna base',(s*.42,-.14,4.12),(s*.66,-.10,4.75),.055,'pinklight')
  limb('Long antenna tip',(s*.66,-.10,4.75),(s*1.12,-.28,5.13),.045,'pinklight')
  for j in (-1,1):limb('Cat whisker',(s*.35,-1.11,3.39),(s*1.06,-1.04,3.39+j*.16),.025,'cream')
 cube('Cat nose',(0,-1.13,3.43),(.21,.10,.15),'pink')

def footera(m=False):
 # A genuine upright foot silhouette, broad toe foreground and narrower heel/head.
 cube('Foot ankle face',(0,.08,3.72),(1.44,1.07,1.28),'sand',bevel=.12)
 plate('Blue jacket',(0,.02,2.55),(1.70,1.02,1.36),'blue',m)
 cube('Foot heel',(0,.24,1.36),(1.38,1.07,1.13),'sand',bevel=.12)
 cube('Wide forefoot',(0,-.50,.54),(1.90,1.85,.82),'sand',bevel=.14)
 for i in range(5):
  x=-.76+i*.37;h=.57-i*.055
  cube('Distinct foot toe',(x,-1.40,.44),( .34,.67,h),'cream',bevel=.07)
  if not m:cube('Toenail',(x,-1.61,.44+h/2),(.22,.26,.035),'white',bevel=.015)
 for s in (-1,1):
  limb('Jacket arm',(s*.85,0,3.03),(s*1.15,-.11,2.15),.39,'blue')
  cube('Gangster hand',(s*1.14,-.16,1.94),(.40,.47,.35),'sand')
  bar('Jacket lapel',(s*.60,-.55,3.17),(s*.16,-.58,2.65),.19,.08,'cyan')
 shades(3.93,-.50,mini=m)
 cube('Cap brim',(0,-.28,4.42),(1.90,1.49,.16),'ink')
 plate('Flat black cap',(0,.04,4.67),(1.52,1.09,.38),'dark',m)
 smile(3.47,-.49,.42)
 for i in range(7):
  x=-.55+i*.183;z=2.88-.35*math.sin(i/6*math.pi)
  cube('Gold chain link',(x,-.61,z),(.17,.10,.17),'goldlight',rotation=(0,math.pi/4,0),bevel=.02)
 cube('Gold pendant',(0,-.66,2.43),(.29,.10,.34),'gold',bevel=.02)

def beaver(m=False):
 plate('Striped gangster jacket',(0,0,2.42),(1.64,1.08,1.60),'white',m)
 for z in (1.90,2.25,2.60,2.95):cube('Black prisoner stripe',(0,-.565,z),(1.65,.035,.16),'ink',bevel=0)
 for s in (-1,1):
  limb('Black trouser',(s*.42,0,1.64),(s*.47,-.04,.39),.48,'ink')
  cube('Beaver foot',(s*.47,-.34,.18),(.62,.96,.33),'brown')
  limb('Striped arm',(s*.83,0,2.99),(s*1.15,-.05,2.05),.43,'white')
  for z in (2.24,2.58,2.89):cube('Sleeve stripe',(s*(1.15-(z-2.05)*.34),-.28,z),(.46,.045,.14),'ink',bevel=0)
  cube('Beaver paw',(s*1.15,-.10,1.81),(.45,.51,.39),'brown')
 cube('Beaver broad head',(0,-.04,3.68),(1.71,1.16,1.05),'brown',bevel=.08)
 for s in (-1,1):
  disk('Beaver ear',(s*.79,-.01,4.17),.27,.22,'brown',vertices=8)
  cube('Broad muzzle',(s*.33,-.68,3.44),(.65,.27,.37),'tan',bevel=.05)
  cube('Large incisor',(s*.13,-.86,3.19),(.22,.10,.33),'white',bevel=.006)
 cube('Beaver nose',(0,-.86,3.60),(.32,.17,.21),'ink')
 shades(3.86,-.67,mini=m)
 cube('Black hat brim',(0,0,4.34),(2.07,1.53,.18),'ink')
 plate('Black gangster hat',(0,.05,4.72),(1.46,1.12,.62),'dark',m)
 cube('Hat white band',(0,-.015,4.47),(1.51,1.17,.15),'white')
 cube('Beaver broad paddle tail',(0,1.12,1.21),(1.02,1.49,.27),'brown',rotation=(.40,0,0),bevel=.06)
 if not m:
  for x in (-.31,0,.31):bar('Tail texture',(x,.67,1.18),(x,1.72,1.60),.025,.025,'tan',bevel=0)

def lirili(m=False):
 body=plate('Wide cactus body',(0,.10,2.93),(2.45,1.51,2.10),'greenlight',m)
 studs(body,m,spacing=.50,faces=('side',))
 for side in (-1,1):
  leg=plate('Broad cactus leg',(side*.66,.10,1.22),(.94,1.21,1.38),'greenlight',m)
  studs(leg,m,spacing=.50,faces=('side',))
  plate('Brown sandal sole',(side*.66,-.25,.19),(1.13,1.96,.34),'brown',m)
  cube('Sandal cactus toe',(side*.66,-.40,.48),(.89,1.53,.27),'greenlight')
  cube('Sandal toe strap',(side*.66,-.73,.68),(1.02,.27,.22),'pink')
  cube('Sandal ankle strap',(side*.66,.35,.72),(1.02,.23,.40),'pink')
  cube('Strap dark clasp',(side*.66,-.88,.69),(.11,.035,.16),'ink',bevel=0)
 cube('Tan elephant face',(0,-.73,3.60),(1.66,.75,1.53),'tan',bevel=.07)
 for side in (-1,1):
  cube('Elephant large ear',(side*1.02,-.50,3.54),(.55,.55,1.24),'tan',bevel=.04)
  cube('Elephant eye',(side*.61,-1.13,3.93),(.18,.045,.25),'ink',bevel=.01)
  cube('Eye glint',(side*.61-.025,-1.16,4.0),(.06,.02,.07),'white',bevel=0)
  bar('Ivory tusk root',(side*.59,-1.03,3.13),(side*.72,-1.62,2.63),.28,.29,'white')
  bar('Ivory tusk tip',(side*.72,-1.62,2.63),(side*.87,-2.04,2.49),.22,.24,'white')
 cube('Elephant upper trunk',(0,-1.16,3.08),(.50,.59,.97),'tan',rotation=(.15,0,0))
 cube('Elephant hanging trunk',(0,-1.31,2.44),(.44,.55,.53),'tan',rotation=(.3,0,0))
 cube('Trunk bent tip',(0,-1.57,2.15),(.43,.57,.32),'tan',rotation=(.3,0,0))
 for side in (-1,1):cube('Nostril',(side*.11,-1.87,2.13),(.08,.035,.15),'ink',bevel=0)
 # The clock is deliberately disconnected geometry in this same MeshPart.
 cx,cy,cz=2.15,-.15,4.45
 plate('Floating alarm clock',(cx,cy,cz),(1.27,.48,1.54),'gray',m)
 cube('Clock ivory face',(cx,cy-.265,cz),(1.04,.05,1.27),'white')
 for i in range(12):
  a=i*math.tau/12
  cube('Clock hour mark',(cx+.43*math.sin(a),cy-.305,cz+.53*math.cos(a)),(.09,.025,.12),'ink',rotation=(0,-a,0),bevel=0)
 cube('Clock minute hand',(cx,cy-.335,cz+.17),(.095,.025,.42),'ink',bevel=0)
 cube('Clock hour hand',(cx+.19,cy-.34,cz),(.43,.025,.095),'ink',bevel=0)
 for side in (-1,1):
  cube('Alarm bell',(cx+side*.43,cy,cz+.87),(.51,.53,.25),'silver',rotation=(0,side*.22,0))
  bar('Clock foot',(cx+side*.38,cy,cz-.73),(cx+side*.48,cy-.03,cz-.96),.18,.21,'gray')
 bar('Clock handle left',(cx-.30,cy,cz+.85),(cx-.30,cy,cz+1.10),.09,.10,'silver')
 bar('Clock handle top',(cx-.30,cy,cz+1.10),(cx+.30,cy,cz+1.10),.09,.10,'silver')
 bar('Clock handle right',(cx+.30,cy,cz+1.10),(cx+.30,cy,cz+.85),.09,.10,'silver')

BUILDERS=[('NoobiniSantanini',santa),('SvininaBombardino',pig),('PipiKiwi',kiwi),('Tartaragno',turtle),('PipiCorni',corn),('TrippiTroppi',shrimp),('GangsterFootera',footera),('BanditoBobritto',beaver),('RaccooniJandelini',raccoon),('LiriliLarila',lirili)]
stats={};models=[]
for key,builder in BUILDERS:
 for mini in (False,True):
  MINI=mini;pieces.clear();builder(mini);name=key+('_Mini' if mini else '');o=join(name,2 if mini else 5);models.append(o)
  bpy.context.view_layer.update();o.data.calc_loop_triangles()
  vertices=[[round(v.co.x,6),round(v.co.z,6),round(v.co.y,6)] for v in o.data.vertices]
  uv=o.data.uv_layers.active.data;faces=[]
  for tri in o.data.loop_triangles:
   assert tri.area>1e-12 and tri.normal.length>.99,(name,'Degenerate mesh face')
   order=(0,2,1);faces.append({'vertices':[tri.vertices[i] for i in order],'uv':[[round(uv[tri.loops[i]].uv.x,6),round(uv[tri.loops[i]].uv.y,6)] for i in order],'normal':[round(tri.normal.x,6),round(tri.normal.z,6),round(tri.normal.y,6)]})
  bounds_min=[min(v[i] for v in vertices) for i in range(3)];bounds_max=[max(v[i] for v in vertices) for i in range(3)]
  payload={'size':[round(bounds_max[i]-bounds_min[i],6) for i in range(3)],'center':[round((bounds_max[i]+bounds_min[i])/2,6) for i in range(3)],'boundsMin':bounds_min,'boundsMax':bounds_max,'name':name,'textureId':126041920116744,'height':2 if mini else 5,'vertices':vertices,'faces':faces,'coordinateSystem':'Roblox XYZ; front -Z; zero-based indices; mirrored winding'}
  (OUT/(name+'.mesh.json')).write_text(json.dumps(payload,separators=(',',':')))
  bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
  raw=(OUT/(name+'.glb')).read_bytes();size,kind=struct.unpack_from('<II',raw,12);doc=json.loads(raw[20:20+size])
  assert len(doc['meshes'])==1 and len(doc['materials'])==1 and len(doc['meshes'][0]['primitives'])==1
  prim=doc['meshes'][0]['primitives'][0];assert 'TEXCOORD_0' in prim['attributes'] and 'TEXCOORD_1' not in prim['attributes']
  count=len(faces);assert count<=(1500 if mini else 5000),(name,count)
  stats[name]={'triangles':count,'vertices':len(vertices),'height':2 if mini else 5,'mesh_objects':1,'material_slots':1,'uv_layers':['UVMap'],'glb_bytes':len(raw)}
  o.hide_render=True;o.hide_set(True)
(OUT/'mesh-stats.json').write_text(json.dumps(stats,indent=2))
print('REVIEW_STATS',json.dumps(stats),flush=True)
# One editable scene, pairs staged separately for inspection. Isolated preview per character.
MINI=False;pieces.clear();floor=cube('Studio floor',(0,0,-.13),(14,12,.25),'floor',bevel=.04)
bpy.ops.object.camera_add(location=(8,-17,10));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,2.3))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=8.6;bpy.context.scene.camera=camera
for pos,power,size in [((-7,-7,11),1900,8),((7,-3,9),1400,7),((0,7,11),2100,6)]:
 bpy.ops.object.light_add(type='AREA',location=pos);light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((0,0,2))-light.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene;scene.render.engine='BLENDER_EEVEE';scene.world.color=(.24,.27,.33);scene.render.resolution_x=800;scene.render.resolution_y=800;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
bpy.context.preferences.filepaths.save_version=0
for i,(key,_) in enumerate(BUILDERS):
 camera.data.ortho_scale=11.4 if key=='Tartaragno' else 8.6
 main,mini=models[i*2:i*2+2];main.hide_render=False;main.hide_set(False);mini.hide_render=False;mini.hide_set(False);main.location=(-.65,.4,0);mini.location=(1.7,-1.6,0)
 scene.render.filepath=str(OUT/(key+'Preview.png'));bpy.ops.render.render(write_still=True)
 main.location=(0,0,0);mini.location=(0,0,0);main.hide_render=True;main.hide_set(True);mini.hide_render=True;mini.hide_set(True)
models[0].hide_render=False;models[0].hide_set(False);models[1].hide_render=False;models[1].hide_set(False);models[0].location=(-.65,.4,0);models[1].location=(1.7,-1.6,0)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ReviewCharacters.blend'))
# One native Studio import: separate named meshes, embedded atlas, spaced gallery.
for index,o in enumerate(models):
 o.hide_render=False;o.hide_set(False);o.location=((index%5)*9,(index//5)*9,0)
bpy.ops.object.select_all(action='DESELECT')
for o in models:o.select_set(True)
bpy.context.view_layer.objects.active=models[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'ReviewCharacters.glb'),export_format='GLB',use_selection=True,export_apply=True)
market=[];market_material=None
for index,key in enumerate(('BrainrotLogKeeper','BrainrotCoffeeKeeper','BrainrotMarketSign')):
 source=ROOT/'assets/map/brainrot_market'/(key+'.glb')
 if not source.exists():continue
 before=set(bpy.data.objects)
 bpy.ops.import_scene.gltf(filepath=str(source))
 imported=[o for o in bpy.data.objects if o not in before and o.type=='MESH']
 assert len(imported)==1,(key,len(imported))
 o=imported[0];o.name=key
 # The three market exports use the same atlas; retain one shared material.
 if market_material is None:market_material=o.data.materials[0]
 o.data.materials.clear();o.data.materials.append(market_material)
 o.location=(index*14,40,0);market.append(o)
bpy.ops.object.select_all(action='DESELECT')
for o in models+market:o.select_set(True)
bpy.context.view_layer.objects.active=models[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'ReviewImport.glb'),export_format='GLB',use_selection=True,export_apply=True)
raw=(OUT/'ReviewImport.glb').read_bytes();size,kind=struct.unpack_from('<II',raw,12);doc=json.loads(raw[20:20+size])
combined={'mesh_count':len(doc['meshes']),'material_count':len(doc['materials']),'image_count':len(doc.get('images',[])),'names':[n['name'] for n in doc['nodes'] if 'mesh' in n],'bytes':len(raw)}
assert combined['mesh_count']==len(models)+len(market)
assert set(combined['names'])==set(o.name for o in models+market)
(OUT/'combined-import-validation.json').write_text(json.dumps(combined,indent=2))
print('COMBINED_IMPORT',json.dumps(combined),flush=True)
(OUT/'README.md').write_text('''# Review character pack

Original procedural Blender geometry based on the requested character descriptions. Rebuild with `blender --background --python tools/build_review_characters.py`.

Ten main/mini pairs: eight newly authored characters, Raccooni Jandelini rebuilt from the existing original helper, and refined Lirili Larila with a floating alarm clock. Each GLB contains one mesh, one atlas material, UV0, embedded identical Expansion A palette. Main height 5, Mini height 2, bottom-origin. Main front Blender -Y / Roblox -Z. Editable source: ReviewCharacters.blend. Each mesh.json supplies zero-based triangle vertices, per-face UVs and normals in Roblox axes, with mirrored winding. Palette Roblox asset 126041920116744. See mesh-stats.json for budgets and individual previews for visual review.
''')
