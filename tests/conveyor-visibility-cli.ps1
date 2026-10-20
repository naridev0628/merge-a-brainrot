$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$runtime = @'
-- Isolated numeric stand-ins execute the actual controller and fake-model
-- fixture without Studio. CFrame position math is exact; rotation interpolation
-- is linear here, so this is not a visual/orientation rendering assertion.
local vectorMT={}
local Vector3={}
function Vector3.new(x,y,z) return setmetatable({X=x,Y=y,Z=z},vectorMT) end
Vector3.zero=Vector3.new(0,0,0)
vectorMT.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectorMT.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectorMT.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vectorMT.__eq=function(a,b) return a.X==b.X and a.Y==b.Y and a.Z==b.Z end
vectorMT.__index=function(v,key)
    if key=='Magnitude' then return math.sqrt(v.X^2+v.Y^2+v.Z^2) end
    if key=='Lerp' then return function(a,b,t) return a+(b-a)*t end end
end
local function matrix(a,b)
    local result={}
    for row=0,2 do for col=0,2 do
        local sum=0
        for n=0,2 do sum+=a[row*3+n+1]*b[n*3+col+1] end
        result[row*3+col+1]=sum
    end end
    return result
end
local function transform(r,v)
    return Vector3.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z,r[4]*v.X+r[5]*v.Y+r[6]*v.Z,r[7]*v.X+r[8]*v.Y+r[9]*v.Z)
end
local identity={1,0,0,0,1,0,0,0,1}
local cfMT={}
local function cf(p,r) return setmetatable({Position=p,r=r},cfMT) end
local CFrame={}
function CFrame.new(x,y,z) return cf(if type(x)=='table' then x else Vector3.new(x or 0,y or 0,z or 0),identity) end
function CFrame.Angles(x,y,z)
    local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return cf(Vector3.zero,matrix(matrix({1,0,0,0,cx,-sx,0,sx,cx},{cy,0,sy,0,1,0,-sy,0,cy}),{cz,-sz,0,sz,cz,0,0,0,1}))
end
CFrame.identity=CFrame.new()
cfMT.__mul=function(a,b) return cf(a.Position+transform(a.r,b.Position),matrix(a.r,b.r)) end
cfMT.__index=function(a,key)
    if key=='Rotation' then return cf(Vector3.zero,a.r) end
    if key=='PointToWorldSpace' then return function(self,p) return self.Position+transform(self.r,p) end end
    if key=='PointToObjectSpace' then return function(self,p)
        local r=self.r
        return transform({r[1],r[4],r[7],r[2],r[5],r[8],r[3],r[6],r[9]},p-self.Position)
    end end
    if key=='Lerp' then return function(self,target,t)
        local r={}
        for index=1,9 do r[index]=self.r[index]+(target.r[index]-self.r[index])*t end
        return cf(self.Position:Lerp(target.Position,t),r)
    end end
end
local modules={
    MiniMotion=require('../src/shared/MiniMotion'),MiniNeighborIndex=require('../src/shared/MiniNeighborIndex'),
    AnimationVisibility=require('../src/shared/AnimationVisibility'),Config=require('../src/shared/Config'),
    TierEffects={new=function() return {update=function() end,destroy=function() end,remove=function() end} end},
}
local shared={WaitForChild=function(_,name) return name end,AnimationVisibility='AnimationVisibility'}
local storage={Shared=shared,WaitForChild=function(_,name) assert(name=='Shared');return shared end}
local collection={tagged={},added={},removed={}}
function collection:GetTagged(name) return self.tagged[name] or {} end
local function signal()
    local s={callbacks={}}
    function s:Connect(callback)
        local connection={Connected=true}
        function connection:Disconnect() self.Connected=false end
        self.callbacks[connection]=callback
        return connection
    end
    function s:emit(model)
        for connection,callback in self.callbacks do if connection.Connected then callback(model) end end
    end
    return s
end
function collection:GetInstanceAddedSignal(name)
    self.added[name]=self.added[name] or signal()
    return self.added[name]
end
function collection:GetInstanceRemovedSignal(name)
    self.removed[name]=self.removed[name] or signal()
    return self.removed[name]
end
local fakeGame={ReplicatedStorage=storage,Players={LocalPlayer={PlayerScripts={Controllers={Conveyor='Conveyor'}}}}}
function fakeGame:GetService(name) return if name=='ReplicatedStorage' then storage else collection end
local environment=setmetatable({
    Vector3=Vector3,Vector2={new=function(x,y) return {X=x,Y=y} end},CFrame=CFrame,game=fakeGame,workspace={},
    script={Parent={WaitForChild=function(_,name) return name end}},
    require=function(name) return assert(modules[name],'Missing fake dependency '..name) end,
},{__index=getfenv()})
local function compile(source)
    local chunk=assert(loadstring(source))
    setfenv(chunk,environment)
    return chunk()
end
'@
$controller = Get-Content -LiteralPath (Join-Path $repo 'src/client/Controllers/Conveyor.luau') -Raw
$fixture = Get-Content -LiteralPath (Join-Path $repo 'tests/studio-conveyor-visibility.client.luau') -Raw
$scriptText = $runtime + "`nmodules.Conveyor=compile([====[`n" + $controller + "`n]====])`nprint(compile([====[`n" + $fixture + "`n]====]))`n"
$idle = Get-Content -LiteralPath (Join-Path $repo 'tests/studio-conveyor-idle.client.luau') -Raw
$scriptText += "`nprint(compile([====[`n" + $idle + "`n]====]))`n"
$scriptText += @'
local plot={Name='Plot1'}
function plot:IsA(name) return name=='Model' end
function plot:GetPivot() return CFrame.new(100,0,0) end
function plot:IsDescendantOf() return true end
local minis={Name='Minis',Parent=plot}
local producers={Name='Producers',Parent=plot}
local function model(parent)
    return {Parent=parent,IsA=function(_,name) return name=='Model' end,
        GetPivot=function() return CFrame.identity end,GetAttribute=function() return nil end}
end
local mini,producer=model(minis),model(producers)
collection.tagged={ConveyorMini={mini},BrainrotProducer={producer}}
local c=modules.Conveyor.new(function() return nil end)
assert(c.groups[plot].count==2 and c.models[mini].group==c.producers[producer].group,'Mini/producer registration must share one plot group')
collection.added.ConveyorMini:emit(mini)
assert(c.groups[plot].count==2,'Repeated registration must not leak plot membership')
collection.removed.ConveyorMini:emit(mini)
assert(c.groups[plot].count==1)
collection.removed.BrainrotProducer:emit(producer)
assert(next(c.groups)==nil,'Removing the last tagged model must release its plot group')
collection.added.ConveyorMini:emit(mini)
assert(c.groups[plot].count==1)
local connections=table.clone(c.connections)
c:destroy();c:destroy()
for _,connection in connections do assert(not connection.Connected) end
assert(next(c.groups)==nil and next(c.models)==nil and next(c.producers)==nil)
collection.added.ConveyorMini:emit(mini)
assert(next(c.groups)==nil,'Destroyed controller must not regain a plot group')
print('PASS shared plot registration, duplicate tags, final-tag release and disconnected controller destruction')
-- Execute the actual slide renderer against authoritative MiniMotion for
-- rotated plots. This catches missing scale/rotation compensation in the client.
local motion,config=modules.MiniMotion,modules.Config
for _,yaw in {0,.7,math.pi} do
    local world=CFrame.new(120,0,-70)*CFrame.Angles(0,yaw,0)
    local scale=config.PlotScale
    local function point(x,y,z) return world:PointToWorldSpace(Vector3.new(x,y,z)*scale) end
    for _,startX in {-45,-5,5,45} do
        local token={startX=startX,startY=25,startZ=config.DisplayZ,x=3,y=1.3,z=config.TrayZ,spawnedAt=10,readyAt=14}
        local attrs={ConveyorStart=point(startX,25,config.DisplayZ),ConveyorDrop=point(startX,motion.beltHeight(startX),config.BeltZ),
            ConveyorCenter=point(0,motion.beltHeight(0),config.BeltZ),ConveyorEnd=point(3,1.3,config.TrayZ),
            SpawnedAt=10,ReadyAt=14,PlotScale=scale,FinalRotation=CFrame.identity,RestingLift=Vector3.zero}
        local visual={Parent=true,pose=CFrame.new(attrs.ConveyorStart)}
        function visual:GetAttribute(key) return attrs[key] end
        function visual:GetPivot() return self.pose end
        function visual:PivotTo(pose) self.pose=pose end
        local controller={models={[visual]={rotation=CFrame.identity,settled=false,landed=false}},producers={}}
        for _,progress in {.23,.33,.495,.66,.76} do
            local now=10+4*progress
            modules.Conveyor.update(controller,now)
            local logical=motion.position(config,token,now)
            assert((visual.pose.Position-point(logical.x,logical.y,logical.z)).Magnitude<1e-7,
                'Rendered curved slide must match pickup geometry on every rotated plot')
        end
    end
end
print('PASS actual curved Conveyor renderer matches authoritative pickup on rotated plots')
'@
$target = Join-Path $repo '.tools/conveyor-visibility-cli.luau'
[System.IO.File]::WriteAllText($target, $scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
