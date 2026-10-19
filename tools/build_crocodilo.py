"""Original studded Crocodilo bomber, with main and lightweight mini exports.
Run with Blender --background --python tools/build_crocodilo.py.
The existing character builders and atlas are never modified.
"""
from pathlib import Path
import re
source=Path(__file__).with_name('build_brainrot_models.py').read_text().split('stats={}; models=[]')[0]
source=source.replace("'BrainrotPalette.png'","'CrocodiloPalette.png'").replace("'BrainrotPalette'","'CrocodiloPalette'").replace("'BrainrotAtlas'","'CrocodiloAtlas'")
palette={
 'olive':(.22,.29,.065),'olive_light':(.33,.40,.11),'olive_dark':(.10,.16,.025),'jaw':(.43,.45,.21),
 'charcoal':(.028,.038,.045),'panel':(.065,.082,.087),'ink':(.006,.01,.012),'yellow':(1,.66,.015),
 'ivory':(1,.95,.77),'white':(1,1,1),'mouth':(.12,.045,.025),'eye':(.91,.67,.12),
 'metal':(.25,.30,.31),'glass':(.10,.36,.44),'glint':(.6,.85,.91),'floor':(.09,.15,.16),
}
source=re.sub(r'PALETTE = \{.*?\n\}', 'PALETTE = '+repr(palette),source,count=1,flags=re.S)
exec(compile(source,str(Path(__file__).with_name('build_brainrot_models.py')),'exec'))

def tooth(name,x,y,z,size=.13):
    # Four-sided tapered voxel tooth, sharper than a rectangular decal.
    w=size;depth=size*.9;height=size*1.8
    verts=[(x-w/2,y-depth/2,z),(x+w/2,y-depth/2,z),(x+w/2,y+depth/2,z),(x-w/2,y+depth/2,z),(x,y,z-height)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],[(0,3,2,1),(0,1,4),(1,2,4),(2,3,4),(3,0,4)]);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);obj.data.materials.append(MATS['ivory']);pieces.append(obj)

def crocodilo(mini=False):
    # Forward is -Y, the same orientation as Tralalero and the existing shop roster.
    body=cube('ArmoredFuselage',(0,.65,2.45),(1.22,3.40,.95),'charcoal',bevel=.11)
    studs(body,('top','side'),spacing=.46,small=mini)
    cube('Belly',(0,.58,1.99),(1.03,2.90,.31),'panel',bevel=.06)
    cube('RearFuselage',(0,2.30,2.54),(.70,1.15,.66),'charcoal',bevel=.07)
    # Main wings taper in three deliberate brick steps, within a six-unit bay.
    for side in (-1,1):
        for x,y,width,depth in [(1.23,.28,1.37,1.65),(2.29,.53,.85,1.35),(2.82,.76,.45,1.03)]:
            wing=cube('SteppedBomberWing',(side*x,y,2.57),(width,depth,.24),'charcoal',bevel=.035)
            studs(wing,('top',),spacing=.39,small=mini)
        for x,y,depth in [(2.42,.53,1.35),(2.67,.65,1.18)]:
            cube('YellowWingStripe',(side*x,y,2.705),(.12,depth,.025),'yellow',bevel=.004)
        cube('WingTip',(side*3.015,.76,2.60),(.07,.83,.22),'yellow',bevel=.015)
        # Twin chunky engine nacelles with dark inset air intakes and cross propellers.
        engine=cube('TwinEngine',(side*1.72,-.18,2.43),(.70,1.62,.70),'panel',bevel=.075)
        studs(engine,('top','side'),spacing=.36,small=mini)
        cube('EngineCowling',(side*1.72,-1.02,2.43),(.77,.18,.77),'charcoal',bevel=.07)
        cube('EngineIntake',(side*1.72,-1.126,2.43),(.51,.04,.51),'ink',bevel=.035)
        for rotation in (.37,.37+math.pi/2):
            cube('PropellerBlade',(side*1.72,-1.22,2.43),(.11,.09,1.17),'charcoal',rotation=(0,rotation,0),bevel=.018)
        cube('PropellerHub',(side*1.72,-1.29,2.43),(.22,.16,.22),'yellow',bevel=.035)
        # Yellow exhaust trim plus panel rivets are omitted in the miniature.
        if not mini:
            for dy in (.08,.37):cube('EngineExhaust',(side*2.09,dy,2.37),(.10,.14,.20),'metal',bevel=.02)
            for dy in (-.58,.0,.54):cube('WingPanelRivet',(side*1.15,dy,2.73),(.09,.09,.025),'metal',bevel=.008)
    # Low cockpit melts into the crocodile brow, keeping the animal/plane fusion clear.
    cube('Cockpit',(0,-.62,3.04),(.84,.80,.28),'olive_dark',bevel=.07)
    cube('CockpitGlass',(0,-.66,3.20),(.63,.56,.12),'glass',bevel=.035)
    if not mini:
        cube('CockpitFrame',(0,-.66,3.27),(.065,.61,.04),'charcoal',bevel=.006)
        cube('GlassReflection',(-.16,-.68,3.27),(.20,.24,.018),'glint',bevel=.008)
    # Broad low crocodile snout: olive upper jaw, cream lower jaw, continuous dark mouth.
    skull=cube('CrocodileSkull',(0,-1.40,2.85),(1.67,1.42,.88),'olive',bevel=.085)
    snout=cube('LongCrocodileSnout',(0,-2.39,2.65),(1.49,1.58,.51),'olive_light',bevel=.065)
    studs(skull,('top','side'),spacing=.34,small=mini)
    studs(snout,('top',),spacing=.32,small=mini)
    cube('MouthShadow',(0,-2.15,2.30),(1.52,2.02,.20),'mouth',bevel=.025)
    cube('LowerJaw',(0,-2.11,2.13),(1.48,2.10,.24),'jaw',bevel=.06)
    cube('Chin',(0,-2.86,2.16),(1.20,.51,.25),'olive',bevel=.035)
    for side in (-1,1):
        cube('Nostril',(side*.44,-3.184,2.74),(.20,.035,.10),'ink',bevel=.012)
        cube('NoseRidge',(side*.44,-2.96,2.96),(.27,.30,.09),'olive_dark',bevel=.015)
        # Side eyes and a raised eyebrow give the long nose an expressive animal face.
        cube('EyeBump',(side*.72,-1.50,3.30),(.38,.57,.31),'olive_light',bevel=.055)
        cube('GoldCrocodileEye',(side*.927,-1.57,3.30),(.055,.35,.25),'eye',bevel=.025)
        cube('SlitPupil',(side*.961,-1.60,3.30),(.025,.065,.23),'ink',bevel=.008)
        if not mini:cube('EyeGlint',(side*.977,-1.65,3.37),(.014,.06,.055),'white',bevel=.004)
        cube('HeavyBrow',(side*.83,-1.52,3.48),(.33,.64,.10),'olive_dark',bevel=.025)
        for i in range(4 if mini else 7):
            y=-2.99+i*(.45 if mini else .27)
            tooth('CrocodileFang',side*.73,y,2.47,.14 if i%2 else .17)
    for x in (-.45,0,.45):tooth('FrontFang',x,-3.15,2.46,.13)
    if not mini:
        # Layered brow scales and cheek dimples break up the snout without noise.
        for side in (-1,1):
            for y in (-2.68,-2.21,-1.99):cube('CheekScale',(side*.776,y,2.68),(.045,.22,.16),'olive',bevel=.012)
        for y in (-1.7,-1.31,-.96):cube('CrocBackPlate',(0,y,3.35),(.22,.25,.11),'olive_dark',bevel=.018)
    # Cross-shaped tail empennage, two yellow stripes, and an olive crocodile tail tip.
    for side in (-1,1):
        fin=cube('Tailplane',(side*.76,2.45,2.71),(1.12,.72,.18),'charcoal',bevel=.025)
        studs(fin,('top',),spacing=.34,small=mini)
        cube('TailStripe',(side*.94,2.45,2.81),(.15,.69,.025),'yellow',bevel=.006)
    for y,z,length,height in [(2.36,3.08,.91,.61),(2.54,3.49,.57,.40)]:
        tailfin=cube('VerticalTailFin',(0,y,z),(.19,length,height),'charcoal',bevel=.025)
        studs(tailfin,('side',),spacing=.31,small=mini)
    cube('FinYellowFlash',(.108,2.55,3.52),(.025,.40,.11),'yellow',bevel=.005)
    cube('FinYellowFlash',(-.108,2.55,3.52),(.025,.40,.11),'yellow',bevel=.005)
    cube('TailCrocTip',(0,2.99,2.52),(.38,.49,.29),'olive_dark',bevel=.035)
    # Landing gear gives a grounded silhouette at the exact local base plane.
    for side in (-1,1):
        bar('LandingStrut',(side*.57,.16,2.03),(side*.81,-.03,.43),.16,.18,'metal',bevel=.015)
        cube('LandingWheel',(side*.81,-.03,.34),(.25,.65,.68),'ink',bevel=.08)
        cube('WheelHub',(side*.955,-.03,.34),(.055,.28,.28),'yellow',bevel=.04)
    bar('TailGear',(0,2.06,2.01),(0,2.16,.35),.12,.13,'metal',bevel=.01)
    cube('TailWheel',(0,2.16,.25),(.20,.46,.50),'ink',bevel=.065)

stats={};models=[]
for mini in (False,True):
    pieces.clear();crocodilo(mini);name='Crocodilo_Mini' if mini else 'Crocodilo'
    obj,tris=join_and_atlas(name);bpy.context.view_layer.update()
    assert obj.dimensions.x<=6.2 and obj.dimensions.z<=6.2
    assert tris<15000,(name,tris)
    stats[name]={'triangles':tris,'vertices':len(obj.data.vertices),'dimensions_xyz':[round(v,3) for v in obj.dimensions],'mesh_objects':1,'material_slots':len(obj.data.materials)}
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
    stats[name]['glb_bytes']=(OUT/(name+'.glb')).stat().st_size
    models.append(obj)
models[0].location=(-1,0,0);models[1].location=(3.3,-3.1,0);models[1].scale=(.40,)*3
pieces.clear();cube('Display',(0,0,-.18),(13,11,.32),'floor',bevel=.12)
bpy.ops.object.camera_add(location=(11,-16,10));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,1.7))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=13;bpy.context.scene.camera=camera
for pos,power in [((-5,-7,11),1500),((7,-2,8),1300),((0,7,10),1800)]:
    bpy.ops.object.light_add(type='AREA',location=pos);lamp=bpy.context.object;lamp.data.energy=power;lamp.data.size=6;lamp.rotation_euler=(Vector((0,0,2))-lamp.location).to_track_quat('-Z','Y').to_euler()
bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene;scene.name='Crocodilo';scene.render.engine='CYCLES';scene.cycles.samples=32;scene.world.color=(.28,.32,.4);scene.render.resolution_x=1600;scene.render.resolution_y=1100;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'CrocodiloPreview.png')
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA';area.spaces.active.shading.type='MATERIAL'
image.pack();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Crocodilo.blend'));(OUT/'Crocodilo-stats.json').write_text(json.dumps(stats,indent=2));print('CROCODILO_STATS',json.dumps(stats),flush=True);bpy.ops.render.render(write_still=True)
