-- Read-only current hub acceptance after a fresh World.build().
-- Historical raised-grid pass: 2037 candidates - 557 fully hidden = 1480 studs.
-- The current native-grid pass removes those remaining 1480 inert ornaments.
-- hub-stud-occlusion.luau still covers the legacy optional containment callback.
-- Also run studio-hub-routes.server.luau and studio-bridge-grounding.server.luau.
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local hub=assert(root:FindFirstChild('StuddedOctagonalPlatform'))
assert(hub:GetAttribute('Radius')==96 and hub:GetScale()==1,'Hub dimensions must remain unchanged')
local radius,thickness=96,1
local a=radius*(math.sqrt(2)-1)
local leg=radius-a
local expected={{name='CenterSlab',class='Part',size=Vector3.new(2*a,thickness,2*a),cf=CFrame.new(0,-.5,0)}}
for side=0,3 do
    local turn=CFrame.Angles(0,side*math.pi/2,0)
    table.insert(expected,{name='StraightEdgeSlab',class='Part',size=Vector3.new(leg,thickness,2*a),
        cf=turn*CFrame.new(a+leg/2,-.5,0)})
    table.insert(expected,{name='DiagonalCornerSlab',class='WedgePart',size=Vector3.new(thickness,leg,leg),
        cf=turn*CFrame.fromMatrix(Vector3.new(a+leg/2,-.5,a+leg/2),Vector3.yAxis,Vector3.xAxis,-Vector3.zAxis)})
end
local function sameFrame(actual,wanted)
    return (actual.Position-wanted.Position).Magnitude<.0001
        and (actual.RightVector-wanted.RightVector).Magnitude<.0001
        and (actual.UpVector-wanted.UpVector).Magnitude<.0001
end
local function sameColor(actual,wanted)
    return math.abs(actual.R-wanted.R)<.0001 and math.abs(actual.G-wanted.G)<.0001 and math.abs(actual.B-wanted.B)<.0001
end
local parts=hub:GetChildren()
assert(#parts==9,'Native hub must contain exactly nine slabs and zero SquareStuds')
local used={}
for _,entry in expected do
    local found=nil
    for _,part in parts do
        if part.Name==entry.name and sameFrame(part.CFrame,entry.cf) then
            assert(not found,'Duplicate original slab');found=part
        end
    end
    local part=assert(found,'Missing original slab '..entry.name)
    assert(not used[part] and part.ClassName==entry.class,'Slab identity changed');used[part]=true
    assert((part.Size-entry.size).Magnitude<.0001,'Slab geometry changed')
    assert(sameColor(part.Color,Color3.fromRGB(115,210,38)) and part.Material==Enum.Material.Plastic,'Slab color/material changed')
    assert(part.Anchored and part.CanCollide and part.CanQuery and not part.CanTouch and part.Transparency==0,'Slab flags changed')
    if part:IsA('WedgePart') then
        assert((part.CFrame.RightVector-Vector3.yAxis).Magnitude<.0001,'Native wedge studs must face world up')
        assert(part.RightSurface==Enum.SurfaceType.Studs and part.TopSurface==Enum.SurfaceType.Smooth,'Wedge surface changed incorrectly')
    else
        assert(part.Shape==Enum.PartType.Block and (part.CFrame.UpVector-Vector3.yAxis).Magnitude<.0001)
        assert(part.TopSurface==Enum.SurfaceType.Studs and part.RightSurface==Enum.SurfaceType.Smooth,'Rectangular top surface changed incorrectly')
    end
    for _,face in {'BottomSurface','LeftSurface','FrontSurface','BackSurface'} do
        assert(part[face]==Enum.SurfaceType.Smooth,'Side/bottom surface changed')
    end
end
-- Native surface detail must not change the neighboring plaza or path slabs.
local circle=assert(root:FindFirstChild('GatheringCircle'))
assert(circle.Shape==Enum.PartType.Cylinder and (circle.Size-Vector3.new(.3,68,68)).Magnitude<.0001)
assert(sameFrame(circle.CFrame,CFrame.new(0,.15,0)*CFrame.Angles(0,0,math.pi/2)))
assert(sameColor(circle.Color,Color3.fromRGB(255,192,98)) and circle.Material==Enum.Material.Plastic)
assert(circle.Anchored and circle.CanCollide and circle.CanQuery and not circle.CanTouch and circle.Transparency==0)
assert(circle.TopSurface==Enum.SurfaceType.Studs and circle.RightSurface==Enum.SurfaceType.Smooth,'Plaza surface was changed')
local walkways,plazaStuds=0,0
for _,part in root:GetChildren() do
    if part.Name=='LobbyWalkway' then
        walkways+=1
        local matches=0
        for side=0,5 do
            local angle=side*math.pi/3
            local outward=Vector3.new(math.sin(angle),0,math.cos(angle))
            local cf=CFrame.lookAt(outward*65+Vector3.new(0,.08,0),outward*90+Vector3.new(0,.08,0))
            if sameFrame(part.CFrame,cf) then matches+=1 end
        end
        assert(matches==1 and (part.Size-Vector3.new(14,.2,62)).Magnitude<.0001,'Path geometry changed')
        assert(sameColor(part.Color,Color3.fromRGB(245,204,123)) and part.Material==Enum.Material.Plastic)
        assert(part.Anchored and not part.CanCollide and part.CanQuery and not part.CanTouch and part.Transparency==0)
        assert(part.TopSurface==Enum.SurfaceType.Studs,'Path studs changed')
    elseif part.Name=='PlazaStud' then
        plazaStuds+=1
        assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch)
        assert((part.Size-Vector3.new(.6,.14,.6)).Magnitude<.0001 and math.abs(part.Position.Y-.37)<.0001)
    end
end
local expectedPlaza=0
for x=-32,32,2 do for z=-32,32,2 do if x*x+z*z<33*33 then expectedPlaza+=1 end end end
assert(walkways==6 and plazaStuds==expectedPlaza,'Path/plaza decoration count changed')
-- Probe the actual collision foundation underneath all six public routes,
-- including slab seams; native studs themselves contribute no collision.
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={hub}
params.RespectCanCollide=true
local probes=0
for sector=0,5 do
    local angle=sector*math.pi/3
    local outward=Vector3.new(math.sin(angle),0,math.cos(angle))
    local right=Vector3.new(math.cos(angle),0,-math.sin(angle))
    for distance=0,94,2 do for _,side in {-5,0,5} do
        local start=outward*distance+right*side+Vector3.new(0,4,0)
        local hit=workspace:Raycast(start,Vector3.new(0,-6,0),params)
        assert(hit and hit.Instance.CanCollide and math.abs(hit.Position.Y)<.0001,'Hub route lost its original walkable top')
        probes+=1
    end end
end
return 'PASS native hub: nine unchanged collision slabs; zero physical hub studs (1480 removed); six paths/plaza preserved; '..probes..' foundation probes'
