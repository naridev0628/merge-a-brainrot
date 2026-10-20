-- Run after WorldBuilder has built the hub. Read-only fixture.
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local Config=require(game.ReplicatedStorage.Shared.ObbyConfig)
local course=assert(root:FindFirstChild('ObbyCourse'))
local count=0
local function bounds(part)
    local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        local point=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
        lo=lo:Min(point);hi=hi:Max(point)
    end end end
    return lo,hi
end
local landings={}
local solids={}
for index=1,#Config.Checkpoints+1 do
    local finish=index>#Config.Checkpoints
    local spec=if finish then Config.Finish else Config.Checkpoints[index]
    local part=assert(root:FindFirstChild(if finish then 'ParkourFinish' else 'ParkourStep'..index))
    table.insert(landings,Vector3.new(spec.x,spec.y,spec.z))
    count+=1
    assert(part:IsA('BasePart') and part.Anchored and part.CanCollide and part.CanQuery and not part.CanTouch)
    assert(part.TopSurface==Enum.SurfaceType.Studs,'Every landing must keep native studs')
    local lo,hi=bounds(part)
    table.insert(solids,{part=part,lo=lo,hi=hi})
    assert(math.abs(lo.X-(spec.x-spec.halfX))<.001 and math.abs(hi.X-(spec.x+spec.halfX))<.001
        and math.abs(lo.Z-(spec.z-spec.halfZ))<.001 and math.abs(hi.Z-(spec.z+spec.halfZ))<.001,
        'Landing footprint must exactly match ObbyRun: '..part.Name)
    assert(math.abs(hi.Y-spec.y)<.001 and part.Size.Y>=1,'Landing top must exactly match sampled foot height')
    if not finish then
        local number=assert(part:FindFirstChild('StepNumber'))
        assert(number:IsA('SurfaceGui') and number.Face==Enum.NormalId.Top and number.Text.Text==tostring(index))
    end
end
local decorations={}
for _,part in course:GetDescendants() do if part:IsA('BasePart') then
    count+=1
    assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,
        'Course decoration must never affect jumps or server queries: '..part.Name)
    local lo,hi=bounds(part)
    assert(lo.X>-27 and hi.X<27 and lo.Z>-27 and hi.Z<27,'Course must remain inside the inner plaza')
    table.insert(decorations,{part=part,lo=lo,hi=hi})
end end
assert(count<140,'Obby exceeded its full solid + decoration part budget')
local start=assert(course:FindFirstChild('StartMarker'))
assert(start.Position.Y+start.Size.Y/2<.6 and not start.CanCollide,'Start marker must stay flush with plaza')
assert(start.StartText.Text.Text=='START')
local finish=assert(root:FindFirstChild('ParkourFinish'))
assert(finish.RewardLabel.Text.Text=='+0.25x Minis for 5m','Static reward must match the adapted config')
assert(course:FindFirstChild('FinishFlagPole') and course:FindFirstChild('FinishFlag'))
-- A conservative visual corridor around each center-to-center jump. No tall
-- decoration may cross it; low corner studs stay below the sampled avatar body.
for index=1,#landings-1 do
    local from,to=landings[index],landings[index+1]
    for sample=0,20 do
        local alpha=sample/20
        local foot=from:Lerp(to,alpha)+Vector3.new(0,math.sin(alpha*math.pi)*4,0)
        local lo=foot+Vector3.new(-1.1,.4,-1.1)
        local hi=foot+Vector3.new(1.1,5,1.1)
        for _,entry in decorations do
            local a,b=entry.lo,entry.hi
            assert(b.X<lo.X or a.X>hi.X or b.Y<lo.Y or a.Y>hi.Y or b.Z<lo.Z or a.Z>hi.Z,
                'Decoration crowds jump '..index..': '..entry.part.Name)
        end
        -- The former finish overhung the last two jumps. Include every landing
        -- body so future route changes cannot reintroduce a low ceiling.
        if index>=#landings-2 then
            for _,entry in solids do
                local a,b=entry.lo,entry.hi
                assert(b.X<lo.X or a.X>hi.X or b.Y<lo.Y or a.Y>hi.Y or b.Z<lo.Z or a.Z>hi.Z,
                    'Landing blocks headroom on jump '..index..': '..entry.part.Name)
            end
        end
    end
end
-- Existing six approach paths begin outside the inner plaza. Check added
-- geometry against their actual oriented bounds, with an avatar-height margin.
for _,walk in root:GetChildren() do if walk:IsA('BasePart') and walk.Name=='LobbyWalkway' then
    for _,entry in decorations do
        local part=entry.part
        local center=walk.CFrame:PointToObjectSpace(part.Position)
        local radius=part.Size.Magnitude/2
        assert(math.abs(center.X)>walk.Size.X/2+radius or math.abs(center.Z)>walk.Size.Z/2+radius
            or center.Y-radius>7,'Course decoration crowds a hub approach')
    end
end end
return 'PASS exact obby landing tops/footprints, numbered native studs, adapted reward, clear jump/approach corridors and <140-part budget'
