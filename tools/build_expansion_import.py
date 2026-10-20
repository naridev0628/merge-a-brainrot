import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
materials={}
objects=[]
for pack in ['expansion_a','expansion_b']:
 for path in sorted((ROOT/'assets/characters'/pack).glob('*.glb')):
  before=set(bpy.data.objects)
  bpy.ops.import_scene.gltf(filepath=str(path))
  imported=[o for o in bpy.data.objects if o not in before and o.type=='MESH']
  assert len(imported)==1,path
  obj=imported[0];obj.name=path.stem;obj.data.name=path.stem+'Mesh'
  if pack not in materials:materials[pack]=obj.data.materials[0]
  obj.data.materials.clear();obj.data.materials.append(materials[pack])
  index=len(objects);obj.location.x+=(index//2%6)*8;obj.location.y+=(index//12)*10+(3 if path.stem.endswith('_Mini') else 0)
  objects.append(obj)
bpy.ops.object.select_all(action='DESELECT')
for obj in objects:obj.select_set(True)
out=ROOT/'assets/characters/expansion_import';out.mkdir(exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(out/'BrainrotExpansion.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_materials='EXPORT')
print('EXPORTED',len(objects),'character meshes',out/'BrainrotExpansion.glb')
