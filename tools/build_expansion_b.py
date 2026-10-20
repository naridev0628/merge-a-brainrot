"""Original reference-inspired brick characters. Run with Blender 5.2 --background --python.
All geometry is authored here; exports use one mesh, one palette, and exactly UV0.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'characters'/'expansion_b';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
PALETTE={
 'black':(.018,.025,.028),'charcoal':(.045,.06,.065),'graphite':(.09,.115,.12),'steel':(.27,.31,.34),
 'silver':(.55,.58,.64),'white':(.96,.97,1),'orange':(.96,.36,.045),'orange_light':(1,.48,.085),
 'orange_dark':(.65,.22,.025),'stem':(.21,.32,.025),'leaf':(.43,.57,.05),'yellow':(.97,.77,.035),
 'yellow_light':(1,.9,.16),'yellow_dark':(.65,.46,.025),'green':(.44,.68,.05),'brown':(.16,.075,.028),
 'purple':(.37,.18,.65),'lavender':(.63,.40,.94),'pale_purple':(.84,.7,1),'armor':(.12,.10,.16),
 'armor_light':(.23,.20,.28),'red':(.98,.08,.025),'dark_red':(.44,.035,.018),'sole':(.80,.84,.77),
 'floor':(.07,.12,.15),'mouth':(.26,.115,.01),'cream':(1,.90,.65),'toe':(.63,.48,.055),
 'gunmetal':(.16,.19,.21),'beak_tip':(.14,.10,.025),'pupil':(.005,.007,.01),'flamewhite':(.94,.85,1),
}
MATS={}
for name,col in PALETTE.items():
 m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True
 m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*col,1)
 m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.62;MATS[name]=m
pieces=[]
MINI=False
def cube(name,pos,size,color,rotation=None,bevel=.015):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.name=name;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if rotation:o.rotation_euler=rotation
 o.data.materials.append(MATS[color])
 if bevel and not MINI:
  mod=o.modifiers.new('Brick edge','BEVEL');mod.width=bevel;mod.segments=1;bpy.ops.object.modifier_apply(modifier=mod.name)
 pieces.append(o);return o
def bar(name,a,b,width,depth,color,bevel=.015):
 a,b=Vector(a),Vector(b);o=cube(name,(a+b)/2,(width,depth,(b-a).length),color,bevel=bevel)
 z=(b-a).normalized();x=Vector((0,1,0)).cross(z)
 if x.length<.0001:x=Vector((1,0,0))
 x.normalize();y=z.cross(x).normalized();o.rotation_euler=Matrix((x,y,z)).transposed().to_euler();return o
def studs(o,small=False,faces=('front','top'),spacing=.32):
 if small:return
 bpy.context.view_layer.update();sx,sy,sz=(max(v[i] for v in o.bound_box)-min(v[i] for v in o.bound_box) for i in range(3));matrix=o.matrix_world.copy()
 for face in faces:
  a,b=(sx,sz) if face=='front' else ((sx,sy) if face=='top' else (sy,sz))
  for i in range(max(1,int(a/spacing))):
   for j in range(max(1,int(b/spacing))):
    u=(i-(max(1,int(a/spacing))-1)/2)*spacing;v=(j-(max(1,int(b/spacing))-1)/2)*spacing
    pos=(u,-sy/2-.023,v) if face=='front' else ((u,v,sz/2+.023) if face=='top' else (sx/2+.023,u,v))
    dim=(.13,.046,.13) if face=='front' else ((.13,.13,.046) if face=='top' else (.046,.13,.13))
    s=cube('Square brick stud',matrix@Vector(pos),dim,o.data.materials[0].name,bevel=0);s.rotation_euler=o.rotation_euler
def poly(name,verts,faces,color):
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);o.data.materials.append(MATS[color]);pieces.append(o);return o
def ring(name,pos,r,inner,depth,color,axis='Y',sides=12):
 # Radial rings stay faceted and have a genuine open center.
 verts=[]
 for d in (-depth/2,depth/2):
  for rad in (r,inner):
   for i in range(sides):
    a=i*math.tau/sides;u,v=rad*math.cos(a),rad*math.sin(a)
    p=(u,d,v) if axis=='Y' else (d,u,v);verts.append(tuple(pos[k]+p[k] for k in range(3)))
 faces=[]
 for i in range(sides):
  j=(i+1)%sides
  faces.extend([(i,j,sides+j,sides+i),(2*sides+i,3*sides+i,3*sides+j,2*sides+j),(i,2*sides+i,2*sides+j,j),(sides+i,sides+j,3*sides+j,3*sides+i)])
 return poly(name,verts,faces,color)
def disc(name,pos,r,depth,color,axis='Y',sides=12):
 bpy.ops.mesh.primitive_cylinder_add(vertices=sides,radius=r,depth=depth,location=pos);o=bpy.context.object;o.name=name
 o.rotation_euler=(math.pi/2,0,0) if axis=='Y' else (0,math.pi/2,0);o.data.materials.append(MATS[color]);pieces.append(o);return o
def speaker(x,y,z,r,small=False):
 sides=8 if small else 12
 disc('Speaker recessed cavity',(x,y,z),r,.12,'black',sides=sides)
 ring('Speaker silver polygon rim',(x,y-.08,z),r,r*.82,.075,'silver',sides=sides)
 ring('Speaker cone surround',(x,y-.09,z),r*.79,r*.48,.04,'graphite',sides=sides)
 disc('Speaker cone',(x,y-.10,z),r*.46,.035,'steel',sides=sides)
 disc('Speaker dark dustcap',(x,y-.13,z),r*.27,.07,'black',sides=sides)
 if not small:
  for a in (.25,1.82,3.39,4.96):cube('Speaker bolt',(x+r*.9*math.cos(a),y-.13,z+r*.9*math.sin(a)),(.045,.025,.045),'white',bevel=0)

def gorillo(small=False):
 chest=cube('Broad gorilla barrel chest',(0,0,2.72),(2.23,1.14,1.7),'charcoal',bevel=.10);studs(chest,small,('top','side'))
 cube('Lower heavy torso',(0,.05,1.95),(1.65,1.06,.7),'graphite',bevel=.09)
 for side in (-1,1):
  shoulder=cube('Raised sloping shoulder',(side*1.23,.03,3.18),(.75,1.03,.86),'graphite',rotation=(0,side*.16,0),bevel=.05);studs(shoulder,small)
  arm=bar('Huge hanging gorilla arm',(side*1.35,0,3.01),(side*1.72,-.08,1.45),.92,.98,'charcoal',bevel=.055);studs(arm,small,('top',))
  cube('Knuckle hand',(side*1.69,-.17,1.11),(.94,.99,.65),'graphite',bevel=.065)
  for i in range(3):cube('Heavy finger',(side*1.68+(i-1)*.26,-.70,1.02),(.22,.19,.38),'charcoal',bevel=.035)
  bar('Bent thigh',(side*.62,.12,1.83),(side*.95,.16,.91),.73,.85,'charcoal',bevel=.04)
  bar('Gorilla shin',(side*.95,.16,.91),(side*.65,-.07,.38),.61,.70,'graphite',bevel=.04)
  foot=cube('Wide planted gorilla foot',(side*.86,-.29,.20),(1.22,1.11,.40),'graphite',bevel=.065);studs(foot,small,('top',))
  speaker(side*1.53,-.59,2.58,.29,small);speaker(side*1.72,-.68,1.73,.30,small)
  speaker(side*.91,-.64,2.10,.32,small);speaker(side*.62,-.64,2.67,.19,small)
  # Paired curved chest cable motifs visible in the source image.
  for a,b in [((side*.73,-.64,3.52),(side*.93,-.65,3.28)),((side*.93,-.65,3.28),(side*.83,-.65,3.10)),((side*.83,-.65,3.10),(side*.64,-.65,3.12))]:bar('Silver chest cable',a,b,.085,.08,'silver',bevel=.01)
 speaker(0,-.65,2.92,.39,small);speaker(0,-.64,2.27,.23,small)
 head=cube('Gorilla block head',(0,-.02,4.05),(1.47,1.05,1.24),'charcoal',bevel=.085);studs(head,small,('top','side'))
 cube('Crown ridge',(0,.02,4.67),(.79,.80,.31),'graphite',bevel=.04)
 cube('Brown crown patch',(0,-.42,4.71),(.48,.20,.26),'brown',bevel=.02)
 cube('Brown crown stripe',(0,-.56,4.49),(.32,.15,.37),'brown',bevel=.02)
 for side in (-1,1):
  cube('Ear',(side*.80,0,4.10),(.20,.53,.48),'graphite',bevel=.04)
  cube('White gorilla eye',(side*.33,-.58,4.12),(.27,.06,.25),'white',bevel=.008)
  cube('Gorilla pupil',(side*.33,-.62,4.15),(.14,.035,.17),'pupil',bevel=0)
  cube('Heavy brow',(side*.34,-.65,4.31),(.61,.24,.20),'graphite',rotation=(0,side*.06,0),bevel=.02)
 cube('Gorilla muzzle',(0,-.68,3.78),(.89,.40,.51),'graphite',bevel=.065)
 cube('Gorilla nose',(0,-.91,3.97),(.44,.15,.18),'black',bevel=.02)
 for side in (-1,1):cube('Nostril',(side*.11,-1.00,3.99),(.08,.02,.065),'pupil',bevel=0)
 cube('Stern mouth',(0,-.90,3.66),(.53,.035,.065),'black',bevel=.008)

def flame(name,x,y,z,s,flip=1):
 # Thick jagged pixel-flame silhouette; no alpha planes or disconnected texture tricks.
 outline=[(-.26,0),(-.39,.22),(-.22,.43),(-.27,.65),(-.02,.54),(.08,.86),(.02,1.10),(.24,.99),(.39,1.27),(.37,.77),(.20,.54),(.26,.29),(.09,.09)]
 v=[(x+flip*a*s,y+d,z+b*s) for d in (-.07,.07) for a,b in outline];n=len(outline)
 faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 poly(name,v,faces,'lavender')
 if s>.6:bar('Pale flame heart',(x,y-.08,z+.15*s),(x+flip*.1*s,y-.08,z+.52*s),.11*s,.04,'pale_purple',bevel=0)

def toiletto(small=False):
 # Bowl and cistern form the anatomy; heavy machine legs support the toilet base.
 cube('Porcelain toilet plinth',(0,.08,1.60),(1.40,1.23,.76),'white',bevel=.10)
 cube('Porcelain bowl front',(0,-.28,2.04),(1.87,1.67,.63),'white',bevel=.12)
 for side in (-1,1):
  cube('Toilet bowl faceted side',(side*.91,-.13,2.12),(.24,1.37,.53),'silver',bevel=.04)
  cube('Orange seat side',(side*.95,-.18,2.43),(.19,1.62,.18),'orange_dark',bevel=.035)
 cube('Orange seat front',(0,-1.01,2.43),(1.88,.20,.18),'orange',bevel=.035)
 cube('Orange seat rear',(0,.59,2.43),(1.88,.17,.18),'orange',bevel=.025)
 cube('Dark bowl opening',(0,-.20,2.42),(1.56,1.37,.11),'armor',bevel=.09)
 tank=cube('Armored toilet cistern',(0,.36,3.18),(1.65,.97,1.62),'armor_light',bevel=.065);studs(tank,small,('top','side'))
 cube('Cistern front armor',(0,-.18,3.29),(1.61,.18,1.28),'armor',bevel=.035)
 for row in range(3):
  for col in (-1,0,1):cube('Cistern plated segments',(col*.48,-.29,2.85+row*.37),(.43,.07,.32),'armor_light',bevel=.025)
 for side in (-1,1):
  for z in (2.71,3.83):cube('Cistern corner bolt',(side*.69,-.34,z),(.10,.06,.10),'silver',bevel=.01)
  shoulder=cube('Shoulder housing',(side*1.00,.21,3.61),(.54,.71,.63),'armor_light',bevel=.05);studs(shoulder,small)
  bar('Upper robotic arm',(side*1.08,.11,3.43),(side*1.37,-.04,2.81),.32,.40,'silver')
  disc('Arm pivot',(side*1.36,-.28,2.83),.24,.20,'armor')
  forearm=bar('Robot gauntlet',(side*1.38,-.04,2.77),(side*1.58,-.18,2.12),.46,.53,'armor_light',bevel=.045);studs(forearm,small,('front',))
  cube('Robot fist',(side*1.58,-.24,2.00),(.47,.51,.41),'silver',bevel=.05)
  bar('Mechanical thigh',(side*.54,.10,1.59),(side*.68,0,.91),.60,.65,'armor_light',bevel=.04)
  cube('Knee guard',(side*.67,-.39,1.00),(.66,.28,.57),'armor',bevel=.045)
  cube('Shin armor',(side*.70,-.01,.57),(.66,.69,.60),'armor_light',bevel=.045)
  foot=cube('Mechanical boot',(side*.77,-.30,.20),(.96,1.17,.40),'armor',bevel=.06);studs(foot,small,('top',))
  for j in range(3):cube('Silver toe armor',(side*.77+(j-1)*.25,-.90,.24),(.19,.11,.20),'armor_light',bevel=.02)
 head=cube('Robot skull',(0,-.02,4.36),(1.27,.93,.91),'armor_light',bevel=.06);studs(head,small,('top',))
 cube('Forehead cap',(0,0,4.85),(1.11,.85,.16),'armor',bevel=.025)
 cube('Goggle brow rail',(0,-.51,4.65),(1.36,.12,.17),'orange_dark',bevel=.025)
 for side in (-1,1):
  ring('Red goggle surround',(side*.35,-.58,4.49),.28,.22,.13,'red')
  disc('Smoked goggle lens',(side*.35,-.65,4.49),.21,.04,'black')
  cube('Red iris',(side*.35,-.69,4.49),(.10,.025,.12),'red',bevel=.005)
  cube('Goggle glare',(side*.35-.07,-.70,4.58),(.065,.02,.06),'white',bevel=0)
 cube('Respirator nose',(0,-.66,4.24),(.31,.25,.28),'black',bevel=.04)
 cube('Robot jaw',(0,-.57,4.04),(.91,.27,.34),'armor',bevel=.035)
 for x in (-.29,-.14,0,.14,.29):cube('Grille tooth',(x,-.72,4.06),(.075,.035,.18),'silver',bevel=.005)
 for side in (-1,1):
  flame('Ghost flame shoulder',side*1.35,.40,3.25,.85,side)
  flame('Ghost flame outer arm',side*1.79,.20,1.70,.83,side)
  flame('Ghost flame ankle',side*.98,.36,.19,.70,side)
  if not small:flame('Floating ghost wisp',side*1.75,.42,3.89,.36,-side)
 flame('Front central ghost flame',.04,-1.09,.58,.76)

def odin(small=False):
 # A rounded orange built from concentric squared courses, with very long arms.
 courses=[(2.54,1.36,.88,.45),(2.99,1.87,1.18,.46),(3.45,2.12,1.32,.46),(3.91,1.95,1.22,.46),(4.29,1.57,1.04,.32)]
 for z,w,d,h in courses:
  o=cube('Orange fruit brick course',(0,0,z),(w,d,h),'orange_light',bevel=.035)
  studs(o,small,('top','side'))
  if not small:
   for x in [-.78,-.46,-.14,.18,.50,.82]:
    if abs(x)<w/2-.1 and (z<2.8 or z>4.1):cube('Fruit face stud',(x,-d/2-.025,z),(.13,.05,.13),'orange',bevel=0)
 for side in (-1,1):
  arm=bar('Extra long orange arm',(side*.99,.06,3.72),(side*1.65,-.01,2.44),.55,.62,'orange',bevel=.045);studs(arm,small)
  fore=bar('Long orange forearm',(side*1.65,-.01,2.44),(side*2.14,-.15,1.90),.53,.57,'orange',bevel=.035);studs(fore,small,('front','top'))
  cube('Flat orange hand',(side*2.18,-.21,1.78),(.54,.60,.36),'orange_light',rotation=(0,side*.25,0),bevel=.04)
  leg=bar('Thin long fruit leg',(side*.47,.02,2.35),(side*.51,-.01,.72),.40,.44,'orange',bevel=.025);studs(leg,small,('front',))
  cube('White crew sock',(side*.51,-.015,.71),(.44,.48,.55),'white',bevel=.018)
  cube('Black sock stripe',(side*.51,-.27,.90),(.43,.03,.11),'black',bevel=0)
  cube('Sneaker white sole',(side*.51,-.29,.12),(.67,1.05,.24),'sole',bevel=.035)
  cube('Black white sneaker upper',(side*.51,-.26,.35),(.64,.99,.29),'black',bevel=.04)
  cube('White sneaker toe',(side*.51,-.69,.31),(.63,.21,.25),'white',bevel=.03)
  cube('White sneaker tongue',(side*.51,-.27,.52),(.41,.51,.11),'white',bevel=.015)
  for j in range(3):cube('Black sneaker lace',(side*.51,-.13-j*.12,.584),(.34,.055,.025),'black',bevel=0)
  cube('Square eye white',(side*.46,-.676,3.79),(.53,.07,.34),'white',bevel=.008)
  cube('Square black pupil',(side*.44,-.72,3.79),(.19,.035,.27),'pupil',bevel=0)
  cube('White pupil glint',(side*.44-.04,-.745,3.85),(.055,.015,.10),'white',bevel=0)
  cube('Orange heavy eyebrow',(side*.45,-.69,4.05),(.65,.13,.12),'orange_dark',rotation=(0,side*.06,0),bevel=.01)
 cube('Orange nose',(0,-.77,3.43),(.28,.25,.29),'orange',bevel=.04)
 cube('Moustache center',(0,-.69,3.16),(.57,.07,.13),'mouth',bevel=.015)
 for side in (-1,1):bar('Drooping orange moustache',(side*.12,-.70,3.23),(side*.48,-.67,3.11),.14,.08,'orange_dark',bevel=.01)
 cube('Lower orange lip',(0,-.65,2.99),(.56,.08,.065),'orange_dark',bevel=.01)
 for a,b in [((0,0,4.45),(0,.015,4.79)),((0,.015,4.79),(.18,0,5.00)),((.18,0,5.00),(.41,0,4.95)),((.41,0,4.95),(.69,0,4.72))]:bar('Bent green fruit stem',a,b,.13,.16,'stem',bevel=.02)
 bar('Stem leaf',(.37,.02,4.95),(.76,.04,4.70),.18,.08,'leaf',bevel=.015)

def tukanno(small=False):
 # Bird looks forward along -Y; the huge banana bill projects beyond the chest.
 body=cube('Toucan black body',(0,.13,2.16),(1.44,1.38,2.25),'black',bevel=.12);studs(body,small,('top','side'))
 for z,w,d in [(1.29,1.05,.11),(1.65,1.25,.14),(2.05,1.30,.17),(2.45,1.19,.18),(2.84,1.02,.19)]:
  c=cube('Golden chest feather brick',(0,-.61,z),(w,d,.41),'yellow_light' if int(z*10)%2 else 'yellow',bevel=.025);studs(c,small,('front',),.35)
 for side in (-1,1):
  wing=cube('Folded stepped wing',(side*.78,.25,2.20),(.28,1.08,1.69),'charcoal',rotation=(.12,0,side*.04),bevel=.045);studs(wing,small,('side',),.34)
  cube('Wing tip',(side*.71,.52,1.28),(.29,.74,.59),'black',bevel=.04)
  bar('Toucan yellow leg',(side*.40,.08,1.07),(side*.43,-.05,.38),.17,.20,'yellow_dark')
  cube('Bird ankle',(side*.43,-.12,.23),(.30,.37,.27),'yellow',bevel=.025)
  for j in range(3):bar('Splayed bird toe',(side*.43,-.12,.18),(side*.43+(j-1)*.22,-.65-(.12 if j==1 else 0),.10),.14,.14,'yellow',bevel=.015)
  bar('Rear bird toe',(side*.43,-.05,.17),(side*.43,.39,.07),.14,.14,'yellow_dark')
 bar('Rear tail',(0,.68,1.50),(0,1.41,.92),.61,.27,'black',bevel=.035)
 head=cube('Toucan head',(0,-.03,3.62),(1.24,1.18,1.17),'black',bevel=.085);studs(head,small,('top',))
 cube('Black crown',(0,.08,4.25),(.78,.83,.23),'charcoal',bevel=.035)
 # Bill has an arched top, drooped tip and dark division line; not a rectangular slab.
 for name,points,col in [
  ('Upper banana bill',[(-.45,3.25),(-.47,4.07),(-1.17,4.13),(-1.80,3.94),(-2.38,3.57),(-2.50,3.30),(-2.26,3.10),(-1.57,3.41),(-.85,3.42)],'yellow_light'),
  ('Black banana bill seam',[(-.46,3.19),(-.46,3.30),(-.85,3.47),(-1.57,3.46),(-2.26,3.15),(-2.48,3.33),(-2.46,3.16),(-2.27,3.01),(-1.55,3.32),(-.86,3.34)],'black'),
  ('Lower banana bill',[(-.46,3.10),(-.46,3.23),(-.86,3.35),(-1.55,3.33),(-2.27,3.02),(-2.44,3.16),(-2.36,2.91),(-2.17,2.87),(-1.49,3.16),(-.86,3.17)],'yellow')]:
  n=len(points);v=[(x,y,z) for x in (-.47,.47) for y,z in points];f=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)];poly(name,v,f,col)
 cube('Dark banana bill tip',(0,-2.38,3.13),(.95,.26,.24),'beak_tip',rotation=(.45,0,0),bevel=.025)
 if not small:
  for side in (-1,1):
   for y,z in [(-.77,3.82),(-1.08,3.84),(-1.4,3.76),(-1.72,3.63),(-2.01,3.45)]:
    cube('Beak square stud',(side*.494,y,z),(.045,.13,.13),'yellow',bevel=0)
    cube('Beak second row stud',(side*.494,y,z-.22),(.045,.13,.13),'yellow_light',bevel=0)
 for side in (-1,1):
  ring('Green toucan eye ring',(side*.654,-.31,3.80),.39,.27,.10,'green',axis='X')
  disc('Cream toucan eye',(side*.70,-.31,3.80),.27,.055,'cream',axis='X')
  cube('Toucan black pupil',(side*.74,-.38,3.84),(.04,.17,.28),'pupil',bevel=.01)
  cube('Toucan eye glint',(side*.77,-.42,3.91),(.02,.055,.07),'white',bevel=0)

image=bpy.data.images.new('ExpansionBPalette',width=128,height=64,alpha=True)
colors=list(PALETTE.values());pixels=[]
for y in range(64):
 for x in range(128):pixels.extend((*colors[(y//16)*8+x//16],1))
image.pixels=pixels;image.filepath_raw=str(OUT/'ExpansionBPalette.png');image.file_format='PNG';image.save()
atlas=bpy.data.materials.new('ExpansionBAtlas');atlas.use_nodes=True
tex=atlas.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest'
atlas.node_tree.links.new(tex.outputs['Color'],atlas.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
atlas.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.62
def finish(name,height):
 bpy.ops.object.select_all(action='DESELECT')
 for o in pieces:o.select_set(True)
 bpy.context.view_layer.objects.active=pieces[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 low=min(v.co.z for v in o.data.vertices);high=max(v.co.z for v in o.data.vertices);scale=height/(high-low)
 for v in o.data.vertices:v.co.z-=low;v.co*=scale
 for layer in list(o.data.uv_layers):o.data.uv_layers.remove(layer)
 uv=o.data.uv_layers.new(name='UVMap');uv.active_render=True
 names=list(PALETTE)
 for p in o.data.polygons:
  index=names.index(o.data.materials[p.material_index].name);c,r=index%8,index//8
  for j,li in enumerate(p.loop_indices):
   dx,dy=((.3,.3),(.7,.3),(.7,.7),(.3,.7))[j%4];uv.data[li].uv=((c+dx)/8,(r+dy)/4)
  p.material_index=0
 o.data.materials.clear();o.data.materials.append(atlas);o.data.calc_loop_triangles();bpy.context.view_layer.update()
 assert len(o.data.uv_layers)==1
 stats={'triangles':len(o.data.loop_triangles),'vertices':len(o.data.vertices),'dimensions_xyz':[round(v,4) for v in o.dimensions],'bounds_min':[round(min(v.co[i] for v in o.data.vertices),5) for i in range(3)],'bounds_max':[round(max(v.co[i] for v in o.data.vertices),5) for i in range(3)],'mesh_objects':1,'material_slots':1,'uv_layers':['UVMap'],'front':'-Y Blender / -Z Roblox'}
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
 stats['glb_bytes']=(OUT/(name+'.glb')).stat().st_size;return o,stats

stats={};models=[]
for key,builder in [('GorilloSubwoofero',gorillo),('ToilettoFocaccino',toiletto),('OdinDinDinDun',odin),('TukannoBananno',tukanno)]:
 for mini in (False,True):
  MINI=mini;pieces.clear();builder(mini);name=key+('_Mini' if mini else '');o,s=finish(name,2 if mini else 5);stats[name]=s;models.append(o)
for i in range(4):
 models[i*2].location=(i*6-9,0,0);models[i*2+1].location=(i*6-9,-4,0)
pieces.clear();cube('Display',(0,0,-.15),(27,13,.30),'floor',bevel=.08)
bpy.ops.object.camera_add(location=(13,-34,16));camera=bpy.context.object;camera.rotation_euler=(Vector((0,-.5,2.0))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=27;bpy.context.scene.camera=camera
for pos,power,size in [((-7,-9,12),2200,8),((10,-4,10),1600,7),((0,7,10),2400,6)]:
 bpy.ops.object.light_add(type='AREA',location=pos);o=bpy.context.object;o.data.energy=power;o.data.size=size;o.rotation_euler=(Vector((0,0,2))-o.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene;scene.render.engine='BLENDER_EEVEE';scene.world.color=(.28,.31,.39);scene.render.resolution_x=1800;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'ExpansionBPreview.png')
image.pack();bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ExpansionBCharacters.blend'))
(OUT/'mesh-stats.json').write_text(json.dumps(stats,indent=2));print('EXPANSION_B_STATS',json.dumps(stats),flush=True)
bpy.ops.render.render(write_still=True)
# Individual closeups retain front and side silhouettes for visual QA.
for i,key in enumerate(['GorilloSubwoofero','ToilettoFocaccino','OdinDinDinDun','TukannoBananno']):
 x=i*6-9;camera.location=(x+8,-14,8);camera.rotation_euler=(Vector((x,0,2.5))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=7.5
 for j,o in enumerate(models):o.hide_render=j!=i*2
 scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.render.filepath=str(OUT/(key+'Preview.png'));bpy.ops.render.render(write_still=True)
(OUT/'README.md').write_text('''# Expansion B reference-inspired brick characters\n\nRebuild with `blender --background --python tools/build_expansion_b.py`. All geometry is original, procedurally authored in Blender from the four supplied character screenshots.\n\n- GorilloSubwoofero: broad gorilla silhouette, ten recessed faceted speaker cones, chest cables, heavy knuckles and brown crown stripe.\n- ToilettoFocaccino: porcelain toilet bowl/cistern, orange seat, armored robot limbs, red goggles, grille mouth and thick lavender ghost flames.\n- OdinDinDinDun: layered orange fruit, long arms, bent green stem, moustache and black/white sneakers.\n- TukannoBananno: black toucan, huge drooping banana bill, green eye rings, golden chest, folded wings and splayed toes.\n\nEach main GLB is 5 Blender units tall; each `_Mini.glb` is 2 units tall, with reduced surface studs. Every GLB contains exactly one joined mesh, one material, one embedded palette image and a sole UVMap exported as TEXCOORD_0. Bounds start at ground Z=0; front is Blender -Y (Roblox -Z). Use uniform game scaling as needed. Editable Blender scene and reproducible builder are included. See mesh-stats.json for exact triangle counts and bounds.\n''')
