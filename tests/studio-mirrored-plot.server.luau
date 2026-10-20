local root=workspace.MergeABrainrotGenerated
local Shared=game.ReplicatedStorage.Shared
local Map=require(Shared.MapSpec)
local Config=require(Shared.Config)
for id=1,6 do
    local plot=root['Plot'..id];local frame=plot:GetPivot();local scale=Map.PlotScale
    local function localPosition(part) return frame:PointToObjectSpace(part.Position)/scale end
    local function bounds(part)
        local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
        for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
            local corner=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
            local p=frame:PointToObjectSpace(corner)/scale
            lo=lo:Min(p);hi=hi:Max(p)
        end end end
        return lo,hi
    end
    assert(localPosition(plot.DepositPad).X<0 and localPosition(plot.BrickBarn).X<0,'Farmer and barn must move to the left')
    assert(localPosition(plot.ProcessorSign.Processor).X<0 and localPosition(plot.GroupRewardBoard).X>0,'Utility boards must swap sides')
    assert(math.abs(localPosition(plot.CoinPad).X-Config.ClaimX)<.01 and math.abs(localPosition(plot.UpgradePad).X-Config.UpgradeX)<.01,'Pad geometry must match mirrored server coordinates')
    assert(plot.DepositBooth.BoothFoundation.Size.X>=18.7*scale and plot.DepositBooth.BoothFoundation.Size.Z>=9.9*scale,'Farmer stall must be larger')
    assert(math.abs(plot.DepositBooth.Shopkeeper.Size.Y-5.5)<.01,'Keep the farmer at avatar height')
    local booth=plot.DepositBooth
    assert(booth.BoothFoundation.Color==Color3.fromRGB(106,119,176),'The existing booth floor palette must remain unchanged')
    local floorLo,floorHi=bounds(booth.BoothFoundation)
    local counterLo,counterHi=bounds(booth.Counter)
    local farmerLo,farmerHi=bounds(booth.Shopkeeper)
    assert(math.abs(counterHi.Y*scale-2.275)<.01,'The counter top must be 2.275 world studs above the plot')
    assert((booth.Counter.Size/scale-Vector3.new(16.25,.6,3.75)).Magnitude<.01,'Lowering the counter must preserve its slab dimensions')
    assert(farmerHi.Y-counterHi.Y>=(farmerHi.Y-farmerLo.Y)*.62,'The counter must leave at least 62 percent of the actual farmer height above the slab for its torso and sleeves')
    assert(not booth.Shopkeeper.CanCollide and not booth.Shopkeeper.CanQuery and not booth.Shopkeeper.CanTouch,'The farmer must remain decorative')
    local panelCount,frontCount,sideCount=0,0,0
    for _,panel in booth:GetChildren() do
        if panel.Name~='CounterFrontPanel' and panel.Name~='CounterSidePanel' then continue end
        panelCount+=1
        if panel.Name=='CounterFrontPanel' then frontCount+=1 else sideCount+=1 end
        assert(panel:IsA('BasePart') and not panel.CanCollide and not panel.CanQuery and not panel.CanTouch,'Counter panels must add no collision, query or touch targets')
        assert(panel.Color==Color3.fromRGB(55,66,165),'Counter panels need the blue-purple palette verified under the deposit light')
        local lo,hi=bounds(panel)
        assert(math.abs(lo.Y-floorHi.Y)<.01 and math.abs(hi.Y-counterLo.Y)<.01,'Counter panels must meet the floor and counter without gaps')
        for _,limit in {{floorLo,floorHi},{counterLo,counterHi}} do
            assert(lo.X>=limit[1].X-.01 and hi.X<=limit[2].X+.01 and lo.Z>=limit[1].Z-.01 and hi.Z<=limit[2].Z+.01,'Counter panels must remain inside the existing footprint')
        end
        assert(hi.X<=farmerLo.X-.25 or lo.X>=farmerHi.X+.25 or hi.Z<=farmerLo.Z-.25 or lo.Z>=farmerHi.Z+.25,'Counter panels must remain clear of the actual farmer mesh')
        assert(hi.Z<=Config.SellZ-Map.DepositHalfSize.Y-5.5,'Counter panels must leave the deposit approach open')
    end
    assert(panelCount==3 and frontCount==1 and sideCount==2,'Each farmer counter needs exactly three broad panels')
    local frontLo,frontHi=bounds(booth.CounterFrontPanel)
    assert(math.abs(frontLo.X-counterLo.X)<.01 and math.abs(frontHi.X-counterHi.X)<.01 and math.abs(frontHi.Z-counterHi.Z)<.01,'The counter front must span the existing slab')
    local leftClosed,rightClosed=false,false
    for _,panel in booth:GetChildren() do if panel.Name=='CounterSidePanel' then
        local lo,hi=bounds(panel)
        assert(math.abs(lo.Z-counterLo.Z)<.01 and math.abs(hi.Z-frontLo.Z)<.01,'Counter sides must join the front and reach the slab rear')
        if math.abs(lo.X-counterLo.X)<.01 then leftClosed=true end
        if math.abs(hi.X-counterHi.X)<.01 then rightClosed=true end
    end end
    assert(leftClosed and rightClosed,'Both ends of the counter must be enclosed')
    local farmerTop=localPosition(booth.Shopkeeper).Y+booth.Shopkeeper.Size.Y/(2*scale)
    local signBottom=localPosition(booth.MiniSignFrame).Y-booth.MiniSignFrame.Size.Y/(2*scale)
    local signTop=localPosition(booth.MiniSignFrame).Y+booth.MiniSignFrame.Size.Y/(2*scale)
    assert(signBottom>=farmerTop+.4,'The hanging sign must leave the farmer head visible')
    local boothFront=-math.huge
    for _,part in booth:GetDescendants() do if part:IsA('BasePart') then
        if part.Name=='AwningFringe' then
            assert(localPosition(part).Y-part.Size.Y/(2*scale)>=signTop+.05,'The deep fringe must not cover the hanging sign')
        end
        for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
            local corner=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
            boothFront=math.max(boothFront,frame:PointToObjectSpace(corner).Z/scale)
        end end end
    end end
    assert(boothFront<=Config.SellZ-Map.DepositHalfSize.Y-4,'The booth must leave an open approach behind the deposit pad')
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={plot.ConveyorCenter};params.RespectCanCollide=true
    for z=Config.BeltZ-3.9,Config.BeltZ+3.9,.3 do
        assert(workspace:Raycast(frame:PointToWorldSpace(Vector3.new(0,10,z)*scale),Vector3.new(0,-12,0),params),'Red conveyor center must cover the whole belt')
    end
    assert(plot.ConveyorCenter.Color==Color3.fromRGB(222,61,62),'Center conveyor must be red')
    params.FilterDescendantsInstances={plot}
    local left=Map.FarmerAlcoveCenter.X-Map.FarmerAlcoveSize.X/2
    local right=Map.FarmerAlcoveCenter.X+Map.FarmerAlcoveSize.X/2
    for x=-47,47,.5 do
        if math.abs(x)*scale<=7 or (x>left and x<right) then continue end
        local from=frame:PointToWorldSpace(Vector3.new(x,3,-36)*scale)
        local hit=workspace:Raycast(from,frame:VectorToWorldSpace(Vector3.new(0,0,-5)*scale),params)
        assert(hit and hit.Instance.CanCollide,'Front fence has a water exit at '..x)
    end
    for x=left+.5,right-.5,.5 do
        local from=frame:PointToWorldSpace(Vector3.new(x,3,-49)*scale)
        assert(workspace:Raycast(from,frame:VectorToWorldSpace(Vector3.new(0,0,-5)*scale),params),'Farmer alcove fence must close its back edge')
    end
end
return 'PASS mirrored utilities, lowered counter with torso allowance, 18 inert panels within existing footprints and clear of farmer meshes, farmer/sign/awning visibility, clear deposit approach, full red conveyor and fenced plot fronts'
