"""Original rock island and Lucky Block. Run with Blender --background --python.
Uses the established mesh/atlas helpers without touching the character palette.
"""
from pathlib import Path
import argparse, re, sys
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--only', choices=['BrickRockIsland', 'LuckyBlock', 'CoolTralalero'])
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
source = Path(__file__).with_name('build_brainrot_models.py').read_text()
prefix = source.split('stats={}; models=[]')[0]
prefix = prefix.replace("OUT = ROOT / 'assets' / 'characters' / 'blender'", "OUT = ROOT / 'assets' / 'map' / 'blender'")
prefix = prefix.replace("'BrainrotPalette.png'", "'LuckyBlock.palette.png'").replace("'BrainrotPalette'", "'BonusPalette'").replace("'BrainrotAtlas'", "'BonusAtlas'")
palette = {
    'rock': (.22,.29,.41), 'rock_light': (.32,.40,.52),
    'rock_dark': (.16,.22,.33), 'moss': (.045,.37,.025),
    'moss_light': (.12,.53,.035), 'white': (1,1,1),
    'gold_top': (1,.84,.004), 'gold_upper': (1,.64,.005),
    'gold_middle': (1,.43,.003), 'gold_lower': (1,.22,.003),
    'gold_bottom': (.94,.12,.001), 'gold_detail': (.008,.012,.018),
    'flower_center': (1,.78,.005), 'water': (.025,.42,.68),
    'rim_gold': (1,.65,.005), 'floor': (.015,.26,.86),
}
prefix = re.sub(r'PALETTE = \{.*?\n\}', 'PALETTE = '+repr(palette), prefix, count=1, flags=re.S)
exec(compile(prefix, str(Path(__file__).with_name('build_brainrot_models.py')), 'exec'))
from mathutils import Matrix
import bmesh

def lucky_atlas(obj):
    """One UV0 atlas, with a padded continuous gold gradient in the middle tile."""
    names=list(PALETTE)
    image.scale(256,256)
    pixels=[]
    # Keep the lower face orange, with no red stop, as in the supplied reference.
    stops=[(0,(1,.40,.003)),(.25,(1,.46,.003)),(.5,(1,.58,.003)),(.75,(1,.71,.004)),(1,PALETTE['gold_top'])]
    for y in range(256):
        for x in range(256):
            index=(y//64)*4+x//64
            color=PALETTE[names[index]]
            if names[index]=='gold_middle':
                t=max(0,min(1,((y%64)/63-.125)/.75))
                segment=min(3,int(t*4));blend=t*4-segment
                color=tuple(stops[segment][1][c]*(1-blend)+stops[segment+1][1][c]*blend for c in range(3))
            pixels.extend((*color,1))
    image.pixels=pixels;image.save()
    uv=obj.data.uv_layers.active
    uv.name='UVMap'
    # The base join helper already placed each face in its palette cell.
    gold_cells={names.index(name) for name in ['gold_top','gold_upper','gold_middle','gold_lower','gold_bottom','rim_gold']}
    for poly in obj.data.polygons:
        first=uv.data[poly.loop_start].uv
        cell=int(first.y*4)*4+int(first.x*4)
        if cell in gold_cells:
            for loop_index in poly.loop_indices:
                z=(obj.matrix_world@obj.data.vertices[obj.data.loops[loop_index].vertex_index].co).z
                uv.data[loop_index].uv=(.125,.5+(.125+.75*max(0,min(1,z/3.80)))/4)
    # Explicitly export the authored texture as TEXCOORD_0, never a spare UV set.
    obj.data.uv_layers.active_index=0
    obj.data.uv_layers[0].active_render=True
    tex.interpolation='Linear'

def soft_box(name,pos,size,color,bevel=.04):
    obj=cube(name,pos,size,color,bevel=0)
    mod=obj.modifiers.new('Molded toy edge','BEVEL');mod.width=bevel;mod.segments=3
    bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=obj.modifiers.new('Weighted face normals','WEIGHTED_NORMAL')
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj

# Mesh data construction keeps the many tiny studs inexpensive to regenerate.
def box_fast(name, pos, size, color):
    x,y,z=pos; a,b,c=[d/2 for d in size]
    verts=[(x+dx*a,y+dy*b,z+dz*c) for dx,dy,dz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    faces=[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);obj.data.materials.append(MATS[color]);pieces.append(obj)
    return obj

def surface_studs(center, size, color, spacing=.73, boxes=()):
    # Stud every exposed top and vertical face; leave the water-contact base flat.
    for axis,sign in [(0,-1),(0,1),(1,-1),(1,1),(2,1)]:
        others=[i for i in range(3) if i!=axis]
        a,b=others; na=max(1,int(size[a]/spacing)); nb=max(1,int(size[b]/spacing))
        for ia in range(na):
            for ib in range(nb):
                p=list(center);p[axis]+=sign*(size[axis]/2+.028)
                p[a]+=(ia-(na-1)/2)*spacing;p[b]+=(ib-(nb-1)/2)*spacing
                if any(all(abs(p[k]-c[k])<s[k]/2+.01 for k in range(3)) for c,s in boxes):continue
                dims=[.23,.23,.23];dims[axis]=.062
                box_fast('SquareBrickStud',p,dims,color)

def daisy(x,y,z,scale=1):
    cube('DaisyStem',(x,y,z+.15*scale),(.10*scale,.10*scale,.30*scale),'moss',bevel=.008)
    for dx,dy,w,d in [(-.20,0,.28,.18),(.20,0,.28,.18),(0,-.20,.18,.28),(0,.20,.18,.28)]:
        cube('WhiteDaisyPetal',(x+dx*scale,y+dy*scale,z+.31*scale),(w*scale,d*scale,.075*scale),'white',bevel=.008)
    cube('GoldenDaisyCenter',(x,y,z+.37*scale),(.18*scale,.18*scale,.09*scale),'flower_center',bevel=.008)

def rock_island():
    rocks=[
      ((0,0,.40),(11.8,9.7,.8),'rock_dark'),
      ((-3.5,-.6,1.30),(4.4,6.9,1.8),'rock'),
      ((1.20,.10,1.48),(5.1,7.2,2.16),'rock_light'),
      ((-1.95,2.25,2.82),(3.0,3.4,4.04),'rock'),
      ((2.70,2.32,2.70),(6.2,2.8,2.5),'rock_light'),
      ((-.38,-2.45,2.25),(2.5,3.3,3.7),'rock'),
      ((3.25,-3.75,1.09),(3.6,2.15,1.38),'rock'),
    ]
    boxes=[(c,s) for c,s,col in rocks]
    for i,(center,size,color) in enumerate(rocks):
        cube('RockLedge_%02d'%i,center,size,color,bevel=.055)
        surface_studs(center,size,color,boxes=boxes[:i]+boxes[i+1:])
    moss=[
      ((-4.0,-.20,2.30),(2.35,2.20,.20)),
      ((-3.08,-1.7,2.30),(.65,1.50,.20)),
      ((-2.80,-2.15,1.61),(.65,.24,1.42)),
      ((-1.95,2.2,4.94),(2.4,2.65,.20)),
      ((-1.95,.59,4.00),(.75,.22,1.95)),
      ((-1.95,.31,3.05),(.75,.65,.20)),
      ((-.35,-2.32,4.20),(1.92,2.52,.20)),
      ((.75,-2.32,3.75),(.25,.76,.80)),
      ((1.08,-2.32,3.38),(.75,.76,.20)),
      ((-.42,-3.76,3.50),(.74,.22,1.40)),
      ((-.42,-3.95,2.82),(.74,.6,.20)),
      ((-3.4,.78,3.8),(.23,.8,2.08)),
    ]
    for i,(center,size) in enumerate(moss):
        color='moss_light' if i%3==0 else 'moss'
        cube('MossBrickStrip_%02d'%i,center,size,color,bevel=.022)
        surface_studs(center,size,color,spacing=.42)
    daisy(-4.05,-.25,2.4,1.2);daisy(-.40,-2.10,4.30,1.1)
    daisy(-2.35,2.56,5.04,.70)

def question_mark():
    # A single continuous silhouette avoids overlapping coplanar strokes.
    pattern=['#####','#...#','...##','..##.','..#..','.....','..#..']
    cells={(x,6-y) for y,row in enumerate(pattern) for x,char in enumerate(row) if char=='#'}
    verts=[];faces=[];indices={}
    def vertex(x,y,z):
        key=(x,y,z)
        if key not in indices:
            indices[key]=len(verts);verts.append(((x-2.5)*.35,y,.73+z*.35))
        return indices[key]
    for x,z in cells:
        front=-2.005;back=-1.86
        faces.append(tuple(vertex(a,front,b) for a,b in [(x,z),(x+1,z),(x+1,z+1),(x,z+1)]))
        faces.append(tuple(vertex(a,back,b) for a,b in [(x,z+1),(x+1,z+1),(x+1,z),(x,z)]))
        for dx,dz,edge in [(-1,0,[(x,z+1),(x,z)]),(1,0,[(x+1,z),(x+1,z+1)]),(0,-1,[(x,z),(x+1,z)]),(0,1,[(x+1,z+1),(x,z+1)])]:
            if (x+dx,z+dz) not in cells:
                (a,b),(c,d)=edge
                faces.append((vertex(a,front,b),vertex(a,back,b),vertex(c,back,d),vertex(c,front,d)))
    mesh=bpy.data.meshes.new('ContinuousPixelQuestion');mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new('WhitePixelQuestionMark',mesh);bpy.context.collection.objects.link(obj);obj.data.materials.append(MATS['white']);pieces.append(obj)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    # Dissolve coplanar pixel-cell boundaries before beveling the silhouette.
    bm=bmesh.new();bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bmesh.ops.dissolve_limit(bm,angle_limit=.001,verts=list(bm.verts),edges=list(bm.edges))
    bm.to_mesh(mesh);bm.free();mesh.update()
    bevel=obj.modifiers.new('Soft pixel edges','BEVEL');bevel.width=.035;bevel.segments=3;bpy.ops.object.modifier_apply(modifier=bevel.name)
    normal=obj.modifiers.new('Weighted normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=normal.name)

def lucky_block():
    # A single molded shell avoids seams across the white relief and gold gradient.
    soft_box('GoldenBody',(0,0,1.90),(3.80,3.80,3.80),'gold_middle',bevel=.07)
    soft_box('YellowTopPlate',(0,0,3.80),(3.72,3.72,.12),'gold_top',bevel=.035)
    # Thin inset top border and small corner caps maintain the open yellow top.
    for side in (-1,1):
        cube('TopBorder',(side*1.77,0,3.90),(.095,3.48,.12),'rim_gold',bevel=.015)
        cube('TopBorder',(0,side*1.77,3.90),(3.48,.095,.12),'rim_gold',bevel=.015)
    for x in (-1.80,1.80):
        for y in (-1.80,1.80):
            for z in (.15,3.76):soft_box('WhiteCornerCap',(x,y,z),(.35,.35,.30),'white',bevel=.025)
    # Classic square brick studs read clearly from the game's elevated camera.
    for x in (-1.14,-.38,.38,1.14):
        for y in (-1.14,-.38,.38,1.14):
            soft_box('TopLegoStud',(x,y,3.94),(.48,.48,.18),'gold_top',bevel=.035)
    for face in range(4):
        transform=Matrix.Rotation(face*math.pi/2,4,'Z')
        start=len(pieces)
        # Shallow embossed squares, strongest near the lower orange corners.
        for u in (-1.30,-.65,0,.65,1.30):
            for z in (.49,1.15,1.81,2.47,3.13):
                if abs(u)<.97 and 1.40<z<3.22:continue
                if abs(u)<.4 and .8<z<1.25:continue
                col=['gold_bottom','gold_lower','gold_middle','gold_upper','gold_top'][min(4,int(z/.76))]
                # Square rings instead of a flat decal: four raised narrow bars.
                for dx,dz,sx,sz in [(-.16,0,.045,.36),(.16,0,.045,.36),(0,-.16,.28,.045),(0,.16,.28,.045)]:
                    box_fast('EmbossedSquare',(u+dx,-1.93,z+dz),(sx,.04,sz),col)
        question_mark()
        for obj in pieces[start:]:obj.matrix_world=transform@obj.matrix_world
    # Studded underside, visible when the block is held or opened.
    for x in (-1.18,0,1.18):
        for y in (-1.18,0,1.18):box_fast('UndersideStud',(x,y,-.027),(.46,.46,.055),'gold_bottom')

def cool_tralalero():
    # Reuse the original character geometry with palette aliases; no base files change.
    for alias,target in {'shark':'water','sneaker':'floor','pink':'gold_lower','ink':'gold_detail','ivory':'white'}.items():MATS[alias]=MATS[target]
    shark(False)
    # The eyes sit on each side of the head. Broad wraparound lenses join over the snout.
    for side in (-1,1):
        cube('SunglassesLens',(side*1.13,-1.53,3.15),(.16,.95,.66),'gold_detail',bevel=.055)
        cube('SunglassesTopRim',(side*1.17,-1.50,3.49),(.18,1.12,.13),'gold_detail',bevel=.025)
        cube('LensGlint',(side*1.222,-1.76,3.31),(.025,.24,.055),'white',rotation=(.18,0,0),bevel=.012)
        bar('GlassesTemple',(side*1.17,-1.02,3.39),(side*1.17,-.35,3.33),.13,.13,'gold_detail',bevel=.02)
        bar('WraparoundGlasses',(side*1.13,-1.98,3.39),(side*.90,-2.16,3.39),.14,.14,'gold_detail',bevel=.02)
    cube('SunglassesBridge',(0,-2.16,3.39),(1.92,.14,.14),'gold_detail',bevel=.02)

models=[];stats={}
for name,builder in [('BrickRockIsland',rock_island),('LuckyBlock',lucky_block),('CoolTralalero',cool_tralalero)]:
    if args.only and args.only!=name:continue
    pieces.clear();builder();obj,tris=join_and_atlas(name)
    if name=='LuckyBlock':lucky_atlas(obj)
    bpy.context.view_layer.update()
    assert tris<=15000,(name,tris)
    stats[name]={'triangles':tris,'vertices':len(obj.data.vertices),'dimensions_xyz':[round(v,3) for v in obj.dimensions],'mesh_objects':1,'material_slots':len(obj.data.materials),'uv_layers':[layer.name for layer in obj.data.uv_layers]}
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
    bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'MESH'},add_leaf_bones=False,path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
    models.append(obj)
# A separate presentation scene; exported meshes retain origin at flat bottom center.
if not args.only:
    models[0].location=(-4,1.2,0);models[1].location=(5.5,1.2,.10);models[2].location=(4,-5.0,.10)
pieces.clear();cube('PreviewGround',(0,0,-.22),(200,200,.35) if args.only else (25,19,.35),'rock_dark' if args.only else 'water',bevel=.1)
bpy.ops.object.camera_add(location=(18,-29,22));camera=bpy.context.object;camera.rotation_euler=(Vector((-.5,-.5,2.1))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=26;bpy.context.scene.camera=camera
if args.only:
    camera.location=(7,-10,7.6);camera.rotation_euler=(Vector((0,0,1.8))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=7.6
for pos,power in [((-7,-10,16),2600),((12,-4,10),1800),((0,9,15),2800)]:
    bpy.ops.object.light_add(type='AREA',location=pos);lamp=bpy.context.object;lamp.data.energy=power;lamp.data.size=8;lamp.rotation_euler=(Vector((0,0,2))-lamp.location).to_track_quat('-Z','Y').to_euler()
bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene;scene.name='BonusProps';scene.render.engine='CYCLES';scene.cycles.samples=32;scene.world.color=(.28,.32,.4)
scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.view_settings.view_transform='Standard';scene.view_settings.look='Medium High Contrast';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'BonusPropsPreview.png')
if args.only:
    scene.name=args.only;scene.render.resolution_x=1200;scene.render.resolution_y=1200;scene.render.filepath=str(OUT/(args.only+'Preview.png'));scene.view_settings.exposure=-.35
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA';area.spaces.active.shading.type='MATERIAL'
image.pack();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/((args.only or 'BonusProps')+'.blend')))
for name,data in stats.items():data['glb_bytes']=(OUT/(name+'.glb')).stat().st_size
(OUT/((args.only+'.stats.json') if args.only else 'bonus-stats.json')).write_text(json.dumps(stats,indent=2));print('BONUS_STATS',json.dumps(stats),flush=True)
bpy.ops.render.render(write_still=True)
