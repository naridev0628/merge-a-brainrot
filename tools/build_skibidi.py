"""Original brick Skibidi Toilet and lightweight Mini, from the user's visual references."""
from pathlib import Path
source=Path(__file__).with_name('build_brainrot_models.py').read_text()
exec(compile(source.split('stats={}; models=[]')[0],str(Path(__file__).with_name('build_brainrot_models.py')),'exec'))

def skibidi(mini=False):
    for z,size in [(.15,(2.45,2.65,.30)),(.45,(2.1,2.25,.30)),(.95,(1.65,1.9,.8)),(1.45,(2.05,2.35,.35))]:
        body=cube('PorcelainPedestal',(0,0,z),size,'white',bevel=.055);studs(body,('front','side'),spacing=.48,small=mini)
    cube('BowlWater',(0,-.1,1.72),(2.18,2.15,.22),'shark',bevel=.04)
    for side in (-1,1):
        rim=cube('ToiletSeatSide',(side*1.25,-.1,1.85),(.42,2.85,.52),'white',bevel=.075);studs(rim,('top',),spacing=.4,small=mini)
    for y in (-1.37,1.16): cube('ToiletSeatEnd',(0,y,1.85),(2.45,.42,.52),'white',bevel=.075)
    tank=cube('ToiletTank',(0,1.1,3.20),(2.65,.62,2.75),'white',bevel=.06);studs(tank,('side',),spacing=.5,small=mini)
    cube('TankLid',(0,1.1,4.65),(2.9,.83,.28),'white',bevel=.04)
    for x in (-1.19,1.19): cube('RaisedSeat',(x,.68,3.37),(.28,.20,2.75),'ivory',bevel=.035)
    cube('RaisedSeatTop',(0,.68,4.71),(2.62,.20,.28),'ivory',bevel=.035)
    neck=cube('LongNeck',(0,-.05,2.75),(1.32,1.32,2.0),'wood_light',bevel=.05);studs(neck,('front',),spacing=.5,small=mini)
    head=cube('Face',(0,-.12,4.55),(2.24,1.62,2.72),'wood_light',bevel=.12);studs(head,('side',),spacing=.48,small=mini)
    for side in (-1,1):
        cube('Ear',(side*1.22,-.03,4.55),(.35,.66,.76),'wood_light',bevel=.06)
        cube('EarInner',(side*1.39,-.16,4.55),(.06,.3,.41),'wood',bevel=.02)
        cube('EyeWhite',(side*.52,-.98,4.97),(.77,.13,.77),'white',bevel=.11)
        cube('Iris',(side*.52,-1.06,4.98),(.36,.08,.40),'green',bevel=.03)
        cube('Pupil',(side*.52,-1.11,4.98),(.22,.035,.29),'ink',bevel=.015)
        cube('EyeSpark',(side*.52-.07,-1.14,5.08),(.09,.025,.09),'white',bevel=0)
        for segment in (-1,1): cube('RaisedBrow',(side*.52+segment*.20,-.99,5.58),(.5,.13,.16),'ink',rotation=(0,segment*side*.25,0),bevel=.02)
        cube('Cheek',(side*.83,-.99,4.23),(.38,.18,.4),'wood_light',rotation=(0,side*.25,0),bevel=.04)
    cube('NoseBridge',(0,-1.02,4.68),(.28,.3,.75),'wood_light',bevel=.045)
    cube('NoseTip',(0,-1.22,4.41),(.49,.39,.26),'wood_light',bevel=.065)
    cube('WideGrin',(0,-.985,3.95),(1.58,.12,.75),'ink',bevel=.1)
    cube('Tongue',(0,-1.07,3.70),(.67,.07,.18),'pink',bevel=.05)
    for i in range(7):
        cube('TopTooth',((i-3)*.19,-1.075,4.20),(.18,.06,.23),'ivory',bevel=.012)
        cube('BottomTooth',((i-3)*.18,-1.075,3.64),(.17,.06,.15),'ivory',bevel=.01)
    for z,w in [(5.76,2.3),(5.99,1.98),(6.14,1.48)]:
        hair=cube('SteppedHair',(0,-.03,z),(w,1.7,.27),'ink',bevel=.035);studs(hair,('top',),spacing=.48,small=mini)
    for side in (-1,1): cube('Sideburn',(side*1.02,-.6,5.35),(.21,.72,.8),'ink',bevel=.025)
    cube('HairFringe',(-.12,-.96,5.60),(.45,.18,.42),'ink',rotation=(0,.18,0),bevel=.025)

models=[];stats={}
for name,small in [('Skibidi',False),('Skibidi_Mini',True)]:
    pieces.clear();skibidi(small);obj,tris=join_and_atlas(name);stats[name]={'triangles':tris}
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True);models.append(obj)
models[1].location.x=4;models[1].scale=(.42,.42,.42)
bpy.ops.object.camera_add(location=(9,-18,10));camera=bpy.context.object;camera.rotation_euler=(Vector((1,0,3))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=10;bpy.context.scene.camera=camera
for pos,power in [((-6,-7,11),1600),((8,-4,9),1200),((0,7,12),1600)]:
    bpy.ops.object.light_add(type='AREA',location=pos);lamp=bpy.context.object;lamp.data.energy=power;lamp.data.size=6;lamp.rotation_euler=(Vector((0,0,3))-lamp.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.world.color=(.22,.26,.31);scene.render.resolution_x=1200;scene.render.resolution_y=900;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.filepath=str(OUT/'SkibidiPreview.png')
image.pack();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Skibidi.blend'));(OUT/'skibidi-stats.json').write_text(json.dumps(stats,indent=2));print(json.dumps(stats),flush=True);bpy.ops.render.render(write_still=True)
