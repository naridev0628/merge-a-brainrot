"""Original Blender brick scenery and Brainrot shopkeeper. Uses the character mesh helpers."""
from pathlib import Path
source=Path(__file__).with_name('build_brainrot_models.py').read_text()
exec(compile(source.split('stats={}; models=[]')[0],str(Path(__file__).with_name('build_brainrot_models.py')),'exec'))
from mathutils import Matrix
OUT=ROOT/'assets'/'map'/'blender'; OUT.mkdir(parents=True,exist_ok=True)
image.filepath_raw=str(OUT/'PropPalette.png'); image.save()

def tree():
    trunk=cube('Trunk',(0,0,3),(2,2,6),'wood_dark',bevel=.04); studs(trunk,('front','side'),spacing=.65)
    for pos,size,color in [((0,0,5.8),(6.4,5.3,3.4),'green'),((-.45,.2,8.7),(4.8,4.3,3.5),'green_light'),((-.75,.35,11.2),(2.7,2.9,1.6),'green')]:
        canopy=cube('SteppedFoliage',pos,size,color,bevel=.05); studs(canopy,('front','top','side'),spacing=.80)

def bush():
    for pos,size in [((0,0,.7),(3.7,2.7,1.4)),((-.4,.3,1.7),(2.6,2,1))]:
        b=cube('BushBrick',pos,size,'green_light',bevel=.06); studs(b,('front','top','side'),spacing=.65)

def log():
    b=cube('FallenLog',(0,0,.65),(3.7,1.25,1.25),'wood',rotation=(0,0,.16),bevel=.035);studs(b,('top','front'),spacing=.6)
    for side in (-1,1):
        cube('CutEnd',(side*1.83,side*.29,.65),(.06,.92,.92),'wood_light',rotation=(0,0,.16),bevel=.015)
        cube('EndRing',(side*1.87,side*.29,.65),(.025,.56,.56),'wood_dark',rotation=(0,0,.16),bevel=.01)
        cube('EndCenter',(side*1.89,side*.29,.65),(.025,.31,.31),'wood_light',rotation=(0,0,.16),bevel=.008)

def flower():
    cube('Stem',(0,0,.65),(.18,.18,1.3),'green',bevel=.01)
    for side in (-1,1): cube('Leaf',(side*.25,0,.48),(.44,.15,.23),'green_light',rotation=(0,side*.35,0),bevel=.015)
    for x,y in [(0,.36),(0,-.36),(.36,0),(-.36,0)]:
        p=cube('Petal',(x,y,1.25),(.45,.45,.16),'pink',bevel=.02); studs(p,('top',),spacing=.4)
    cube('FlowerCenter',(0,0,1.35),(.35,.35,.20),'banana',bevel=.02)

def grass():
    for x,y,h in [(-.4,0,.7),(0,.15,1.1),(.38,-.1,.85),(.15,-.4,.55)]:
        cube('GrassBlade',(x,y,h/2),(.20,.20,h),'green_light',rotation=(0,x*.25,0),bevel=.01)

def bridge():
    for i in range(21):
        plank=cube('BridgePlank',(0,(i-10)*3,.15),(13.6,2.90,.5),'wood' if i%3 else 'wood_light',bevel=.035)
        studs(plank,('top',),spacing=1.55)
        for side in (-1,1): cube('Peg',(side*5.8,(i-10)*3,.43),(.20,.20,.08),'wood_dark',bevel=.012)
    for side in (-1,1):
        cube('BridgeRail',(side*6.8,0,2.7),(.45,64,.45),'wood_light',bevel=.02)
        cube('BridgeRail',(side*6.8,0,1.5),(.38,64,.32),'wood',bevel=.02)
        for y in range(-30,31,10):
            p=cube('BridgePost',(side*6.8,y,1.65),(.8,.8,3.3),'wood_dark',bevel=.03);studs(p,('top',),spacing=.6)

def barn():
    body=cube('RedBarn',(0,0,3.05),(6,5.5,6.1),'pink_dark',bevel=.04);studs(body,('front','side'),spacing=.7)
    for x in (-2.95,2.95): cube('CornerTrim',(x,-2.8,3),(.32,.24,6.1),'ivory',bevel=.02)
    cube('Door',(0,-2.82,1.8),(2.6,.18,3.6),'wood_dark',bevel=.02)
    for x in (-1.45,1.45): cube('DoorFrame',(x,-2.96,1.92),(.26,.24,3.84),'ivory',bevel=.02)
    cube('DoorHeader',(0,-2.96,3.83),(3.15,.24,.28),'ivory',bevel=.02)
    for side in (-1,1):
        beam=cube('DoorCross',(0,-3.0,1.8),(.19,.15,3.9),'ivory',rotation=(0,side*.60,0),bevel=.01)
    for step in range(4):
        width=7.0-step*1.35
        roof=cube('SteppedRoof',(0,0,6.3+step*.55),(width,6.4,.55),'sneaker',bevel=.035);studs(roof,('top',),spacing=.75)
        for y in (-3.24,3.24): cube('RoofTrim',(0,y,6.3+step*.55),(width,.22,.32),'ivory',bevel=.02)

def lily():
    # A stepped leaf with an open notch, built from individual brick strips.
    for y,width in [(-1.1,1.5),(-.55,2.6),(0,3.0),(.55,2.6),(1.1,1.5)]:
        if y<0:
            for side in (-1,1):
                leaf=cube('NotchedLeaf',(side*(width/4+.16),y,.10),(width/2-.32,.55,.20),'green_light',bevel=.025);studs(leaf,('top',),spacing=.48)
        else:
            leaf=cube('LilyLeaf',(0,y,.10),(width,.55,.20),'green_light',bevel=.025);studs(leaf,('top',),spacing=.48)
    cube('LeafVein',(0,.45,.23),(.12,1.2,.05),'green',bevel=.01)

def keeper():
    for side in (-1,1):
        cube('OverallLeg',(side*.61,0,1.14),(1.03,1.14,1.8),'sneaker',bevel=.04)
        cube('Boot',(side*.61,-.27,.28),(1.12,1.68,.55),'wood_dark',bevel=.05)
        arm=cube('ShirtSleeve',(side*1.73,0,3.95),(.97,1.27,1.35),'pink',bevel=.05);studs(arm,('front','side'),spacing=.42)
        cube('Hand',(side*1.73,-.02,2.87),(.91,1.14,.92),'ivory',bevel=.05)
    shirt=cube('Shirt',(0,0,3.52),(2.5,1.45,2.5),'green_light',bevel=.05);studs(shirt,('side',),spacing=.5)
    cube('OverallsBib',(0,-.765,3.43),(2.1,.14,1.84),'sneaker',bevel=.025)
    for side in (-1,1):
        cube('OverallStrap',(side*.76,-.78,4.38),(.30,.18,1.0),'sneaker',bevel=.02)
        cube('Button',(side*.76,-.89,4.03),(.19,.08,.19),'banana',bevel=.02)
    # Tong Tong face stitched onto the front pocket.
    cube('BrainrotPocket',(0,-.87,3.22),(.97,.08,1.05),'wood_light',bevel=.02)
    for side in (-1,1):
        cube('PocketEye',(side*.23,-.93,3.42),(.23,.04,.22),'white',bevel=0)
        cube('PocketPupil',(side*.23,-.96,3.41),(.10,.02,.12),'ink',bevel=0)
    cube('PocketSmile',(0,-.94,2.98),(.40,.04,.07),'wood_dark',bevel=.01)
    head=cube('GoofyHead',(0,0,5.77),(2.12,1.75,2.05),'ivory',bevel=.10);studs(head,('side',),spacing=.45)
    for side in (-1,1):
        cube('Ear',(side*1.15,0,5.65),(.25,.55,.52),'ivory',bevel=.05)
        cube('EyeWhite',(side*.49,-.91,5.98),(.57,.08,.55 if side<0 else .43),'white',bevel=.035)
        cube('Pupil',(side*.49+side*.05,-.97,6.02),(.18,.05,.22),'ink',bevel=.015)
        cube('Brow',(side*.49,-.94,6.44),(.66,.09,.09),'wood_dark',rotation=(0,side*.18,0),bevel=.015)
        cube('Cheek',(side*.78,-.91,5.48),(.34,.07,.20),'pink',bevel=.035)
    cube('Nose',(0,-1.00,5.72),(.33,.31,.30),'ivory',bevel=.08)
    cube('SillyGrin',(0,-.93,5.25),(1.07,.12,.42),'ink',bevel=.05)
    cube('BuckTooth',(-.18,-1.01,5.37),(.32,.06,.25),'white',bevel=.015)
    cube('Tongue',(.23,-1.02,5.11),(.34,.07,.24),'pink',bevel=.04)
    brim=cube('StrawBrim',(0,0,6.90),(3.7,2.75,.22),'banana',bevel=.05);studs(brim,('top',),spacing=.50)
    hat=cube('StrawHat',(0,.08,7.35),(2.35,1.83,.76),'banana',bevel=.055);studs(hat,('front','top','side'),spacing=.38)
    cube('HatBand',(0,-.86,7.09),(2.36,.08,.22),'pink',bevel=.01)
    for side in (-1,1):
        for y in (-.36,.39):
            before=len(pieces);tung(True);bpy.context.view_layer.update()
            matrix=Matrix.Translation((side*1.73,y,4.70))@Matrix.Scale(.16,4)
            for obj in pieces[before:]: obj.matrix_world=matrix@obj.matrix_world

models=[];stats={}
for name,builder in [('BrickTree',tree),('BrickBush',bush),('BrickLog',log),('BrickFlower',flower),('BrickGrass',grass),('BrickBridge',bridge),('Shopkeeper',keeper),('BrickBarn',barn),('BrickLilyPad',lily)]:
    pieces.clear();builder();obj,tris=join_and_atlas(name);stats[name]={'triangles':tris};bpy.context.scene.name=name
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
    models.append(obj)
for obj,pos in zip(models,[(-9,2,0),(-7,-5,0),(-3,-5,0),(0,-5,0),(2,-5,0),(0,20,-.4),(5,-2,0),(10,8,0),(4,-6,0)]): obj.location=pos
models[5].scale=(.35,.35,.35)
pieces.clear();cube('Display',(0,0,-.3),(27,15,.5),'floor',bevel=.1)
bpy.ops.object.camera_add(location=(17,-33,25));camera=bpy.context.object;camera.rotation_euler=(Vector((0,5,4))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=44;bpy.context.scene.camera=camera
for pos,power in [((-6,-7,15),2200),((10,-3,12),1800),((0,8,15),2200)]:
    bpy.ops.object.light_add(type='AREA',location=pos);lamp=bpy.context.object;lamp.data.energy=power;lamp.data.size=8;lamp.rotation_euler=(Vector((0,0,3))-lamp.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.world.color=(.22,.26,.31);scene.render.resolution_x=1600;scene.render.resolution_y=900;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.filepath=str(OUT/'MapPropsPreview.png')
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D': area.spaces.active.region_3d.view_perspective='CAMERA';area.spaces.active.shading.type='MATERIAL'
image.pack();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'BrainrotMapKit.blend'));(OUT/'mesh-stats.json').write_text(json.dumps(stats,indent=2));print('PROP_STATS',json.dumps(stats),flush=True);bpy.ops.render.render(write_still=True)
