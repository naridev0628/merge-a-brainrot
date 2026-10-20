$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
# Reuse the established exact Vector3/CFrame arithmetic, not its controller mocks.
$numericSource = Get-Content -LiteralPath (Join-Path $repo 'tests/conveyor-visibility-cli.ps1') -Raw
$start = $numericSource.IndexOf('local vectorMT={}')
$end = $numericSource.IndexOf('local modules={')
if ($start -lt 0 -or $end -le $start) { throw 'Numeric runtime markers changed' }
$numeric = $numericSource.Substring($start, $end - $start)
$runtime = @'
Vector3.xAxis=Vector3.new(1,0,0);Vector3.yAxis=Vector3.new(0,1,0);Vector3.zAxis=Vector3.new(0,0,1)
vectorMT.__unm=function(v) return v*-1 end
function CFrame.fromMatrix(p,right,up,back)
    return cf(p,{right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z})
end
local priorIndex=cfMT.__index
cfMT.__index=function(a,key)
    if key=='RightVector' then return Vector3.new(a.r[1],a.r[4],a.r[7]) end
    if key=='UpVector' then return Vector3.new(a.r[2],a.r[5],a.r[8]) end
    return priorIndex(a,key)
end
local Color3={}
function Color3.new(r,g,b)
    return {R=r,G=g,B=b,Lerp=function(a,c,t)
        return Color3.new(a.R+(c.R-a.R)*t,a.G+(c.G-a.G)*t,a.B+(c.B-a.B)*t)
    end}
end
function Color3.fromRGB(r,g,b) return Color3.new(r/255,g/255,b/255) end
local Enum={Material={Plastic='Plastic'},SurfaceType={Smooth='Smooth',Studs='Studs'},PartType={Block='Block'}}
local Instance={}
function Instance.new(class)
    local object={ClassName=class,children={},CanQuery=true,Transparency=0,
        TopSurface='Smooth',BottomSurface='Smooth',RightSurface='Smooth',LeftSurface='Smooth',FrontSurface='Smooth',BackSurface='Smooth'}
    function object:SetAttribute(k,v) self[k]=v end
    function object:ScaleTo(scale) assert(scale==1,'Octagon scale must remain one') end
    function object:PivotTo(pivot)
        for _,part in self.children do part.CFrame=pivot*part.CFrame end
    end
    return setmetatable(object,{__newindex=function(self,key,value)
        rawset(self,key,value)
        if key=='Parent' then table.insert(value.children,self) end
    end})
end
local environment=setmetatable({Vector3=Vector3,CFrame=CFrame,Color3=Color3,Enum=Enum,Instance=Instance,
    script={Parent={BrickStudOcclusion='BrickStudOcclusion'}},task={wait=function() end},
    require=function(name) assert(name=='BrickStudOcclusion');return {} end},{__index=getfenv()})
local function compile(source)
    local chunk=assert(loadstring(source));setfenv(chunk,environment);return chunk()
end
local Occlusion=require('../src/shared/HubStudOcclusion')
local covers={{kind='circle',x=0,z=0,radius=34,bottom=0,top=.3}}
for sector=0,5 do
    local angle=sector*math.pi/3
    table.insert(covers,{kind='box',x=math.sin(angle)*65,z=math.cos(angle)*65,halfX=7,halfZ=31,
        rightX=math.cos(angle),rightZ=-math.sin(angle),bottom=-.02,top=.18})
end
local function skip(x,z,width,bottom,top)
    return Occlusion.isFullyCovered(x,z,width,bottom,top,covers)
end
local function signature(part)
    local values={part.ClassName,part.Name,tostring(part.Anchored),tostring(part.CanCollide),
        tostring(part.CanQuery),tostring(part.CanTouch),tostring(part.Transparency),part.Material}
    for _,n in {part.Size.X,part.Size.Y,part.Size.Z,part.CFrame.Position.X,part.CFrame.Position.Y,
        part.CFrame.Position.Z,part.Color.R,part.Color.G,part.Color.B} do table.insert(values,string.format('%.9f',n)) end
    for _,n in part.CFrame.r do table.insert(values,string.format('%.9f',n)) end
    return table.concat(values,':')
end
'@
$source = Get-Content -LiteralPath (Join-Path $repo 'src/shared/EnvironmentArt.luau') -Raw
$scriptText = $numeric + "`n" + $runtime + "`nlocal Environment=compile([====[`n" + $source + "`n]====])`n"
$scriptText += @'
local parent=Instance.new('Folder')
local color=Color3.fromRGB(115,210,38)
local baseline=Environment.octagon(parent,CFrame.identity,96,1,color,skip)
assert(#baseline.children==1489,'Historical raised mode must retain 1480 studs and nine slabs')
local legacy={}
for _,part in baseline.children do
    if part.Name~='SquareStud' then
        assert(part.TopSurface=='Smooth' and part.RightSurface=='Smooth','Default surface semantics changed')
        legacy[signature(part)]=true
    else assert(not part.CanCollide and not part.CanQuery and not part.CanTouch,'Legacy ornaments became interactive') end
end
local candidate=Environment.octagon(parent,CFrame.identity,96,1,color,nil,true)
assert(#candidate.children==9,'Native hub must contain exactly nine slabs and zero physical studs')
local rectangles,wedges=0,0
for _,part in candidate.children do
    assert(legacy[signature(part)],'Native mode changed original slab geometry/color/material/physics: '..part.Name)
    legacy[signature(part)]=nil
    if part.ClassName=='WedgePart' then
        wedges+=1
        assert(part.RightSurface=='Studs' and part.TopSurface=='Smooth','Only the upward wedge face receives native studs')
        assert((part.CFrame.RightVector-Vector3.yAxis).Magnitude<1e-8,'Studded wedge face must point up')
    else
        rectangles+=1
        assert(part.TopSurface=='Studs' and part.RightSurface=='Smooth','Only rectangular tops receive native studs')
        assert((part.CFrame.UpVector-Vector3.yAxis).Magnitude<1e-8)
    end
    for _,face in {'BottomSurface','FrontSurface','BackSurface','LeftSurface'} do
        assert(part[face]=='Smooth','Native mode changed a side/bottom surface')
    end
end
assert(next(legacy)==nil and rectangles==5 and wedges==4,'Native mode must preserve every original slab')
local called=0
Environment.octagon(parent,CFrame.identity,96,1,color,function() called+=1;return false end,true)
assert(called==0,'Native mode must not enumerate unused physical-stud candidates')
local unculled=Environment.octagon(parent,CFrame.identity,96,1,color)
assert(#unculled.children==2046,'Default callers must retain all 2037 physical studs')
for _,spec in {{8,.5},{23,2.5}} do
    local pivot=CFrame.new(8,7,-11)*CFrame.Angles(0,.73,0)
    local callsA,callsB=0,0
    local a=Environment.octagon(parent,pivot,spec[1],spec[2],color,function(x) callsA+=1;return x<0 end)
    local b=Environment.octagon(parent,pivot,spec[1],spec[2],color,function(x) callsB+=1;return x<0 end,false)
    assert(callsA==callsB and callsA>0 and #a.children==#b.children,'Default/false callbacks must stay equivalent')
    for i,part in a.children do assert(signature(part)==signature(b.children[i]),'Default/false generation differs') end
end
print('PASS actual octagon: nine exact slabs; five top/four upward-right native surfaces; 1480 ornaments removed; legacy defaults/callbacks retained')
'@
$target = Join-Path $repo '.tools/hub-native-studs-cli.luau'
[System.IO.File]::WriteAllText($target, $scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
