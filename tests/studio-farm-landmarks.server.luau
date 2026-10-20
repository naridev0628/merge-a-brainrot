-- Run after WorldBuilder integrates FarmLandmarks and the generated world is ready.
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Map=require(Shared.MapSpec)
local scale=Map.PlotScale
local function bounds(part,frame)
    local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        local p=frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))/scale
        lo=lo:Min(p);hi=hi:Max(p)
    end end end
    return lo,hi
end
for id=1,Config.PlotCount do
    local plot=assert(root:FindFirstChild('Plot'..id))
    local landmarks=assert(plot:FindFirstChild('FarmLandmarks'),'Each plot needs island foundations')
    local frame=plot:GetPivot()
    local count=0
    assert(not landmarks:FindFirstChild('FarmSilo'),'Removed farm silo must stay absent')
    assert(not landmarks.IslandFoundations:FindFirstChild('SiloBay'),'Removed silo bay must stay absent')
    for _,part in landmarks:GetDescendants() do if part:IsA('BasePart') then
        count+=1
        assert(part.Anchored and not part.CanTouch,'Landmarks must be fixed and must not emit touch events')
        local lo,hi=bounds(part,frame)
        if part:GetAttribute('FoundationSolid') then
            assert(part.CanCollide and part.CanQuery and hi.Y<=.01,'Foundations must support the island without raising its existing walking surface')
            assert(lo.Y<=-7.5,'The thick green foundation must reach below the waterline')
        else
            assert(not part.CanCollide and not part.CanQuery,'Visual ribs and studs must not obstruct player movement or queries')
        end
    end end
    assert(count<=300,'Additional geometry exceeded the per-plot budget')
    -- The continuous side fence must still guard the lawn after bay removal.
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances={plot}
    params.RespectCanCollide=true
    for z=-34,-14,2 do
        local from=frame:PointToWorldSpace(Vector3.new(-Map.FrontWidth/2+2,3,z)*scale)
        local hit=workspace:Raycast(from,frame:VectorToWorldSpace(Vector3.new(-4,0,0)*scale),params)
        assert(hit and hit.Instance.Name=='FenceBarrier','Removing the silo must not open a hole in the side fence')
    end
end
local skirt=assert(root:FindFirstChild('HubIslandSkirt'))
for _,part in skirt:GetDescendants() do if part:IsA('BasePart') then
    assert(not part.CanTouch)
    if part:GetAttribute('FoundationSolid') then
        assert(part.CanCollide and part.CanQuery,'Hub skirt must be structurally solid')
    else
        assert(not part.CanCollide and not part.CanQuery,'Hub edge details must be decorative')
    end
end end
return 'PASS bounded farm landmarks, lower foundations, removed silo bays and intact side fences'
