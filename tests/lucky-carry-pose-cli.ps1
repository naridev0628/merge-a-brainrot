$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$runtime=@'
local Players={GetPlayers=function() return {} end}
local Enum={HumanoidRigType={R6='R6',R15='R15'}}
local game={GetService=function(_,name) return if name=='Players' then Players else {} end}
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local CFrame={}
local mt={}
local function make(p,r) return setmetatable({p=p,r=r},mt) end
local ident={1,0,0,0,1,0,0,0,1}
function CFrame.new(x,y,z)
 if type(x)=='table' then return make({x.X,x.Y,x.Z},table.clone(ident)) end
 return make({x or 0,y or 0,z or 0},table.clone(ident))
end
mt.__mul=function(a,b)
 local r={};local p={}
 for i=0,2 do
  p[i+1]=a.p[i+1]
  for k=0,2 do p[i+1]+=a.r[i*3+k+1]*b.p[k+1] end
  for j=0,2 do
   local v=0;for k=0,2 do v+=a.r[i*3+k+1]*b.r[k*3+j+1] end;r[i*3+j+1]=v
  end
 end
 return make(p,r)
end
function CFrame.Angles(x,y,z)
 local sx,cx=math.sin(x),math.cos(x);local sy,cy=math.sin(y),math.cos(y);local sz,cz=math.sin(z),math.cos(z)
 return make({0,0,0},{1,0,0,0,cx,-sx,0,sx,cx})*make({0,0,0},{cy,0,sy,0,1,0,-sy,0,cy})*make({0,0,0},{cz,-sz,0,sz,cz,0,0,0,1})
end
local methods={}
function methods.Inverse(a)
 local r={};for i=0,2 do for j=0,2 do r[i*3+j+1]=a.r[j*3+i+1] end end
 local p={};for i=0,2 do p[i+1]=0;for j=0,2 do p[i+1]-=r[i*3+j+1]*a.p[j+1] end end
 return make(p,r)
end
function methods.VectorToWorldSpace(a,v)
 return Vector3.new(a.r[1]*v.X+a.r[2]*v.Y+a.r[3]*v.Z,a.r[4]*v.X+a.r[5]*v.Y+a.r[6]*v.Z,a.r[7]*v.X+a.r[8]*v.Y+a.r[9]*v.Z)
end
mt.__index=function(a,key)
 if key=='Rotation' then return make({0,0,0},table.clone(a.r)) end
 if key=='Position' then return Vector3.new(table.unpack(a.p)) end
 return methods[key]
end
CFrame.identity=CFrame.new()
local function same(a,b)
 for i=1,3 do assert(math.abs(a.p[i]-b.p[i])<1e-8,'Joint pivot moved') end
 for i=1,9 do assert(math.abs(a.r[i]-b.r[i])<1e-8,'Joint baseline drifted') end
end
'@
$source=[System.IO.File]::ReadAllText((Join-Path $repo 'src/client/Controllers/LuckyCarryPose.luau'))
$test=@'
for _,spec in {{'R6','Motor6D'},{'R15','Motor6D'},{'R15','AnimationConstraint'}} do
 local rig,class=spec[1],spec[2]
 local joints={}
 for _,side in {-1,1} do
  local base=CFrame.new(side,1,0)*CFrame.Angles(0,if rig=='R6' then side*math.pi/2 else 0,0)
  local joint={Name=if side==1 then 'Right Shoulder' else 'Left Shoulder',baseline=base,Transform=CFrame.identity,Parent=true,IsA=function(_,name) return name==class end}
  if class=='AnimationConstraint' then
   joint.Attachment0={CFrame=base}
   setmetatable(joint,{__index=function(self,key) if key=='C0' then return self.Attachment0.CFrame end end,
    __newindex=function(self,key,value) assert(key~='C0','AnimationConstraint.C0 is read-only');rawset(self,key,value) end})
  else joint.C0=base end
  table.insert(joints,joint)
 end
 local character={held=true,GetDescendants=function() return joints end,FindFirstChild=function(self) return self.held end,
  FindFirstChildOfClass=function() return {RigType=rig} end}
 for i=1,50 do
  local active=Pose.apply(character)
  for _,joint in joints do assert(active[joint],class..' shoulder was skipped') end
  for _,joint in joints do
   local forward=(joint.C0.Rotation*joint.baseline.Rotation:Inverse()):VectorToWorldSpace(Vector3.new(0,-1,0))
   assert(forward.Z<-.90,rig..' hand must lift forward even when Animator overwrites Transform')
   joint.Transform=CFrame.Angles(.05,0,0)
  end
 end
 Pose.release(character)
 for _,joint in joints do same(joint.C0,joint.baseline) end
 character.held=false;assert(next(Pose.apply(character))==nil)
 for _,joint in joints do same(joint.C0,joint.baseline) end
end
print('PASS actual carry pose: R6/R15 Motor6D and R15 AnimationConstraint shoulders are posed, resist animation resets, never drift and restore on release')
'@
$target=Join-Path $repo '.tools/lucky-carry-pose-cli.luau'
[System.IO.File]::WriteAllText($target,$runtime+"`nlocal Pose=(function()`n"+$source+"`nend)()`n"+$test)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
