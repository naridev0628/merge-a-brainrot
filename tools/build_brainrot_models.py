"""Reproducible original brick-style models, built in Blender from user references.
Run: blender --background --python tools/build_brainrot_models.py
Exports textured meshes, lightweight Minis, editable .blend and a review render.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'characters' / 'blender'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
PALETTE = {
    'wood': (0.72, .35, .105), 'wood_light': (.91,.51,.20),
    'wood_dark': (.32,.13,.045), 'ivory': (1,.94,.77),
    'white': (1,1,1), 'ink': (.025,.018,.016),
    'green': (.065,.39,.11), 'green_light': (.12,.53,.16),
    'pink': (.86,.36,.39), 'pink_dark': (.43,.12,.14),
    'banana': (.94,.73,.12), 'peel': (1,.91,.42),
    'banana_shade': (.69,.51,.07), 'floor': (.12,.27,.22),
    'shark': (.23,.45,.66), 'sneaker': (.025,.35,.87),
}
MATS = {}
for name,color in PALETTE.items():
    mat=bpy.data.materials.new(name); mat.diffuse_color=(*color,1); mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Roughness'].default_value=.56
    MATS[name]=mat

pieces=[]
def cube(name, pos, size, color, rotation=None, bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj=bpy.context.object; obj.name=name; obj.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if rotation: obj.rotation_euler=rotation
    obj.data.materials.append(MATS[color])
    if bevel:
        mod=obj.modifiers.new('Toy edge', 'BEVEL'); mod.width=bevel; mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
        mod=obj.modifiers.new('Weighted face normals','WEIGHTED_NORMAL')
        bpy.ops.object.modifier_apply(modifier=mod.name)
    pieces.append(obj); return obj

def bar(name, a, b, width, depth, color, bevel=.025):
    a,b=Vector(a),Vector(b)
    obj=cube(name,(a+b)/2,(width,depth,(b-a).length),color,bevel=bevel)
    obj.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return obj

def studs(obj, axes=('front','top'), spacing=.44, small=False, omit=None):
    if small: return
    bpy.context.view_layer.update()
    sx,sy,sz=(max(v[i] for v in obj.bound_box)-min(v[i] for v in obj.bound_box) for i in range(3))
    matrix=obj.matrix_world.copy()
    # Solid square studs match the supplied classic brick references.
    for face in axes:
        a,b=(sx,sz) if face=='front' else ((sx,sy) if face=='top' else (sy,sz))
        nx,ny=max(1,int(a/spacing)),max(1,int(b/spacing))
        for i in range(nx):
            for j in range(ny):
                u=(i-(nx-1)/2)*spacing; v=(j-(ny-1)/2)*spacing
                if omit and face=='front' and omit(u,v): continue
                point=(u,-sy/2-.026,v) if face=='front' else ((u,v,sz/2+.026) if face=='top' else (sx/2+.026,u,v))
                size=(.19,.055,.19) if face=='front' else ((.19,.19,.055) if face=='top' else (.055,.19,.19))
                s=cube('BrickStud',matrix@Vector(point),size,obj.data.materials[0].name,bevel=.009)
                s.rotation_euler=obj.rotation_euler

def tung(small=False):
    body=cube('Tung_BrickBody',(0,0,4.28),(1.75,1.05,3.45),'wood_light',bevel=.075)
    studs(body,('front','top','side'),small=small,omit=lambda u,v: -.38<v<.98)
    # Long straight legs, slightly splayed, broad flat feet.
    for side in (-1,1):
        leg=bar('Leg',(side*.47,0,2.68),(side*.68,-.02,.34),.37,.45,'wood_light')
        studs(leg,('front',),small=small)
        foot=cube('FlatFoot',(side*.68,-.23,.15),(.53,.96,.24),'wood_light')
        studs(foot,('top',),small=small)
        arm=bar('LongArm',(side*.96,0,3.75),(side*1.56,-.05,1.83),.34,.38,'wood_light')
        studs(arm,('front',),small=small)
        cube('Palm',(side*1.56,-.07,1.68),(.39,.37,.42),'wood_light')
        if not small:
            for finger in range(3): cube('Finger',(side*1.56+(finger-1)*.12,-.11,1.43),(.09,.26,.28),'wood_light',bevel=.015)
    for side in (-1,1):
        cube('EyeSocket',(side*.43,-.555,4.91),(.65,.095,.67),'wood')
        cube('SquareEye',(side*.43,-.615,4.88),(.55,.07,.52),'white',bevel=.008)
        cube('SquarePupil',(side*.43,-.66,4.85),(.31,.045,.32),'ink',bevel=.004)
        cube('EyeSpark',(side*.43-.065,-.69,4.94),(.095,.018,.08),'white',bevel=0)
        cube('Eyebrow',(side*.43,-.6,5.3),(.65,.11,.12),'wood_dark',rotation=(0,side*.06,0),bevel=.01)
        cube('SmileCorner',(side*.35,-.59,3.89),(.16,.1,.13),'wood_dark',bevel=.008)
    cube('Nose',(0,-.64,4.38),(.29,.25,.45),'wood_light',bevel=.035)
    cube('Smile',(0,-.59,3.78),(.57,.1,.13),'wood_dark',bevel=.008)
    # The bat is held beside the right hand, not fused into the torso.
    bar('BatGrip',(1.56,-.12,1.55),(1.91,-.14,2.31),.20,.22,'wood_dark')
    bat=bar('WoodenBat',(1.85,-.14,2.18),(2.50,-.16,3.65),.38,.40,'wood')
    studs(bat,('front',),spacing=.46,small=small)
    if not small:
        # Subtle wood-grain grooves: sparse enough to retain the toy-brick silhouette.
        for x,z,length in [(-.69,3.1,.48),(-.32,3.38,.31),(.36,2.96,.39),(.69,3.36,.46),(-.65,5.65,.29),(.62,5.78,.24)]:
            cube('WoodGrain',(x,-.532,z),(.018,.009,length),'wood',bevel=0)
            cube('GrainFork',(x+.045,-.535,z+length*.36),(.085,.01,.018),'wood',bevel=0)
        # End-grain rings on the top of the log, made from inset square outlines.
        for width,depth in [(1.42,.78),(1.02,.52),(.62,.28)]:
            for side in (-1,1):
                cube('EndGrain',(side*width/2,0,6.008),(.018,depth,.012),'wood',bevel=0)
                cube('EndGrain',(0,side*depth/2,6.008),(width,.018,.012),'wood',bevel=0)
        for side in (-1,1):
            cube('LowerEyelid',(side*.43,-.642,4.60),(.57,.10,.075),'wood',bevel=.012)
            cube('Cheek',(side*.61,-.566,4.28),(.34,.07,.17),'wood_light',bevel=.035)
            cube('Knuckle',(side*1.56,-.275,1.72),(.30,.07,.11),'wood',bevel=.018)
            cube('Knee',(side*.59,-.263,1.33),(.28,.075,.32),'wood',bevel=.02)
            for toe in range(3): cube('ToeGroove',(side*.68+(toe-1)*.13,-.65,.278),(.018,.14,.012),'wood',bevel=0)
        for fraction in (.15,.33,.51,.69):
            point=Vector((1.56,-.12,1.55)).lerp(Vector((1.91,-.14,2.31)),fraction)
            band=cube('BatGripBand',point,(.24,.26,.065),'wood_light',bevel=.012)
            band.rotation_euler=Vector((.35,-.02,.76)).to_track_quat('Z','Y').to_euler()
        cube('NoseHighlight',(-.10,-.775,4.42),(.055,.016,.27),'wood_light',bevel=.01)

def chimp(small=False):
    head=cube('GreenChimpHead',(0,0,4.62),(1.76,1.4,2.02),'green',bevel=.055)
    studs(head,('front','top','side'),small=small,omit=lambda u,v: abs(u)<.69 and -.81<v<.77)
    # Pixel-like pink facial silhouette, ears, two small eyes and a downturned mouth.
    cube('PinkFace',(0,-.727,4.88),(1.28,.065,1.02),'pink',bevel=.008)
    cube('PinkMuzzle',(0,-.735,4.13),(.83,.075,.60),'pink',bevel=.008)
    for side in (-1,1):
        cube('Ear',(side*.97,0,4.8),(.23,.55,.79),'pink',bevel=.025)
        cube('EyeWhite',(side*.35,-.775,5.02),(.24,.025,.23),'ivory',bevel=0)
        cube('Eye',(side*.33,-.795,5.02),(.155,.025,.19),'ink',bevel=0)
        cube('Nostril',(side*.14,-.78,4.53),(.105,.03,.065),'ink',bevel=0)
        cube('MouthCorner',(side*.28,-.786,3.99),(.055,.03,.13),'pink_dark',bevel=0)
    cube('Mouth',(0,-.786,4.06),(.59,.03,.055),'pink_dark',bevel=0)
    cube('Collar',(0,0,3.55),(1.82,1.45,.30),'peel',bevel=.025)
    # A continuous curved, tapering banana shell: no human feet or brown monkey head.
    centers=[((0,0,3.35),1.52,1.2),((0,0,2.7),1.50,1.16),((.17,0,2.03),1.31,1.04),((.54,0,1.48),1.06,.90),((1.08,0,1.20),.78,.73),((1.64,0,1.24),.51,.55),((2.04,0,1.53),.24,.29)]
    verts=[]
    for i,(point,w,d) in enumerate(centers):
        prev=Vector(centers[max(0,i-1)][0]); nex=Vector(centers[min(len(centers)-1,i+1)][0])
        tangent=(nex-prev).normalized(); perpendicular=Vector((-tangent.z,0,tangent.x))
        for side,depth in [(-1,-1),(1,-1),(1,1),(-1,1)]: verts.append(Vector(point)+perpendicular*(side*w/2)+Vector((0,depth*d/2,0)))
    faces=[(3,2,1,0)]
    for i in range(len(centers)-1):
        for j in range(4): faces.append((i*4+j,i*4+(j+1)%4,(i+1)*4+(j+1)%4,(i+1)*4+j))
    faces.append(tuple(range((len(centers)-1)*4,len(centers)*4)))
    mesh=bpy.data.meshes.new('CurvedBanana'); mesh.from_pydata(verts,[],faces); mesh.update()
    shell=bpy.data.objects.new('CurvedBanana',mesh); bpy.context.collection.objects.link(shell); shell.data.materials.append(MATS['banana']); pieces.append(shell)
    # Rows of studs follow the curve without bloating the Mini version.
    if not small:
        for point,w,d in centers[:-1]:
            for dx in (-.28,0,.28):
                if abs(dx)<w/2-.08: cube('BananaStud',(point[0]+dx,-d/2-.035,point[2]),(.18,.06,.18),'banana',bevel=.01)
    bar('BananaTip',(2.00,0,1.52),(2.30,0,1.91),.25,.28,'wood_dark')
    # Four broad peeled flaps, each visibly segmented like the reference.
    for side in (-1,1):
        segments=[((side*.63,0,3.38),(side*1.35,0,3.16),.76),((side*1.35,0,3.16),(side*1.72,0,2.67),.66),((side*1.72,0,2.67),(side*1.86,0,2.13),.47)]
        for a,b,width in segments:
            flap=bar('SidePeel',a,b,width,.18,'peel'); studs(flap,('front',),spacing=.43,small=small)
    for sign in (-1,1):
        points=[(0,sign*.55,3.38),(0,sign*.98,3.12),(0,sign*1.17,2.62),(0,sign*1.15,2.17)]
        for i in range(3): bar('FrontPeel',points[i],points[i+1],.78-i*.13,.14,'peel')
    if not small:
        # Stepped brick cap, inset ears, expressive brows and segmented fruit shell.
        cap=cube('HeadCap',(0,0,5.69),(1.58,1.22,.13),'green_light',bevel=.025)
        studs(cap,('top',),spacing=.40)
        for side in (-1,1):
            cube('InnerEar',(side*1.095,-.08,4.8),(.025,.31,.48),'pink_dark',bevel=.015)
            cube('Brow',(side*.35,-.79,5.22),(.36,.04,.055),'pink_dark',rotation=(0,side*.08,0),bevel=.008)
            cube('CheekPixel',(side*.48,-.775,4.64),(.18,.025,.11),'pink_dark',bevel=.005)
            cube('EyeSpark',(side*.33-.035,-.812,5.065),(.047,.012,.045),'white',bevel=0)
        for i in range(1,len(centers)-1):
            point,w,d=centers[i]
            cube('BananaSegmentSeam',(point[0],-d/2-.008,point[2]-.24),(max(.18,w-.12),.016,.024),'banana_shade',bevel=.005)
        for side in (-1,1):
            for z in (2.28,2.7,3.08): cube('SideBananaStud',(side*.68,0,z),(.07,.21,.21),'banana',bevel=.01)
        # A narrow lighter strip down each outer peel gives it thickness and a cut edge.
        for side in (-1,1):
            for a,b in [((side*.74,-.10,3.43),(side*1.35,-.10,3.20)),((side*1.35,-.10,3.20),(side*1.72,-.10,2.7))]:
                bar('PeelRidge',a,b,.09,.055,'ivory',bevel=.015)

def ballerina(small=False):
    cup=cube('CoffeeCup',(0,0,4.58),(2.12,1.72,2.0),'ivory',bevel=.07)
    studs(cup,('front','side'),spacing=.35,small=small,omit=lambda u,v: -.65<v<.63)
    for pos,size in [((0,-.81,5.62),(2.18,.15,.13)),((0,.81,5.62),(2.18,.15,.13)),((-.99,0,5.62),(.15,1.65,.13)),((.99,0,5.62),(.15,1.65,.13))]:
        cube('CupRim',pos,size,'white',bevel=.022)
    cube('CoffeeSurface',(0,0,5.57),(1.88,1.43,.07),'wood_dark',bevel=.03)
    # Latte-art heart, deliberately pixel-shaped to suit the brick world.
    for x,y,w,d in [(-.23,-.15,.41,.30),(.23,-.15,.41,.30),(0,.03,.62,.28),(0,.24,.32,.22)]: cube('LatteFoam',(x,y,5.613),(w,d,.018),'ivory',bevel=.02)
    for a,b in [((-1.04,0,5.23),(-1.66,0,5.23)),((-1.66,0,5.23),(-1.85,0,4.98)),((-1.85,0,4.98),(-1.85,0,4.20)),((-1.85,0,4.20),(-1.58,0,4.0)),((-1.58,0,4.0),(-1.04,0,4.0))]:
        bar('CupHandle',a,b,.22,.25,'ivory',bevel=.035)
    bodice=cube('PinkBodice',(0,0,2.97),(.72,.64,1.14),'pink',bevel=.04); studs(bodice,('front',),spacing=.32,small=small)
    # Flared octagonal skirt with alternating facets.
    verts=[]
    for z,r in [(2.55,.40),(2.03,.96)]:
        for i in range(8): verts.append((math.cos(i*math.tau/8)*r,math.sin(i*math.tau/8)*r,z))
    faces=[tuple(reversed(range(8))),tuple(range(8,16))]
    for i in range(8): faces.append((i,(i+1)%8,(i+1)%8+8,i+8))
    mesh=bpy.data.meshes.new('Tutu'); mesh.from_pydata(verts,[],faces); mesh.update()
    skirt=bpy.data.objects.new('Tutu',mesh); bpy.context.collection.objects.link(skirt); skirt.data.materials.append(MATS['pink']); pieces.append(skirt)
    cube('WaistRibbon',(0,-.36,2.60),(.78,.08,.13),'pink_dark',bevel=.01)
    for side in (-1,1):
        arm=bar('BalletArm',(side*.42,0,3.38),(side*2.37,-.04,3.55),.20,.23,'ivory',bevel=.024)
        studs(arm,('front',),spacing=.35,small=small)
        cube('Hand',(side*2.49,-.04,3.57),(.30,.20,.14),'pink',bevel=.025)
        cube('Eye',(side*.48,-.887,4.80),(.43,.075,.44),'white',bevel=.008)
        cube('Iris',(side*.48,-.932,4.78),(.27,.03,.30),'wood_dark',bevel=.004)
        cube('Pupil',(side*.48,-.95,4.78),(.18,.025,.23),'ink',bevel=0)
        cube('EyeSpark',(side*.48-.045,-.968,4.86),(.07,.015,.07),'white',bevel=0)
        cube('Brow',(side*.48,-.90,5.17),(.60,.06,.08),'wood',rotation=(0,side*.08,0),bevel=.01)
        if not small:
            for i in range(3): bar('Lash',(side*.48+(i-1)*.15,-.942,5.02),(side*.48+(i-1)*.20,-.945,5.17),.035,.035,'ink',bevel=0)
        cube('SmileCorner',(side*.28,-.906,4.17),(.13,.055,.13),'pink',bevel=.008)
    cube('Nose',(0,-.949,4.43),(.24,.17,.24),'pink',bevel=.04)
    cube('Smile',(0,-.91,4.06),(.51,.06,.11),'pink',bevel=.01)
    for name,a,b in [('StandingLeg',(.31,0,2.05),(.48,0,.30)),('RaisedThigh',(-.31,0,2.05),(-.78,0,1.25)),('RaisedCalf',(-.78,0,1.25),(-1.40,-.12,.83))]:
        leg=bar(name,a,b,.22,.26,'ivory'); studs(leg,('front',),spacing=.33,small=small)
    cube('PointeSlipper',(.49,-.14,.17),(.30,.60,.25),'pink',bevel=.035)
    cube('RaisedSlipper',(-1.48,-.21,.78),(.38,.56,.23),'pink',rotation=(0,-.4,0),bevel=.035)

def shark(small=False):
    body=cube('SharkBody',(0,.15,2.75),(2.12,4.5,1.47),'shark',bevel=.07)
    studs(body,('top','side'),spacing=.40,small=small)
    jaw=cube('WhiteJaw',(0,-1.25,2.17),(2.28,2.18,.72),'white',bevel=.035)
    cube('MouthLine',(0,-2.36,2.23),(2.14,.035,.09),'pink',bevel=.008)
    for side in (-1,1):
        cube('MouthSide',(side*1.145,-1.47,2.23),(.025,1.73,.09),'pink',bevel=.005)
        cube('Nostril',(side*.74,-2.135,2.94),(.16,.035,.18),'ink',bevel=.004)
        cube('SharkEye',(side*1.075,-1.47,3.13),(.035,.27,.28),'ink',bevel=.004)
        if not small: cube('EyeGlint',(side*1.098,-1.52,3.20),(.015,.065,.06),'white',bevel=0)
        for i in range(3): cube('Gill',(side*1.077,.10+i*.30,2.80),(.035,.075,.94),'ink',rotation=(.08,0,0),bevel=.005)
        fin=bar('SideFin',(side*.95,.74,2.70),(side*1.65,1.22,2.16),.50,.24,'shark'); studs(fin,('front',),small=small)
    for pos,size in [((0,.27,3.66),(.32,1.26,.45)),((0,.50,4.08),(.32,.84,.42)),((0,.70,4.46),(.32,.43,.36))]:
        fin=cube('DorsalFin',pos,size,'shark',bevel=.025); studs(fin,('side',),spacing=.29,small=small)
    tail=cube('TailStem',(0,2.57,2.77),(.96,1.05,.80),'shark',bevel=.04); studs(tail,('top',),small=small)
    for side in (-1,1):
        fin=bar('TailFluke',(0,2.89,2.83),(0,3.27,2.83+side*1.14),.32,.46,'shark'); studs(fin,('side',),spacing=.35,small=small)
    for x,y in [(-1.18,-.70),(1.18,-.70),(0,1.88)]:
        leg=bar('SharkLeg',(x*.72,y,2.16),(x,y-.18,.57),.47,.52,'shark'); studs(leg,('front',),spacing=.37,small=small)
        cube('WhiteSole',(x,y-.47,.15),(.78,1.23,.25),'white',bevel=.035)
        shoe=cube('BlueSneaker',(x,y-.43,.40),(.73,1.13,.35),'sneaker',bevel=.06)
        cube('ShoeTongue',(x,y-.05,.62),(.50,.46,.16),'shark',bevel=.02)
        if not small:
            for j in range(3): cube('Shoelace',(x,y-.19-j*.14,.585),(.48,.045,.025),'white',bevel=.005)
            cube('ShoePanel',(x+.37,y-.37,.40),(.025,.42,.10),'ivory',bevel=.01)

def join_and_atlas(name):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in pieces: obj.select_set(True)
    bpy.context.view_layer.objects.active=pieces[0]; bpy.ops.object.join()
    obj=bpy.context.object; obj.name=name
    bpy.context.scene.cursor.location=(0,0,0); bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    # One tiny shared palette texture, with padded UV islands to avoid color bleed.
    names=list(PALETTE); uv=obj.data.uv_layers.active or obj.data.uv_layers.new(name='UVMap')
    for poly in obj.data.polygons:
        index=names.index(obj.data.materials[poly.material_index].name)
        col,row=index%4,index//4
        for j,loop in enumerate(poly.loop_indices):
            dx,dy=[(.25,.25),(.75,.25),(.75,.75),(.25,.75)][j%4]
            uv.data[loop].uv=((col+dx)/4,(row+dy)/4)
        poly.material_index=0
    obj.data.materials.clear(); obj.data.materials.append(atlas_mat)
    obj.data.calc_loop_triangles()
    return obj, len(obj.data.loop_triangles)

image=bpy.data.images.new('BrainrotPalette',width=64,height=64,alpha=True)
names=list(PALETTE); pixels=[]
for y in range(64):
    for x in range(64):
        i=(y//16)*4+x//16; col=PALETTE[names[min(i,len(names)-1)]]
        # Image pixels are linear and saved as sRGB for an exact material match.
        pixels.extend((*col,1))
image.pixels=pixels; image.filepath_raw=str(OUT/'BrainrotPalette.png'); image.file_format='PNG'; image.save()
atlas_mat=bpy.data.materials.new('BrainrotAtlas'); atlas_mat.use_nodes=True
tex=atlas_mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=image; tex.interpolation='Closest'
shader=atlas_mat.node_tree.nodes.get('Principled BSDF'); shader.inputs['Roughness'].default_value=.56
atlas_mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])

stats={}; models=[]
for key,builder in [('TungTung',tung),('Chimpanzini',chimp),('Ballerina',ballerina),('Tralalero',shark)]:
    for mini in (False,True):
        pieces.clear(); builder(mini); name=key+('_Mini' if mini else '')
        obj,triangles=join_and_atlas(name); stats[name]={'triangles':triangles,'vertices':len(obj.data.vertices)}
        bpy.context.scene.name=name
        bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
        bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
        bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'MESH'},add_leaf_bones=False,path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
        models.append(obj)

# A clean studio scene for judging silhouettes, with both Minis in front.
for i in range(4):
    x=(i-1.5)*5.3; models[i*2].location.x=x
    models[i*2+1].scale=(.36,)*3; models[i*2+1].location=(x,-3.5,0)
pieces.clear()
cube('DisplayBase',(0,0,-.18),(25,12,.35),'floor',bevel=.16)
for x in range(-12,13):
    for y in range(-5,6): cube('DisplayStud',(x,y,.025),(.30,.30,.09),'floor',bevel=.025)
bpy.ops.object.camera_add(location=(10,-32,17)); camera=bpy.context.object
camera.rotation_euler=(Vector((0,0,2.7))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO'; camera.data.ortho_scale=26; bpy.context.scene.camera=camera
for loc,power,size in [((-4,-7,11),1600,7),((7,-3,8),1100,6),((1,6,10),1700,5)]:
    bpy.ops.object.light_add(type='AREA',location=loc); light=bpy.context.object; light.data.energy=power; light.data.shape='DISK'; light.data.size=size
    light.rotation_euler=(Vector((0,0,3))-light.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=32
scene.world.color=(.22,.26,.31); scene.render.resolution_x=1600; scene.render.resolution_y=900; scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'; scene.render.image_settings.file_format='PNG'
scene.render.filepath=str(OUT/'CharacterPreview.png')
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_perspective='CAMERA'
            area.spaces.active.shading.type='MATERIAL'
image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'BrainrotCharacters.blend'))
(OUT/'mesh-stats.json').write_text(json.dumps(stats,indent=2))
print('MODEL_STATS',json.dumps(stats),flush=True)
bpy.ops.render.render(write_still=True)
