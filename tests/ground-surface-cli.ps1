$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
# Reuse the numeric rigid-transform stand-in used by the real carry-pose harness.
$pose=[System.IO.File]::ReadAllText((Join-Path $repo 'tests/lucky-carry-pose-cli.ps1'))
$match=[regex]::Match($pose,'(?s)\$runtime=@''\r?\n(.*?)\r?\n''@')
if(-not $match.Success){throw 'Numeric CFrame runtime block not found'}
$runtime=$match.Groups[1].Value
$standins=@'
local vectorMt={__unm=function(v) return Vector3.new(-v.X,-v.Y,-v.Z) end}
Vector3.new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vectorMt) end
Vector3.zero=Vector3.new(0,0,0);Vector3.xAxis=Vector3.new(1,0,0);Vector3.yAxis=Vector3.new(0,1,0);Vector3.zAxis=Vector3.new(0,0,1)
CFrame.fromMatrix=function(p,x,y,z) return make({p.X,p.Y,p.Z},{x.X,y.X,z.X,x.Y,y.Y,z.Y,x.Z,y.Z,z.Z}) end
local Color3={new=function(r,g,b) return {R=r,G=g,B=b} end,fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end}
local Enum={SurfaceType={Smooth='Smooth',Studs='Studs'},Material={Plastic='Plastic'}}
local objects={}
local Instance={}
function Instance.new(class)
 local item={ClassName=class,Name=class,attributes={},Size=Vector3.new(1,1,1),CFrame=CFrame.identity}
 function item:IsA(kind) return kind==self.ClassName or kind=='BasePart' and (self.ClassName=='Part' or self.ClassName=='MeshPart' or self.ClassName=='WedgePart') end
 function item:FindFirstChild(name) for _,obj in objects do if obj.Parent==self and obj.Name==name then return obj end end end
 function item:SetAttribute(key,value) self.attributes[key]=value end
 function item:GetAttribute(key) return self.attributes[key] end
 function item:Destroy() for _,obj in table.clone(objects) do if obj.Parent==self then obj:Destroy() end end;self.Parent=nil;self.destroyed=true end
 function item:Clone() local clone=Instance.new(self.ClassName);clone.Size=self.Size;return clone end
 table.insert(objects,item);return item
end
local replicated=Instance.new('Folder')
local templates=Instance.new('Folder');templates.Name='MapModels';templates.Parent=replicated
for _,key in {'GroundGreenTile','GroundGreenTriangle','GroundGoldTile','GroundGoldTriangle','GroundBrownTile','GroundBrownTriangle','GroundGreenEdge'} do
 local t=Instance.new('MeshPart');t.Name=key;t.Parent=templates
end
local game={GetService=function() return replicated end}
'@
$source=[System.IO.File]::ReadAllText((Join-Path $repo 'src/shared/GroundSurface.luau'))
$test=@'
local root=Instance.new('Model')
local floor=Instance.new('Part');floor.Parent=root;floor.Size=Vector3.new(108,1,82);floor.CFrame=CFrame.new(0,-.5,3);floor.CanCollide=true
local cover=Surface.cover(floor,'Green')
assert(cover:GetAttribute('TileCount')==42 and not cover:GetAttribute('MissingTemplate'))
assert(floor.CanCollide and floor.Size.Y==1 and floor.CFrame.Position.Y==-.5,'Never change floor collision/height')
for _,p in objects do if p.Parent==cover then
 assert(p.ClassName=='MeshPart' and not p.CanCollide and not p.CanQuery and not p.CanTouch and p.Anchored)
 assert(math.abs(p.CFrame.Position.Y-.10)<1e-7 and p.Size.Y==.16,'Inset bottom stays above the original floor')
 assert(math.abs(p.CFrame.Position.X)+p.Size.X/2<=54+1e-6)
 assert(math.abs(p.CFrame.Position.Z-3)+p.Size.Z/2<=41+1e-6)
end end
local minGreen,maxGreen=1,0
for _,p in objects do if p.Parent==cover then minGreen=math.min(minGreen,p.Color.R);maxGreen=math.max(maxGreen,p.Color.R) end end
assert(maxGreen-minGreen>.01 and maxGreen-minGreen<.06,'Broad grass patches must retain subtle, bounded variation')
local replacement=Surface.cover(floor,'Green');assert(cover.destroyed and replacement:GetAttribute('TileCount')==42,'Repeat integration replaces the old cover')
local board=Surface.panel(root,CFrame.new(0,-2,-.52),19.8,18.8,'Brown')
assert(board:GetAttribute('TileCount')==4)
for _,p in objects do if p.Parent==board then
 local normal=p.CFrame:VectorToWorldSpace(Vector3.yAxis)
 assert(normal.Z<-.999 and math.abs(p.CFrame.Position.Z+.62)<1e-6,'Board relief must face local -Z and stay inside label clearance')
end end
local sides=Surface.sides(floor,6,{Front=true,Left=true,Right=true})
assert(sides:GetAttribute('TileCount')==19 and sides:FindFirstChild('IslandDepth').Size.Y==6)
local hub=Surface.octagon(root,CFrame.identity,96,'Gold')
assert(hub:GetAttribute('TileCount')==145,'Octagon tessellation must stay bounded')
local triangles=0;local area=0
for _,p in objects do if p.Parent==hub then
 local triangle=p.Name:find('Triangle')~=nil
 if triangle then triangles+=1 end
 area+=p.Size.X*p.Size.Z*(if triangle then .5 else 1)
end end
assert(triangles==16 and math.abs(area-8*(math.sqrt(2)-1)*96^2)<1e-6,'Corners must close exact octagonal area without rectangular overhang')
templates.Parent=nil
local fallback=Surface.panel(root,CFrame.identity,19.8,18.8,'Brown')
assert(fallback:GetAttribute('MissingTemplate') and fallback:GetAttribute('TileCount')==4,'Missing imports use bounded fallback parts')
print('PASS actual GroundSurface: 42-tile widened plot, exact floor bounds/height/collision, replacement, board orientation, 19 side tiles, 145-tile closed octagon, bounded import fallback')
'@
$target=Join-Path $repo '.tools/ground-surface-cli.luau'
[System.IO.File]::WriteAllText($target,$runtime+"`n"+$standins+"`nlocal Surface=(function()`n"+$source+"`nend)()`n"+$test)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
