"""Convert original Blender primitive manifests into matching Roblox prop data."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
lines=['--!strict','-- Generated from assets/map/stall_props/*-layout.json. Rebuild with tools/build_stall_runtime.py.',"local Factory=require(script.Parent.ModelFactory)", 'local data={']
def nums(values):return ','.join(f'{v:.6g}' for v in values)
for key in ('KeyCrate','ShippingCrate','CashStash'):
    manifest=json.loads((ROOT/f'assets/map/stall_props/{key}-layout.json').read_text())
    lines.append(f'{key}={{')
    for part in manifest['parts']:
        values=part['position_roblox']+part['rotation_matrix_roblox']
        lines.append('{'+f"Vector3.new({nums(part['size_roblox'])}),CFrame.new({nums(values)}),Color3.new({nums(part['color_srgb'])}),Enum.PartType.{part['type']}"+'},')
    lines.append('},')
lines+=['}', 'local Decor={}', 'function Decor.place(parent: Instance,key: string,cf: CFrame,scale: number?): Model', "local model=Instance.new('Model');model.Name=key;model.WorldPivot=CFrame.identity", "for _,p in data[key] do Factory.part(model,key..'Detail',p[1],p[2],p[3],p[4]) end", 'model:ScaleTo(scale or 1);model:PivotTo(cf);model.Parent=parent;return model', 'end','return Decor']
(ROOT/'src/shared/StallDecor.luau').write_text('\n'.join(lines)+'\n')
