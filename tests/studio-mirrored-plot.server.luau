local root=workspace.MergeABrainrotGenerated
local Shared=game.ReplicatedStorage.Shared
local Map=require(Shared.MapSpec)
local Config=require(Shared.Config)
for id=1,6 do
    local plot=root['Plot'..id];local frame=plot:GetPivot();local scale=Map.PlotScale
    local function localPosition(part) return frame:PointToObjectSpace(part.Position)/scale end
    assert(localPosition(plot.DepositPad).X<0 and localPosition(plot.BrickBarn).X<0,'Farmer and barn must move to the left')
    assert(localPosition(plot.ProcessorSign.Processor).X<0 and localPosition(plot.GroupRewardBoard).X>0,'Utility boards must swap sides')
    assert(math.abs(localPosition(plot.CoinPad).X-Config.ClaimX)<.01 and math.abs(localPosition(plot.UpgradePad).X-Config.UpgradeX)<.01,'Pad geometry must match mirrored server coordinates')
    assert(plot.DepositBooth.BoothFoundation.Size.X>=18.7*scale and plot.DepositBooth.BoothFoundation.Size.Z>=9.9*scale,'Farmer stall must be larger')
    assert(math.abs(plot.DepositBooth.Shopkeeper.Size.Y-5.5)<.01,'Keep the farmer at avatar height')
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
return 'PASS mirrored utilities, enlarged stall, full red conveyor and fenced plot fronts'
