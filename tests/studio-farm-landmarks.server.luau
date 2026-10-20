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
local siloBounds={}
for id=1,Config.PlotCount do
    local plot=assert(root:FindFirstChild('Plot'..id))
    local landmarks=assert(plot:FindFirstChild('FarmLandmarks'),'Each plot needs island foundations and a silo')
    local frame=plot:GetPivot()
    local count=0
    local siloLo,siloHi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
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
        if part:IsDescendantOf(landmarks.FarmSilo) then siloLo=siloLo:Min(lo);siloHi=siloHi:Max(hi) end
    end end
    assert(count<=300,'Additional geometry exceeded the per-plot budget')
    assert(siloHi.Y>=34 and siloHi.X<=-48.5,'Silo must be tall and remain outside the left fence')
    assert(siloLo.X>=-62 and siloLo.Z>=-35 and siloHi.Z<=-13,'Silo must fit its supporting bay')
    local bay=landmarks.IslandFoundations.SiloBay
    local bayLo,bayHi=bounds(bay,frame)
    local lawnLo,lawnHi=bounds(assert(plot:FindFirstChild('StuddedLawn')),frame)
    -- ScaleTo/PivotTo introduce small float errors, even at a shared edge.
    assert(math.abs(bayHi.Y-lawnHi.Y)<.01 and math.abs(bayHi.X-lawnLo.X)<.01,
        'Utility bay must meet the lawn at its existing height and side edge')
    for _,part in plot:GetChildren() do
        local passKey=part.Name:match('^Pass_(.+)$')
        local pad=part.Name:match('^Buy%d+$') or (passKey and Map.PassPads[passKey])
            or part.Name=='DepositPad' or part.Name=='CoinPad' or part.Name=='UpgradePad'
            or part.Name=='FinishNowPad' or part.Name=='MergePad' or part.Name=='GroupRewardPad'
        if part:IsA('BasePart') and pad then
            local lo,hi=bounds(part,frame)
            assert(siloHi.X<lo.X-1 or siloLo.X>hi.X+1 or siloHi.Z<lo.Z-1 or siloLo.Z>hi.Z+1,'Silo crowds '..part.Name)
        end
    end
    -- The unchanged side fence must separate the full bay from the play lawn.
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances={plot}
    params.RespectCanCollide=true
    for z=-34,-14,2 do
        local from=frame:PointToWorldSpace(Vector3.new(-46,3,z)*scale)
        local hit=workspace:Raycast(from,frame:VectorToWorldSpace(Vector3.new(-4,0,0)*scale),params)
        assert(hit and hit.Instance.Name=='FenceBarrier','Silo utility bay must stay behind the continuous side fence')
    end
    local worldLo,worldHi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
    for _,x in {bayLo.X,bayHi.X} do for _,z in {bayLo.Z,bayHi.Z} do
        local p=frame:PointToWorldSpace(Vector3.new(x,0,z)*scale)
        worldLo=worldLo:Min(p);worldHi=worldHi:Max(p)
    end end
    table.insert(siloBounds,{lo=worldLo,hi=worldHi})
end
for i,a in siloBounds do for j=i+1,#siloBounds do
    local b=siloBounds[j]
    assert(a.hi.X<b.lo.X or a.lo.X>b.hi.X or a.hi.Z<b.lo.Z or a.lo.Z>b.hi.Z,'Adjacent radial utility bays overlap')
end end
local skirt=assert(root:FindFirstChild('HubIslandSkirt'))
for _,part in skirt:GetDescendants() do if part:IsA('BasePart') then
    assert(not part.CanTouch)
    if part:GetAttribute('FoundationSolid') then
        assert(part.CanCollide and part.CanQuery,'Hub skirt must be structurally solid')
    else
        assert(not part.CanCollide and not part.CanQuery,'Hub edge details must be decorative')
    end
end end
return 'PASS bounded farm landmarks, lower foundations, guarded silo bays, clear pads and nonoverlapping radial additions'
