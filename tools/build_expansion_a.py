"""Original brick characters. Run with Blender --background --python this file.
Exports one mesh/material/UV0 per GLB, bottom-origin, front -Y, normalized heights.
"""
import bpy, math, json, random, struct
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/characters/expansion_a';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
PALETTE={
'yellow':(1,.76,.03),'yellowlight':(1,.92,.18),'cyan':(.03,.62,.85),'cyandark':(.025,.39,.58),
'green':(.19,.55,.10),'greenlight':(.48,.8,.13),'greendark':(.06,.26,.055),'olive':(.32,.30,.15),
'ink':(.017,.023,.025),'dark':(.045,.06,.06),'gray':(.29,.32,.32),'silver':(.62,.66,.65),
'white':(1,.97,.85),'pink':(.82,.35,.26),'pinklight':(.98,.59,.41),'brown':(.31,.14,.055),
'gold':(.95,.58,.065),'goldlight':(1,.82,.25),'tan':(.57,.43,.25),'sand':(.77,.64,.42),
'cream':(.98,.84,.57),'red':(.81,.035,.075),'redlight':(1,.13,.17),'blue':(.16,.18,.65),
'potato':(.54,.30,.10),'potatolight':(.74,.47,.20),'potatodark':(.26,.12,.035),'lens':(.012,.06,.075),
'fur':(.23,.20,.15),'floor':(.065,.11,.14),'shoe':(.18,.09,.04),'black':(.008,.009,.011)}
MATS={}
for k,c in PALETTE.items():
 m=bpy.data.materials.new(k);m.diffuse_color=(*c,1);m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*c,1);MATS[k]=m
pieces=[]
def cube(name,pos,size,color,rotation=None,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if rotation:o.rotation_euler=rotation
 o.data.materials.append(MATS[color])
 if bevel:
  mod=o.modifiers.new('Toy mould edge','BEVEL');mod.width=bevel;mod.segments=1;bpy.ops.object.modifier_apply(modifier=mod.name)
 pieces.append(o);return o

def bar(n,a,b,w,d,c,bevel=.02):
 a,b=Vector(a),Vector(b);o=cube(n,(a+b)/2,(w,d,(b-a).length),c,bevel=bevel)
 z=(b-a).normalized();up=Vector((0,1,0)) if abs(z.y)<.99 else Vector((1,0,0));y=(up-z*up.dot(z)).normalized();x=y.cross(z).normalized()
 o.rotation_euler=Matrix((x,y,z)).transposed().to_euler();return o

def studs(o,mini=False,spacing=.38,faces=('front','top')):
 if mini:return
 bpy.context.view_layer.update();sx,sy,sz=(max(v[i] for v in o.bound_box)-min(v[i] for v in o.bound_box) for i in range(3));mat=o.matrix_world.copy();c=o.data.materials[0].name
 for face in faces:
  a,b=(sx,sz) if face=='front' else ((sx,sy) if face=='top' else (sy,sz))
  for i in range(max(1,int(a/spacing))):
   for j in range(max(1,int(b/spacing))):
    x=(i-(max(1,int(a/spacing))-1)/2)*spacing;v=(j-(max(1,int(b/spacing))-1)/2)*spacing
    p=(x,-sy/2-.027,v) if face=='front' else ((x,v,sz/2+.027) if face=='top' else (sx/2+.027,x,v));s=(.15,.055,.15) if face=='front' else ((.15,.15,.055) if face=='top' else (.055,.15,.15))
    z=cube('Square stud',mat@Vector(p),s,c,bevel=.006);z.rotation_euler=o.rotation_euler

def plate(n,p,s,c,mini=False):
 o=cube(n,p,s,c);studs(o,mini);return o

def disk(n,p,r,depth,c,axis='Y',vertices=12):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=p,rotation=(math.pi/2,0,0) if axis=='Y' else (0,0,0));o=bpy.context.object;o.name=n;o.data.materials.append(MATS[c]);pieces.append(o);return o

def ring(n,p,r,thick,c,mini=False):
 count=8 if mini else 12
 for i in range(count):
  a=i*math.tau/count;b=(i+1)*math.tau/count
  bar(n,(p[0]+r*math.cos(a),p[1],p[2]+r*math.sin(a)),(p[0]+r*math.cos(b),p[1],p[2]+r*math.sin(b)),thick,.10,c,bevel=.007)

def eyes(z,y,x=.36,mini=False):
 for side in (-1,1):
  cube('Eye white',(side*x,y,z),(.25,.05,.32),'white',bevel=.005);cube('Pupil',(side*x,y-.034,z),(.13,.035,.22),'ink',bevel=0)
  if not mini:cube('Eye glint',(side*x-.03,y-.058,z+.07),(.045,.015,.05),'white',bevel=0)

def noob(m=False):
 plate('Blue torso',(0,0,2.73),(1.8,.88,1.62),'cyan',m)
 for s in (-1,1):
  plate('Green leg',(s*.47,0,.90),(.83,.83,1.8),'greenlight',m)
  cube('Knee inset',(s*.47,-.43,.8),(.69,.04,.15),'green',bevel=.008)
  plate('Yellow arm',(s*1.25,0,2.72),(.65,.85,1.66),'yellow',m)
  cube('Hand',(s*1.25,-.015,1.79),(.64,.85,.32),'yellowlight')
 head=cube('Smiling noob head',(0,0,4.08),(1.12,.95,1.05),'yellowlight')
 plate('Pizza yellow cap',(0,-.05,4.69),(1.35,1.12,.20),'yellow',m)
 cube('Cap visor',(0,-.65,4.68),(1.50,.45,.13),'yellowlight')
 for s in (-1,1):
  cube('Eye',(s*.24,-.49,4.18),(.12,.04,.21),'ink',bevel=.008)
  cube('Smile corner',(s*.25,-.49,3.83),(.10,.04,.15),'ink',bevel=.005)
 cube('Smile',(0,-.49,3.76),(.55,.04,.10),'ink',bevel=.005)
 if not m:
  for s in (-1,1):cube('Torso seam',(s*.84,-.45,2.74),(.025,.03,1.39),'cyandark',bevel=0)

def elephant(m=False):
 o=plate('Cactus body',(0,.28,2.67),(2.2,2.05,2.25),'green',m);studs(o,m,faces=('side',))
 plate('Cactus crown',(0,.25,3.96),(1.87,1.79,.38),'greenlight',m)
 cube('Elephant face',(0,-.90,3.36),(1.64,.42,1.25),'olive',bevel=.10)
 for s in (-1,1):
  plate('Ear',(s*1.13,-.59,3.43),(.50,.40,1.20),'olive',m)
  for y in (-.55,1.0):
   plate('Cactus leg',(s*.76,y,1.28),(.70,.73,1.32),'green',m)
   plate('Sandal sole',(s*.76,y-.18,.15),(.96,1.35,.30),'brown',m)
   cube('Sandal foot',(s*.76,y-.17,.44),(.70,1.04,.29),'greenlight')
   cube('Sandal strap',(s*.76,y-.35,.59),(.79,.25,.16),'pink')
   cube('Ankle strap',(s*.76,y+.27,.71),(.79,.18,.30),'brown')
  eyeside=(s*.63,-1.125,3.59)
  cube('Elephant eye',eyeside,(.11,.04,.20),'ink',bevel=0)
  if not m:cube('Eye glint',(s*.63-.02,-1.15,3.64),(.035,.02,.045),'white',bevel=0)
  bar('Ivory tusk',(s*.64,-1.03,2.95),(s*.70,-1.65,2.59),.20,.22,'white')
  bar('Tusk tip',(s*.70,-1.65,2.59),(s*.74,-1.96,2.70),.15,.17,'cream')
 # Stepped broad hanging trunk, bending forward at its tip.
 for p,sz in [((0,-1.12,2.84),(.48,.45,.88)),((0,-1.28,2.24),(.43,.46,.56)),((0,-1.55,1.99),(.41,.70,.32))]:cube('Elephant trunk',p,sz,'olive')
 for s in (-1,1):cube('Trunk nostril',(s*.105,-1.91,1.99),(.075,.03,.14),'ink',bevel=0)
 if not m:
  for x in (-.82,-.38,.08,.52,.9):
   for z in (2.15,2.65,3.15,3.7):
    if abs(x)>.72 or z<2.4:bar('Cactus spine',(x,-.76,z),(x+.07,-.95,z+.08),.035,.035,'cream',bevel=0)
  for z in (2.08,2.35,2.62):cube('Trunk crease',(0,-1.52 if z<2.5 else -1.36,z),(.30,.02,.025),'brown',bevel=0)

def tim(m=False):
 plate('Black suit',(0,0,2.66),(1.42,.79,1.62),'ink',m)
 for s in (-1,1):
  leg=bar('Suit leg',(s*.36,0,1.90),(s*.50,-.03,.42),.45,.54,'dark');studs(leg,m,faces=('front',))
  cube('Brown shoe',(s*.50,-.24,.18),(.59,.95,.34),'shoe');cube('Gold shoe trim',(s*.50,-.50,.31),(.49,.43,.07),'gold')
  arm=bar('Jacket sleeve',(s*.69,0,3.26),(s*1.02,-.04,2.33),.40,.47,'ink');studs(arm,m,faces=('front',))
  bar('Bent forearm',(s*1.02,-.04,2.33),(s*.63,-.47,2.13),.36,.40,'dark')
  cube('Mouse hand',(s*.61,-.48,2.10),(.28,.31,.31),'gray')
 cube('White shirt',(0,-.42,3.05),(.55,.065,.58),'white')
 for s in (-1,1):bar('Suit lapel',(s*.54,-.47,3.39),(s*.16,-.48,2.85),.19,.06,'gray',bevel=.006)
 cube('Purple necktie',(0,-.49,2.99),(.13,.06,.57),'blue')
 cube('Mouse head',(0,-.03,3.91),(1.25,.85,.96),'gray',bevel=.12)
 for s in (-1,1):
  cube('Large mouse ear',(s*.63,0,4.54),(.62,.28,.80),'pinklight',rotation=(0,s*-.16,0),bevel=.06)
  cube('Ear inset',(s*.63,-.16,4.56),(.41,.025,.55),'pink',rotation=(0,s*-.16,0),bevel=.03)
  cube('Sunglasses frame',(s*.30,-.50,4.06),(.57,.12,.39),'silver')
  cube('Dark lens',(s*.30,-.573,4.06),(.43,.035,.26),'black',bevel=.009)
  if not m:
   for i in (-1,0,1):bar('Whisker',(s*.19,-.61,3.69+i*.09),(s*.77,-.56,3.70+i*.18),.025,.025,'white',bevel=0)
 cube('Glasses bridge',(0,-.55,4.08),(.15,.10,.07),'silver')
 cube('Mouse muzzle',(0,-.51,3.71),(.70,.18,.31),'silver')
 cube('Pink nose',(0,-.64,3.82),(.23,.13,.18),'pink')
 for s in (-1,1):cube('Incisor',(s*.085,-.63,3.56),(.14,.07,.19),'white',bevel=.003)
 if not m:
  for z in (2.12,2.34,2.56):cube('Suit button',(0,-.43,z),(.055,.03,.06),'silver',bevel=.005)
  for a,b in [((0,.3,1.8),(.75,.65,1.35)),((.75,.65,1.35),(1.24,.64,1.64)),((1.24,.64,1.64),(1.23,.57,2.0))]:bar('Pink tail',a,b,.10,.10,'pink')

def bird(m=False):
 plate('Toucan body',(0,0,2.36),(1.68,1.09,2.38),'dark',m)
 cube('Cream belly',(0,-.58,2.28),(1.20,.14,1.86),'cream',bevel=.06)
 plate('Toucan head',(0,-.03,3.92),(1.65,1.23,1.17),'dark',m)
 for s in (-1,1):
  wing=bar('Long wing',(s*.77,.04,3.15),(s*1.0,-.02,1.14),.45,.54,'dark');studs(wing,m,faces=('front',))
  bar('Bird leg',(s*.44,0,1.22),(s*.44,-.04,.30),.19,.22,'gold')
  for t in (-1,0,1):bar('Orange toe',(s*.44,-.02,.18),(s*.44+t*.18,-.65,.10),.13,.14,'gold')
  disk('Glasses lens',(s*.47,-.735,4.03),.40,.09,'lens')
  ring('Golden round glasses',(s*.47,-.81,4.03),.44,.085,'gold',m)
  bar('Glasses arm',(s*.90,-.73,4.12),(s*.90,.38,4.28),.09,.09,'gold')
 cube('Golden bridge',(0,-.81,4.07),(.17,.09,.075),'gold')
 # Substantial hooked, projecting toucan beak with a dark tip.
 bar('Orange beak',(0,-.70,3.58),(0,-1.15,3.21),.49,.48,'gold')
 cube('Dark beak tip',(0,-1.23,3.04),(.45,.42,.40),'ink',rotation=(.25,0,0),bevel=.05)
 for x,z in [(-.28,4.63),(0,4.76),(.28,4.63)]:cube('Head tuft',(x,.10,z),(.22,.30,.29),'dark',rotation=(0,x*.6,0))
 for x in (-.35,0,.35):bar('Tail feather',(x,.42,1.63),(x,.89,1.23),.25,.24,'dark')

def mole(m=False):
 plate('Mole body',(0,0,2.37),(1.70,1.15,2.06),'fur',m)
 plate('Tan belly',(0,-.61,2.32),(1.14,.13,1.62),'tan',m)
 plate('Mole head',(0,-.01,3.86),(1.65,1.12,1.17),'fur',m)
 for s in (-1,1):
  disk('Round ear',(s*.78,0,4.52),.42,.25,'brown');disk('Ear center',(s*.78,-.15,4.52),.30,.04,'pink')
  bar('Mole leg',(s*.43,0,1.46),(s*.53,-.04,.44),.52,.62,'fur')
  cube('Mole foot',(s*.53,-.30,.21),(.64,.98,.40),'brown')
  arm=bar('Mole arm',(s*.85,.02,3.11),(s*1.13,-.11,2.05),.52,.54,'fur');studs(arm,m,faces=('front',))
  cube('Digging paw',(s*1.12,-.18,1.72),(.50,.62,.42),'brown')
  for i in (-1,0,1):cube('Paw claw',(s*1.12+i*.13,-.51,1.62),(.08,.24,.10),'cream',bevel=.01)
  disk('Goggle glass',(s*.43,-.67,4.03),.36,.10,'ink',vertices=8);ring('Brass goggle rim',(s*.43,-.74,4.03),.39,.10,'tan',True)
  cube('Goggle eye',(s*.43,-.75,4.05),(.19,.05,.23),'white',bevel=.007);cube('Goggle pupil',(s*.43+.025,-.79,4.04),(.095,.025,.14),'ink',bevel=0)
  cube('Goggle strap',(s*.84,0,4.02),(.10,1.12,.17),'brown')
  for i in (-1,0,1):bar('Mole whisker',(s*.23,-.70,3.55+i*.08),(s*.88,-.65,3.55+i*.16),.035,.035,'ink',bevel=0)
 cube('Goggle bridge',(0,-.73,4.04),(.16,.10,.12),'tan')
 cube('Mole muzzle',(0,-.64,3.52),(.85,.18,.40),'dark');cube('Orange nose',(0,-.79,3.65),(.30,.15,.24),'pink')
 if not m:
  for s in (-1,1):
   bar('Overall strap',(s*.47,-.71,3.21),(s*.41,-.72,2.76),.13,.06,'sand');cube('Strap button',(s*.42,-.77,2.77),(.09,.04,.10),'gold')
  cube('Belly pocket',(0,-.71,2.36),(.54,.07,.42),'sand');cube('Pocket seam',(0,-.76,2.19),(.45,.02,.025),'brown',bevel=0)

def raccoon(m=False):
 plate('Tan jacket',(0,0,2.35),(1.57,1.03,1.49),'tan',m)
 cube('Belt',(0,-.03,1.74),(1.65,1.09,.20),'sand');cube('Buckle',(0,-.60,1.74),(.25,.06,.19),'gold')
 for s in (-1,1):
  leg=bar('Tan trouser',(s*.41,0,1.65),(s*.62,-.05,.43),.55,.62,'tan');studs(leg,m,faces=('front',))
  cube('Cream foot',(s*.62,-.28,.19),(.64,1.01,.35),'white')
  arm=bar('Jacket arm',(s*.77,0,2.92),(s*1.06,-.10,2.10),.50,.61,'tan');studs(arm,m,faces=('front',))
  cube('Cream hand',(s*1.07,-.17,1.82),(.53,.55,.39),'white')
  if not m:
   for f in (-1,0,1):cube('Finger',(s*1.07+f*.14,-.42,1.62),(.10,.18,.26),'white')
 cube('Monkey head',(0,-.02,3.57),(1.60,1.12,1.20),'fur',bevel=.06)
 cube('Monkey face',(0,-.61,3.63),(1.18,.11,.85),'white')
 cube('Monkey muzzle',(0,-.66,3.27),(.91,.12,.44),'white')
 for s in (-1,1):
  cube('Monkey ear',(s*.89,0,3.60),(.31,.53,.59),'fur');cube('Cream inner ear',(s*1.055,-.10,3.60),(.035,.30,.39),'white')
  cube('Monkey eye',(s*.27,-.69,3.76),(.13,.035,.17),'ink',bevel=.005)
  cube('Smile corner',(s*.22,-.74,3.31),(.08,.03,.13),'ink',bevel=0)
 cube('Monkey nose',(0,-.72,3.53),(.19,.08,.13),'tan');cube('Smile',(0,-.74,3.24),(.48,.03,.08),'ink',bevel=0)
 cube('Red hat brim',(0,0,4.26),(2.03,1.51,.16),'red')
 plate('Red tall hat',(0,.03,4.71),(1.48,1.17,.79),'red',m)
 cube('Crown band',(0,-.02,4.45),(1.67,1.31,.21),'gold')
 for x in (-.66,-.33,0,.33,.66):
  vs=[(x-.17,y,4.49) for y in (-.77,-.64)]+[(x+.17,y,4.49) for y in (-.77,-.64)]+[(x*1.1,y,4.90) for y in (-.77,-.64)]
  mesh=bpy.data.meshes.new('Crown point');mesh.from_pydata(vs,[],[(0,2,4),(1,5,3),(0,1,3,2),(2,3,5,4),(4,5,1,0)]);mesh.update()
  tooth=bpy.data.objects.new('Crown point',mesh);bpy.context.collection.objects.link(tooth);tooth.data.materials.append(MATS['goldlight']);pieces.append(tooth)
  disk('Crown jewel',(x,-.785,4.45),.045,.03,'white',vertices=8)
 # Raccoon ring tail behind body; visible from the three-quarter preview.
 for i in range(6):bar('Ringed raccoon tail',(0.72+i*.16,.48+i*.15,1.90-i*.18),(0.88+i*.16,.63+i*.15,1.72-i*.18),.42,.46,'fur' if i%2 else 'sand')
 if not m:
  for s in (-1,1):cube('Jacket pocket',(s*.43,-.59,2.39),(.40,.10,.40),'sand');cube('Pocket flap',(s*.43,-.65,2.52),(.44,.05,.10),'tan')

def potato(m=False):
 # Layered chamfered bricks create an original broad potato silhouette.
 for p,s,c in [((0,.07,2.29),(2.01,1.47,2.31),'potato'),((0,.07,2.28),(2.33,1.22,1.57),'potatolight'),((0,.07,2.28),(1.65,1.68,1.84),'potato')]:cube('Potato body',p,s,c,bevel=.15)
 plate('Hamster head',(0,-.20,3.74),(1.60,1.14,.98),'potatolight',m)
 for s in (-1,1):
  disk('Hamster ear',(s*.73,-.15,4.36),.40,.27,'potato');disk('Pink inner ear',(s*.73,-.31,4.36),.27,.045,'pinklight')
  bar('Small arm',(s*1.04,-.01,2.99),(s*1.32,-.38,2.62),.27,.29,'potatolight');cube('Pink paw',(s*1.31,-.44,2.54),(.29,.34,.26),'pinklight')
  bar('Humanlike leg',(s*.57,.01,1.15),(s*.59,-.02,.40),.31,.38,'pinklight')
  cube('Bare foot',(s*.59,-.34,.16),(.53,.91,.29),'pinklight')
  cube('Hamster cheek',(s*.39,-.80,3.52),(.66,.24,.38),'cream',bevel=.07)
  cube('Rodent eye',(s*.43,-.81,3.96),(.24,.08,.26),'ink',bevel=.025)
  cube('Eye sparkle',(s*.43-.045,-.86,4.01),(.065,.02,.075),'white',bevel=0)
  if not m:
   for i in (-1,0,1):bar('Hamster whisker',(s*.32,-.95,3.57+i*.065),(s*.85,-.92,3.57+i*.17),.022,.022,'cream',bevel=0)
   for t in (-1,0,1):cube('Toe',(s*.59+t*.145,-.81,.18),(.12,.16,.15),'pinklight',bevel=.02)
 cube('Pink nose',(0,-.97,3.68),(.23,.16,.16),'pink')
 for s in (-1,1):cube('Buck tooth',(s*.07,-.93,3.34),(.12,.055,.16),'white',bevel=.004)
 if not m:
  rng=random.Random(771)
  for i in range(27):
   x=rng.uniform(-.95,.95);z=rng.uniform(1.36,3.18)
   cube('Potato skin fleck',(x,-.785 if abs(x)<.8 else -.56,z),(rng.uniform(.055,.12),.025,rng.uniform(.045,.11)),'potatodark',bevel=.008)
  for x,z in [(-.6,2.05),(.4,2.73),(.7,1.55),(-.3,3.0)]:
   cube('Potato eye dimple',(x,-.80,z),(.15,.035,.11),'potatodark',bevel=.02);cube('Dimple glint',(x,-.825,z+.025),(.07,.015,.03),'sand',bevel=0)

# Small atlas. Explicitly retain only UVMap and use it for TEXCOORD_0.
img=bpy.data.images.new('ExpansionA_Palette',width=128,height=64,alpha=True);names=list(PALETTE);pixels=[]
for y in range(64):
 for x in range(128):pixels.extend((*PALETTE[names[(y//16)*8+x//16]],1))
img.pixels=pixels;img.filepath_raw=str(OUT/'ExpansionAPalette.png');img.file_format='PNG';img.save();img.pack()
atlas=bpy.data.materials.new('ExpansionA_Atlas');atlas.use_nodes=True;nt=atlas.node_tree;tex=nt.nodes.new('ShaderNodeTexImage');tex.image=img;tex.interpolation='Closest';nt.links.new(tex.outputs['Color'],nt.nodes.get('Principled BSDF').inputs['Base Color']);nt.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.56

def join(name,height):
 bpy.ops.object.select_all(action='DESELECT')
 for o in pieces:o.select_set(True)
 bpy.context.view_layer.objects.active=pieces[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 uv=o.data.uv_layers.active or o.data.uv_layers.new(name='UVMap')
 for p in o.data.polygons:
  i=names.index(o.data.materials[p.material_index].name);u=(i%8+.5)/8;v=(i//8+.5)/4
  for loop in p.loop_indices:uv.data[loop].uv=(u,v)
  p.material_index=0
 for lay in list(o.data.uv_layers):
  if lay!=uv:o.data.uv_layers.remove(lay)
 uv.name='UVMap';o.data.uv_layers.active_index=0;uv.active_render=True;o.data.materials.clear();o.data.materials.append(atlas)
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 zmin=min(v.co.z for v in o.data.vertices);zmax=max(v.co.z for v in o.data.vertices);factor=height/(zmax-zmin)
 for v in o.data.vertices:v.co.z-=zmin;v.co*=factor
 o.data.update();o.data.calc_loop_triangles();return o

stats={};models=[]
for key,builder in [('NoobiniPizzanini',noob),('LiriliLarila',elephant),('TimCheese',tim),('Fluriflura',bird),('TalpaDiFero',mole),('RaccooniJandelini',raccoon),('PipiPotato',potato)]:
 for mini in (False,True):
  pieces.clear();builder(mini);name=key+('_Mini' if mini else '');o=join(name,2 if mini else 5);models.append(o)
  bpy.context.view_layer.update();stats[name]={'triangles':len(o.data.loop_triangles),'vertices':len(o.data.vertices),'dimensions_xyz':[round(v,5) for v in o.dimensions],'mesh_objects':1,'material_slots':1,'uv_layers':['UVMap'],'front':'-Y Blender / -Z Roblox','bottom_z':round(min(v.co.z for v in o.data.vertices),6)}
  bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
  raw=(OUT/(name+'.glb')).read_bytes();stats[name]['glb_bytes']=len(raw)
  size,kind=struct.unpack_from('<II',raw,12);doc=json.loads(raw[20:20+size])
  assert len(doc['meshes'])==1 and len(doc['meshes'][0]['primitives'])==1
  prim=doc['meshes'][0]['primitives'][0];assert 'TEXCOORD_0' in prim['attributes'] and 'TEXCOORD_1' not in prim['attributes']
  assert len(doc['materials'])==1 and len(doc['images'])==1 and 'bufferView' in doc['images'][0]
  stats[name]['glb_verified']={'one_mesh':True,'one_primitive':True,'only_uv0':True,'embedded_palette':True}
  o.hide_render=True;o.hide_set(True)

# One editable source scene contains each joined main and mini; preview is lit at toy scale.
pieces.clear();floor=cube('Studio floor',(0,0,-.11),(11,10,.20),'floor',bevel=.06)
bpy.ops.object.camera_add(location=(7,-13,8));cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=7.7;cam.rotation_euler=(Vector((0,0,2.40))-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.scene.camera=cam
for pos,power,size in [((-4,-6,9),1000,6),((6,-3,7),750,5),((1,6,9),1200,5)]:
 bpy.ops.object.light_add(type='AREA',location=pos);light=bpy.context.object;light.data.energy=power;light.data.size=size;light.rotation_euler=(Vector((0,0,2.5))-light.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.world.color=(.22,.26,.31);scene.render.resolution_x=900;scene.render.resolution_y=900;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
bpy.context.preferences.filepaths.save_version=0
for i in range(7):
 main,mini=models[i*2:i*2+2];main.hide_render=False;main.hide_set(False);mini.hide_render=False;mini.hide_set(False);main.location=(-.60,.35,0);mini.location=(1.5,-1.5,0)
 scene.render.filepath=str(OUT/(main.name+'Preview.png'));bpy.ops.render.render(write_still=True)
 main.location=(0,0,0);mini.location=(0,0,0);main.hide_render=True;main.hide_set(True);mini.hide_render=True;mini.hide_set(True)
# Source opens showing the first pair; all other complete meshes stay named and organized.
models[0].hide_render=False;models[0].hide_set(False);models[0].location=(-.6,.35,0);models[1].hide_render=False;models[1].hide_set(False);models[1].location=(1.5,-1.5,0)
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA';area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ExpansionACharacters.blend'))
(OUT/'mesh-stats.json').write_text(json.dumps(stats,indent=2));print('EXPANSION_A_STATS',json.dumps(stats),flush=True)
