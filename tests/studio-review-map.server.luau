-- Read-only verification of the reviewed farm layout after the world is built.
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Map=require(Shared.MapSpec)
assert(Config.BuyZ+3.5<Config.BeltZ-5,'Purchase pads must stop before the conveyor facade')
assert((Config.BeltZ-5)-(Config.BuyZ+3.5)<=1,'Purchase row must be adjacent to the conveyor')
assert(Config.MergeZ==Config.AutoCollectZ,'Merge must occupy the former Auto Collect location')
assert(Config.ClaimX+7.5+9<Config.SellX-Map.DepositHalfSize.X,'Cash needs a clear gap to the left of deposit')
assert(Config.ClaimZ==Config.SellZ,'Deposit and cash must share their approach row')
local bridges,walks,approaches={},{},{}
for _,part in root:GetChildren() do
    if part.Name=="Bridge" then table.insert(bridges,part) elseif part.Name=="LobbyWalkway" then table.insert(walks,part) elseif part.Name=="BridgeApproach" then table.insert(approaches,part) end
end
assert(#bridges==6 and #walks==6 and #approaches==6,"All six bridge interfaces must exist")
for _,walk in walks do
    local radius=Vector2.new(walk.Position.X,walk.Position.Z).Magnitude
    assert(math.abs(radius+walk.Size.Z/2-92.5)<.01,"Gold walkway must end at the wood landing without overlapping")
end
for _,landing in approaches do
    local radius=Vector2.new(landing.Position.X,landing.Position.Z).Magnitude
    assert(math.abs(radius-landing.Size.Z/2-92.5)<.01,"Wood landing must meet gold path exactly")
    assert(landing.CanCollide and landing.Position.Y+landing.Size.Y/2>.18,"Landing must have an intentional shallow wood lip")
end
local counts={plots=0,lanes=0,chutes=0,merchants=0,clearDecorations=0,referenceSigns=0}
local function logicalBounds(parts,frame)
    local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
    for _,part in parts do
        if part:IsA('BasePart') then
            for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
                local point=frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))/Config.PlotScale
                lo=lo:Min(point);hi=hi:Max(point)
            end end end
        end
    end
    return lo,hi
end
local function clearRectangle(lo,hi,x0,x1,z0,z1,message)
    assert(hi.X<x0 or lo.X>x1 or hi.Z<z0 or lo.Z>z1,message)
end
for _,object in root:GetDescendants() do
    assert(object.Name~='FarmSilo' and object.Name~='SiloBay' and object.Name~='RedWhiteLighthouse','Unrequested exterior towers must be removed')
end
for id=1,Config.PlotCount do
    local plot=assert(root:FindFirstChild('Plot'..id))
    counts.plots+=1
    assert(not plot:FindFirstChild('FinishNowPad'),'Finish Now placeholder remains')
    local frame=plot:GetPivot()
    assert(math.abs(plot.StuddedLawn.Size.X/Config.PlotScale-Map.FrontWidth)<.01,'Front lawn width mismatch')
    assert(math.abs(plot.WideFarmRear.Size.X/Config.PlotScale-Map.RearWidth)<.01,'Rear lawn width mismatch')
    assert(math.abs(plot.FarmLandmarks.IslandFoundations.FrontIslandFoundation.Size.X-plot.StuddedLawn.Size.X)<.01,'Foundation must match widened lawn')
    assert(Config.ClaimX-7.5>-Map.FrontWidth/2+3,'Cash pad needs clearance inside the widened fence')
    assert(not plot:FindFirstChild('Buy50') and plot:FindFirstChild('Buy100'),'Buy100 must replace the existing fourth Buy50 pad')
    local buyCount=0
    for _,part in plot:GetChildren() do
        if part:IsA('BasePart') and part.Name:match('^Buy%d+$') then buyCount+=1 end
    end
    assert(buyCount==4,'Buy100 must not add an extra pad')
    local buy100Position=frame:PointToObjectSpace(plot.Buy100.Position)/Config.PlotScale
    assert(math.abs(buy100Position.X+44)<.01 and math.abs(buy100Position.Z-Config.BuyZ)<.01,
        'Buy100 must retain the old fourth pad position')
    local barn=assert(plot:FindFirstChild('BrickBarn'),'Existing barn decoration must remain')
    local mascot=assert(plot:FindFirstChild('BarnMascot'),'Existing roof mascot must remain')
    for _,parts in {{barn},mascot:GetDescendants()} do
        local lo,hi=logicalBounds(parts,frame)
        assert(lo.X>=-Map.FrontWidth/2+1 and hi.X<=Map.FrontWidth/2-1 and lo.Z>=-37 and hi.Z<=43,
            'Barn and mascot must remain inside the front lawn fence')
        assert(hi.X<0,'Barn and mascot must preserve the mirrored left-side layout')
        clearRectangle(lo,hi,Config.ClaimX-11,Config.ClaimX+11,Config.ClaimZ-8,Config.ClaimZ+20,
            'Barn or mascot blocks Collect Cash or its approach')
        clearRectangle(lo,hi,Config.UpgradeX-11,Config.UpgradeX+11,Config.UpgradeZ-9,Config.UpgradeZ+9,
            'Barn or mascot crowds the processor upgrade pad')
        counts.clearDecorations+=1
    end
    local sign=assert(plot:FindFirstChild('ProcessorSign'))
    local signLo,signHi=logicalBounds(sign:GetDescendants(),frame)
    local panel=sign.Processor
    local avatarHeight=5
    local width=(signHi.Z-signLo.Z)*Config.PlotScale/avatarHeight
    local height=(signHi.Y-signLo.Y)*Config.PlotScale/avatarHeight
    assert(width>=2.75 and width<=2.95 and height>=2.35 and height<=2.5,
        'Processor sign must match reference width and total height relative to a five-stud avatar')
    assert(math.abs(panel.Size.Y/avatarHeight-1.5)<.03,'Processor face must be about 1.5 avatar heights tall')
    assert(signHi.X<-Map.FrontWidth/2+2 and signLo.X>-Map.FrontWidth/2 and signLo.Z>Config.ClaimZ+20,
        'Processor board must retain its left fence pose without entering the cash approach')
    local display=panel.ProcessorDisplay
    assert(display.Queued.Size.Y.Offset==150 and display.Queued.TextScaled
        and display.Queued:FindFirstChildOfClass('UITextSizeConstraint').MaxTextSize==100,
        'Reference sign requires a dominant scaled queue count')
    assert(display.Title.Position.Y.Offset+display.Title.Size.Y.Offset<=display.Queued.Position.Y.Offset
        and display.Queued.Position.Y.Offset+display.Queued.Size.Y.Offset<=display.Rate.Position.Y.Offset
        and display.Rate.Position.Y.Offset+display.Rate.Size.Y.Offset<=display.CanvasSize.Y,
        'Processor heading, queue and rate must fit without overlap')
    counts.referenceSigns+=1
    local lucky=plot:FindFirstChild('LuckyBlock')
    if lucky then
        local label=lucky:FindFirstChild('Label')
        assert(label and label:FindFirstChild('Text') and label.Text.Text=='Lucky Block',
            'Lucky world label must contain only its name')
    end
    assert(math.abs(plot.ConveyorBackRail.Size.X/Config.PlotScale-Map.ConveyorWidth)<.01,'Conveyor must widen with the rear lawn')
    assert(Map.RearWidth-Map.ConveyorWidth==4,'Conveyor requires two logical studs inside each side fence')
    assert(plot.StuddedLawn.AuthoredGround:GetAttribute('BlenderAuthored') and not plot.StuddedLawn.AuthoredGround:GetAttribute('MissingTemplate'),'Front lawn must use imported Blender-authored relief')
    assert(plot.WideFarmRear.AuthoredGround:GetAttribute('BlenderAuthored') and not plot.WideFarmRear.AuthoredGround:GetAttribute('MissingTemplate'),'Rear lawn must use imported Blender-authored relief')
    local laneCount,chuteCount=0,0
    for _,part in plot:GetDescendants() do
        assert(not part.Name:match('^Pass_'),'Paid feature placeholder remains: '..part.Name)
        if part:IsA('BasePart') then
            local velocity=part:GetAttribute('BeltPushVelocity')
            if velocity then
                assert(part.Anchored and part.CanCollide,'Conveyor must be anchored and transport standing players')
                assert((part.AssemblyLinearVelocity-frame:VectorToWorldSpace(velocity)).Magnitude<.02,'Belt push must rotate with every radial plot')
            end
            if part.Name=='StuddedConveyorRamp' then
                laneCount+=1
                assert(part.Color.R>part.Color.G*2 and part.Color.R>part.Color.B*2,'Conveyor travel surface must remain red')
            elseif part.Name=='ConveyorChuteSlope' then
                chuteCount+=1
            elseif part.Name=='DisplayPlatform' or part.Name=='ShelfBase' or part.Name=='DisplayDivider' then
                assert(part.CanCollide,'Producer stand must stop players from walking through it')
            end
        end
    end
    -- Every unchanged drop column and center-bound path must stay above a red lane.
    local motion=require(Shared.MiniMotion)
    for x=-45,45,.5 do
        local covered=math.abs(x)<=7
        for _,part in plot:GetChildren() do
            if part.Name=='StuddedConveyorRamp' then
                local point=part.CFrame:PointToObjectSpace(frame:PointToWorldSpace(Vector3.new(x,motion.beltHeight(x),Config.BeltZ)*Config.PlotScale))
                if math.abs(point.X)<=part.Size.X/2+.01 and math.abs(point.Z)<=part.Size.Z/2 then
                    assert(point.Y>part.Size.Y/2,'Mini trajectory must clear its red lane')
                    covered=true
                end
            end
        end
        assert(covered,'Widened conveyor must preserve all existing drop and slide positions')
    end
    assert(laneCount==8 and chuteCount==4,'Conveyor must have eight curved lane sections and four shallow chute sections')
    counts.lanes+=laneCount;counts.chutes+=chuteCount
    local merchant=assert(plot.DepositBooth:FindFirstChild('BrainrotLogKeeper'))
    assert(merchant:GetAttribute('BlenderAuthored')==true,'Farm merchant must use authored Blender geometry')
    counts.merchants+=1
end
for index=1,2 do
    local stall=assert(root.HubScenery:FindFirstChild('BrainrotMarket'..index))
    local merchant=assert(stall:FindFirstChild(if index==1 then 'BrainrotLogKeeper' else 'BrainrotCoffeeKeeper'))
    assert(merchant:GetAttribute('BlenderAuthored')==true)
    local position=stall.MarketStand.Position
    assert(Vector2.new(position.X,position.Z).Magnitude>45,'Market stalls must leave the central plaza open')
    counts.merchants+=1
end
return counts
