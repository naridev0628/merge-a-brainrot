"""Reusable low brick nest pedestal, kept within the producer bay's foot clearance."""
from pathlib import Path
import re,random
source=Path(__file__).with_name('build_brainrot_models.py').read_text().split('stats={}; models=[]')[0]
source=source.replace("OUT = ROOT / 'assets' / 'characters' / 'blender'", "OUT = ROOT / 'assets' / 'map' / 'blender'")
source=source.replace("'BrainrotPalette.png'","'BrainrotNestPalette.png'").replace("'BrainrotPalette'","'BrainrotNestPalette'").replace("'BrainrotAtlas'","'BrainrotNestAtlas'")
palette={
 'brown':(.23,.095,.026),'brown_light':(.36,.17,.055),'brown_dark':(.15,.055,.012),'rim':(.43,.22,.065),
 'gold':(.78,.43,.035),'straw':(.98,.66,.10),'straw_light':(1,.82,.24),'straw_dark':(.54,.27,.014),
 'floor':(.075,.16,.12),'green':(.10,.30,.08),'white':(1,1,1),'ink':(.01,.01,.01),
 'unused1':(.8,.7,.2),'unused2':(.8,.7,.2),'unused3':(.8,.7,.2),'unused4':(.8,.7,.2),
}
source=re.sub(r'PALETTE = \{.*?\n\}', 'PALETTE = '+repr(palette),source,count=1,flags=re.S)
exec(compile(source,str(Path(__file__).with_name('build_brainrot_models.py')),'exec'))

def disc(name,radius,z,height,color,sides=40):
    verts=[(radius*math.cos(i*math.tau/sides),radius*math.sin(i*math.tau/sides),level) for level in (z-height/2,z+height/2) for i in range(sides)]
    faces=[tuple(reversed(range(sides))),tuple(range(sides,2*sides))]
    faces += [(i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);obj.data.materials.append(MATS[color]);pieces.append(obj)

pieces.clear()
disc('GoldenNestFloor',2.30,.11,.22,'gold')
# Two interlocked brick courses form a substantial circular rim rather than a flat border.
for course in range(2):
    for i in range(20):
        theta=(i+course*.5)*math.tau/20
        r=2.43
        cube('BrownRingBrick',(r*math.cos(theta),r*math.sin(theta),.095+course*.17),(.72,.47,.17),['brown','brown_light','brown','brown_dark'][(i+course)%4],rotation=(0,0,theta+math.pi/2),bevel=.018)
# Closely spaced shallow square studs give the center a toy-brick floor.
for ix in range(-4,5):
    for iy in range(-4,5):
        x,y=ix*.46,iy*.46
        if x*x+y*y<1.93**2:
            cube('GoldenFloorStud',(x,y,.246),(.18,.18,.052),'straw' if (ix+iy)%3 else 'straw_light',bevel=0)
# Deterministic short angular straw pieces, spread around the inner edge with an open center.
rng=random.Random(121)
for i in range(24):
    theta=i*math.tau/24+rng.uniform(-.05,.05)
    radius=rng.uniform(1.76,2.07)
    length=rng.uniform(.54,.90)
    width=rng.uniform(.14,.22)
    height=rng.uniform(.065,.095)
    top=rng.uniform(.39,.48)
    height=top-.22
    cube('RadialGoldenStraw',(radius*math.cos(theta),radius*math.sin(theta),top-height/2),(length,width,height),['straw','straw_light','straw_dark'][i%3],rotation=(0,0,theta+rng.uniform(-.60,.60)),bevel=.012)
# A few crosspieces make small, readable woven clusters between the radial strands.
for theta in (.25,1.45,2.65,3.85,5.05):
    radius=1.95
    cube('CrosswovenStraw',(radius*math.cos(theta),radius*math.sin(theta),.255),(.55,.12,.07),'straw_light',rotation=(0,0,theta+1.12),bevel=.01)
obj,tris=join_and_atlas('BrainrotNest');bpy.context.view_layer.update()
# The custom disc starts without UVs. Joining primitive cubes can preserve their
# original UVMap alongside the generated atlas layer. Roblox reads the first UV
# set, so retain only the atlas and export it explicitly as TEXCOORD_0.
atlas_uv=obj.data.uv_layers.active
for layer in list(obj.data.uv_layers):
    if layer != atlas_uv:obj.data.uv_layers.remove(layer)
atlas_uv.name='UVMap';obj.data.uv_layers.active_index=0;atlas_uv.active_render=True
low=[min((obj.matrix_world@Vector(v))[i] for v in obj.bound_box) for i in range(3)]
high=[max((obj.matrix_world@Vector(v))[i] for v in obj.bound_box) for i in range(3)]
assert tris<=4000,tris
assert obj.dimensions.x<=5.7 and obj.dimensions.y<=5.7 and high[2]<=.5,(list(obj.dimensions),high)
stats={'BrainrotNest':{'triangles':tris,'vertices':len(obj.data.vertices),'dimensions_xyz':[round(v,4) for v in obj.dimensions],'bounds_min':[round(v,4) for v in low],'bounds_max':[round(v,4) for v in high],'mesh_objects':1,'material_slots':len(obj.data.materials)}}
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
bpy.ops.export_scene.gltf(filepath=str(OUT/'BrainrotNest.glb'),export_format='GLB',use_selection=True,export_apply=True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'BrainrotNestFixed.glb'),export_format='GLB',use_selection=True,export_apply=True)
stats['BrainrotNest']['glb_bytes']=(OUT/'BrainrotNest.glb').stat().st_size
pieces.clear();cube('Display',(0,0,-.10),(8,8,.18),'floor',bevel=.08)
bpy.ops.object.camera_add(location=(7,-9,7));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,.2))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=7.5;bpy.context.scene.camera=camera
for pos,power in [((-3,-4,7),700),((5,-1,5),500),((0,5,7),850)]:
    bpy.ops.object.light_add(type='AREA',location=pos);lamp=bpy.context.object;lamp.data.energy=power;lamp.data.size=5;lamp.rotation_euler=(Vector((0,0,.2))-lamp.location).to_track_quat('-Z','Y').to_euler()
bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene;scene.name='BrainrotNest';scene.render.engine='CYCLES';scene.cycles.samples=32;scene.world.color=(.28,.32,.4);scene.render.resolution_x=1200;scene.render.resolution_y=900;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'BrainrotNestPreview.png')
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA';area.spaces.active.shading.type='MATERIAL'
image.pack();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'BrainrotNest.blend'));(OUT/'BrainrotNest-stats.json').write_text(json.dumps(stats,indent=2));print('NEST_STATS',json.dumps(stats),flush=True);bpy.ops.render.render(write_still=True)
