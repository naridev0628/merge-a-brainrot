-- Read-only: verify the reference-inspired gold accents stay in corner pockets.
local Config=require(game.ReplicatedStorage.Shared.Config)
local Map=require(game.ReplicatedStorage.Shared.MapSpec)
local generated=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local function bounds(part,frame)
    local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        local point=frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))/Map.PlotScale
        lo=lo:Min(point);hi=hi:Max(point)
    end end end
    return lo,hi
end
for index=1,Config.PlotCount do
    local plot=assert(generated:FindFirstChild('Plot'..index))
    local facade=assert(plot:FindFirstChild('ConveyorFacade'))
    local frame=plot:GetPivot()
    local total=0
    for _,part in facade:GetDescendants() do if part:IsA('BasePart') then total+=1 end end
    assert(total<220,'End accents must fit the existing facade budget')
    for _,side in {-1,1} do
        local crop=assert(facade:FindFirstChild(if side==-1 then 'ConveyorWheatLeft' else 'ConveyorWheatRight'))
        local count,stems=0,0
        local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
        for _,part in crop:GetDescendants() do if part:IsA('BasePart') then
            count+=1
            if part.Name=='WheatStem' then stems+=1 end
            assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch)
            local a,b=bounds(part,frame)
            lo=lo:Min(a);hi=hi:Max(b)
            if part.Name:match('^WheatGrain') then assert(part.TopSurface==Enum.SurfaceType.Studs) end
        end end
        assert(count==21 and stems==5,'Each authored bundle needs exactly five distinct stalks')
        local endX=side*((Config.Columns*Config.ColumnSpacing+1)/2+1.9)
        assert(lo.X>=endX-1.5-.01 and hi.X<=endX+1.5+.01,'Crop must stay beside the conveyor end')
        assert(lo.Y>=-.01 and hi.Y<=5.31,'Crops stay low and grounded')
        assert(lo.Z>=Config.BeltZ-8.1 and hi.Z<=Config.BeltZ-6.7,'Crop must stay in the shallow rear corner pocket')
        assert(hi.Z<Config.BeltZ-5.3,'Crop must remain in front of the cream skirt')
        -- A two-stud clearance behind the purchase row leaves its approach open.
        assert(lo.Z>Config.BuyZ+3.5+2)
        assert(lo.X>=50 or hi.X<=-50,'No central lawn or collection-lane decoration')
        for _,treePart in plot.PlotDecor:GetDescendants() do
            if treePart:IsA('BasePart') and treePart.CanCollide then
                local a,b=bounds(treePart,frame)
                assert(hi.X<a.X or lo.X>b.X or hi.Y<a.Y or lo.Y>b.Y or hi.Z<a.Z or lo.Z>b.Z,
                    'Crop overlaps an existing tree body: '..treePart.Name)
            end
        end
    end
end
return 'PASS two low gold end accents per plot, five-stalk silhouettes, tree/pad/belt clearance and unchanged facade budget'
