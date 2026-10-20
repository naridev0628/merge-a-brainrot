-- Private unparented clones; reads the current camera without moving it.
-- Covers native property contracts, not a rendered screenshot or device QA.
local Controller=require(game.Players.LocalPlayer.PlayerScripts.Controllers.PadLabels)
-- Main may already manage the local plot. Clone a canonical unmanaged plot,
-- not its locally scaled text and temporary title-fit constraints.
local source
for id=1,6 do
    local candidate=workspace.MergeABrainrotGenerated:FindFirstChild('Plot'..id)
    local buy=candidate and candidate:FindFirstChild('Buy1')
    local title=buy and buy:FindFirstChild('Label') and buy.Label:FindFirstChild('Text')
    if title and not title.TextScaled and not title:FindFirstChild('PadLabelTextFit') then source=candidate;break end
end
assert(source,'The fixture needs one fully built unmanaged plot as its canonical source')
local camera=assert(workspace.CurrentCamera)
local sandbox=Instance.new('Folder')
local world=Instance.new('Folder');world.Name='MergeABrainrotGenerated';world.Parent=sandbox
local plot=Instance.new('Model');plot.Name='Plot1';plot.Parent=world
local otherPlot=Instance.new('Model');otherPlot.Name='Plot2';otherPlot.Parent=world
local names={'Buy1','Buy5','Buy10','Buy100','DepositPad','CoinPad','UpgradePad','MergePad'}
local before={}
local function remember(object,properties)
    local values={}
    for _,key in properties do values[key]=object[key] end
    before[object]=values
end
local function place(part,x,y,depth)
    local viewport=camera.ViewportSize
    local focal=viewport.Y/(2*math.tan(math.rad(camera.FieldOfView)/2))
    local point=camera.CFrame:PointToWorldSpace(Vector3.new((x-viewport.X/2)*depth/focal,-(y-viewport.Y/2)*depth/focal,-depth))
    part.Position=point-part.Label.StudsOffsetWorldSpace-camera.CFrame:VectorToWorldSpace(part.Label.StudsOffset)
end
for index,name in names do
    local part=source[name]:Clone();part.Parent=plot
    assert(not part.Label.Text:FindFirstChild('PadLabelTextFit'),'Canonical source already includes a controller-owned constraint')
    part.CFrame=camera.CFrame*CFrame.new(1000+index*100,0,20)
end
local viewport=camera.ViewportSize
local spacing=math.min(120,viewport.X/4)
for index,name in {'Buy1','Buy5','UpgradePad'} do
    place(plot[name],viewport.X/2+(index-2)*spacing,viewport.Y/2,45)
end
local foreign=source.Buy1:Clone();foreign.Parent=otherPlot
for _,part in plot:GetChildren() do
    remember(part,{'CFrame','Size','CanCollide','CanQuery','CanTouch'})
    remember(part.Label,{'Size','Enabled','StudsOffset','StudsOffsetWorldSpace','MaxDistance'})
    for _,child in part.Label:GetDescendants() do
        if child:IsA('TextLabel') then remember(child,{'Size','Position','TextSize','TextScaled','TextWrapped','Font','TextColor3'})
        elseif child:IsA('UITextSizeConstraint') then remember(child,{'MinTextSize','MaxTextSize'})
        elseif child:IsA('UIStroke') then remember(child,{'Thickness'}) end
    end
end
local foreignSize,foreignEnabled=foreign.Label.Size,foreign.Label.Enabled
local controller=Controller.new(sandbox)
local ok,err=xpcall(function()
    controller:setPlot(1);controller:update(1,camera,camera.CFrame.Position)
    assert(plot.Buy1.Label.Enabled and plot.Buy1.Label.Size.X.Offset<before[plot.Buy1.Label].Size.X.Offset,'Distant fixed pixel labels should shrink')
    assert(foreign.Label.Size==foreignSize and foreign.Label.Enabled==foreignEnabled,'Only the assigned plot may change')
    local count=0
    for _ in controller.records do count+=1 end
    assert(count==8,'Cache only the eight active local pad labels')
    for _,name in names do
        local part=plot[name]
        for property,value in before[part] do assert(part[property]==value,'Interaction geometry changed: '..name..'.'..property) end
        assert(part.Label.Text.Parent==part.Label,'Keep direct world/shop update paths intact')
    end
    local price=plot.Buy1.Label.Price
    price.Text='$1,234,567'
    controller:update(1.2,camera,camera.CFrame.Position)
    assert(price.Text=='$1,234,567','Never restore or replace a live quote')
    -- Force a projected collision and approach the Buy pad.
    plot.UpgradePad.Position=plot.Buy1.Position
    controller:update(1.4,camera,plot.Buy1.Position)
    assert(plot.Buy1.Label.Enabled and plot.Buy1.Label.Size==before[plot.Buy1.Label].Size,'The nearby buy label keeps full size')
    assert(not plot.UpgradePad.Label.Enabled,'A crowded utility label must not cover the nearby buy price')
    plot.UpgradePad.CFrame=before[plot.UpgradePad].CFrame
    controller:clear()
    for object,properties in before do
        for key,value in properties do assert(object[key]==value,'Teardown failed to restore '..object.Name..'.'..key) end
    end
    assert(price.Text=='$1,234,567','Teardown must preserve the latest server/shop text')
    for _,part in plot:GetChildren() do assert(not part.Label.Text:FindFirstChild('PadLabelTextFit'),'Owned title constraints must be removed') end
    controller:setPlot(1);controller:update(2,camera,camera.CFrame.Position)
    local previous=controller
    controller=Controller.new(sandbox)
    assert(previous.destroyed and next(previous.records)==nil,'Replacement must release and restore the prior controller')
    controller:setPlot(1);controller:update(3,camera,camera.CFrame.Position)
    controller:setPlot(2);controller:update(4,camera,camera.CFrame.Position)
    assert(plot.Buy1.Label.Size==before[plot.Buy1.Label].Size,'Changing farms restores the old farm')
    controller:destroy();controller:destroy();controller:update(5,camera,camera.CFrame.Position)
    assert(foreign.Label.Size==foreignSize and foreign.Label.Enabled==foreignEnabled and next(controller.records)==nil,'Destroy must restore the new farm and release cached objects')
end,debug.traceback)
controller:destroy();sandbox:Destroy()
assert(ok,err)
return 'PASS eight active local pad labels, distance shrink, near full size, quote/hierarchy/geometry preservation and exact teardown/plot-change restoration'
