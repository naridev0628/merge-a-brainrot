$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$numericSource = Get-Content -LiteralPath (Join-Path $repo 'tests/conveyor-visibility-cli.ps1') -Raw
$start = $numericSource.IndexOf('local vectorMT={}')
$end = $numericSource.IndexOf('local modules={')
$numeric = $numericSource.Substring($start, $end - $start)
$runtime = @'
Vector3.yAxis=Vector3.new(0,1,0);Vector3.zAxis=Vector3.new(0,0,1)
local priorIndex=vectorMT.__index
vectorMT.__index=function(v,key)
    if key=='Unit' then return v*(1/v.Magnitude) end
    return priorIndex(v,key)
end
local function cross(a,b) return Vector3.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end
function CFrame.lookAt(from,to,up)
    local back=(from-to).Unit
    local right=cross(up or Vector3.yAxis,back).Unit
    local actualUp=cross(back,right)
    return cf(from,{right.X,actualUp.X,back.X,right.Y,actualUp.Y,back.Y,right.Z,actualUp.Z,back.Z})
end
local created={}
local Instance={}
function Instance.new(class)
    local object={ClassName=class,Destroy=function(self) self.destroyed=true end}
    table.insert(created,object)
    return object
end
local now=0
local environment=setmetatable({
    Vector3=Vector3,CFrame=CFrame,Instance=Instance,workspace={},
    Enum={Material={SmoothPlastic='SmoothPlastic'},SurfaceType={Smooth='Smooth'},Font={FredokaOne='FredokaOne'}},
    Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end},
    UDim2={fromOffset=function() return {} end,new=function() return {} end},
    os={clock=function() return now end},
},{__index=getfenv()})
local function compile(source)
    local chunk=assert(loadstring(source));setfenv(chunk,environment);return chunk()
end
'@
$source = Get-Content -LiteralPath (Join-Path $repo 'src/client/Controllers/TutorialGuide.luau') -Raw
$checks = @'
local guide=Guide.new()
assert(#guide.parts==36 and #guide.arrows==12 and #guide.starterParts==3,'Guide must use the bounded volumetric pool')
assert(#guide.lights==3,'Only the nearest three arrows may cast a soft glow')
local allocated=#created
for _,pieces in guide.arrows do
    assert(pieces[1].ClassName=='Part' and pieces[2].ClassName=='WedgePart' and pieces[3].ClassName=='WedgePart')
    assert(pieces[1].Size.Y>=.2 and pieces[2].Size.X>=.2,'Shaft and head need real visible extrusion')
    assert(pieces[1].Color.R==1 and pieces[1].Color.G==1 and pieces[1].Color.B==1,'Reference guide must be white')
    assert(pieces[1].Material=='SmoothPlastic' and pieces[1].CastShadow,'Lighting must reveal the solid arrow edges')
    for _,part in pieces do assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery) end
end
local origin,target=Vector3.new(0,3,0),Vector3.new(0,0,-24)
guide:update(origin,target)
local function center(index)
    return guide.arrows[index][1].CFrame:PointToWorldSpace(Vector3.new(0,0,-.38))
end
assert(center(1).Y>2.8,'First arrow must emerge at the avatar waist, not the floor')
assert(center(2).Y<center(1).Y and center(2).Y>.32,'Stream must curve gradually down')
assert(math.abs(center(4).Y-.32)<1e-8,'Stream must join the ground path smoothly')
for _,pieces in guide.arrows do
    local leftTip=pieces[2].CFrame:PointToWorldSpace(Vector3.new(0,-.36,-.44))
    local rightTip=pieces[3].CFrame:PointToWorldSpace(Vector3.new(0,-.36,-.44))
    assert((leftTip-rightTip).Magnitude<1e-8,'Both triangular prisms must meet at one forward arrow tip')
end
local first=center(1)
now=.1;guide:update(origin,target)
assert(center(1).Z<first.Z and center(1).Y<first.Y,'Arrows must visibly flow outward and downward from the body')
for frame=1,300 do now=frame/60;guide:update(origin,target) end
assert(#created==allocated,'Animation must reuse all parts and lights without per-frame allocation')
guide:update(origin,Vector3.new(0,12,0))
for _,p in guide.parts do assert(p.Transparency==1,'Vertical-only target must clear stale geometry') end
guide:update(origin,target);guide:update(nil,target)
for _,p in guide.parts do assert(p.Transparency==1,'Missing avatar must hide the full pool') end
for _,light in guide.lights do assert(not light.Enabled,'Hidden guides must disable their glow') end
guide:showStarter(target)
assert(guide.markerGui.Enabled and not guide.markerGui.AlwaysOnTop,'Starter text must not cover the character through geometry')
for _,p in guide.starterParts do assert(p.Transparency<1,'Starter direction must also be a real 3D arrow') end
guide:showStarter(nil)
for _,p in guide.starterParts do assert(p.Transparency==1) end
guide:destroy()
assert(guide.folder.destroyed and #guide.parts==0 and #guide.arrows==0 and #guide.lights==0)
print('PASS 12 pooled 3D body arrows, prismatic forward tips, waist emission, smooth ground curve, stream animation, three bounded lights, 3D starter arrow, hiding and cleanup')
'@
$scriptText = $numeric + "`n" + $runtime + "`nlocal Guide=compile([====[`n" + $source + "`n]====])`n" + $checks
$target = Join-Path $repo '.tools/tutorial-guide-volume-cli.luau'
[IO.File]::WriteAllText($target,$scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
