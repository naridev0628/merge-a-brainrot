-- Disposable whole-plot visual context, using only the currently installed
-- WorldBuilder and current plot UI. Run before sync, destroy/restart, run after.
-- _G.ProcessorBoardPreview.setCount(0|1|96|1000|2147483647, optionalLevel),
-- inspect(), destroy(). Camera/player/HUD remain root-controlled.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsServer(),'Studio Server required')
assert(not _G.ProcessorBoardPreview,'Destroy the earlier processor preview first')
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Map=require(Shared.MapSpec)
local Core=require(game.ServerScriptService.Domain.FarmCore)
local original=game.ServerScriptService.Services.WorldBuilder
local module=original:Clone();module.Name='ProcessorPreviewWorld'
local clone=workspace.MergeABrainrotGenerated.Plot2:Clone();clone.Name='ProcessorBoardPreview'
local active=true
local api={}
local world,session,core,World,board,display
local partBefore={}
local boardInstanceCount=0
local revision=0
local function xyz(vector)
    return {vector.X,vector.Y,vector.Z}
end
function api.destroy()
    if not active then return end
    active=false;clone:Destroy();module:Destroy();table.clear(partBefore)
    if _G.ProcessorBoardPreview==api then _G.ProcessorBoardPreview=nil end
end
local function checked(callback)
    local ok,result=xpcall(callback,debug.traceback)
    if not ok then api.destroy();error(result) end
    return result
end
function api.inspect()
    assert(active,'Preview has been destroyed')
    if boardInstanceCount>0 then
        assert(#board:GetDescendants()==boardInstanceCount,'Count update added/removed board Instances')
        for part,before in partBefore do
            assert(part:IsDescendantOf(board),'Count update replaced a board Part')
            for key,value in before do assert(part[key]==value,'Count update changed geometry: '..key) end
        end
    end
    local face=display.Adornee
    local center=face.Position
    return {count=clone:GetAttribute('PreviewCount'),level=session.state.processorLevel,revision=revision,
        title=display.Title.Text,queued=display.Queued.Text,rate=display.Rate.Text,
        countCell={display.Queued.Size.X.Offset,display.Queued.Size.Y.Offset},
        countFontCap=display.Queued:FindFirstChildWhichIsA('UITextSizeConstraint').MaxTextSize,
        maxDistance=display.MaxDistance,sourceBytes=#original.Source,
        canvas={display.CanvasSize.X,display.CanvasSize.Y},
        boardInstances=boardInstanceCount,
        cameraHints={
            close={position=xyz(center+face.CFrame.LookVector*20+Vector3.new(0,1.5,0)),lookAt=xyz(center)},
            approach={position=xyz(world.frame:PointToWorldSpace(Vector3.new(0,7,20)*Map.PlotScale)),lookAt=xyz(center)},
        },
        scope='Current native source/UI only; rerun after fresh-world sync for a matched comparison'}
end
function api.setCount(count,level)
    assert(active and type(count)=='number' and count%1==0 and count>=0 and count<=Config.SaleCapacity,'Use an integer within SaleCapacity')
    local processorLevel=level or 0
    assert(type(processorLevel)=='number' and processorLevel%1==0 and processorLevel>=0
        and processorLevel<#Config.ProcessorRates,'Unknown processor level')
    return checked(function()
        clone:SetAttribute('Ready',false)
        local state=core:snapshot(session)
        state.starterClaimed=true;state.processorLevel=processorLevel
        state.producers={{id='processor-preview-starter',speciesId='tier_01',slot=1,due=100000}}
        state.saleQueue=if count==0 then {} else {{units=4,count=count,due=100000,interval=1/Config.ProcessorRates[processorLevel+1]}}
        assert(core:commit(session,state),'Preview seed must be a valid Core state')
        World.render(world,session.state)
        revision+=1
        clone:SetAttribute('PreviewCount',count);clone:SetAttribute('PreviewLevel',processorLevel)
        clone:SetAttribute('PreviewQueueText',display.Queued.Text);clone:SetAttribute('PreviewRateText',display.Rate.Text)
        clone:SetAttribute('PreviewRevision',revision);clone:SetAttribute('Ready',true)
        return api.inspect()
    end)
end
local result=checked(function()
    module.Parent=original.Parent
    World=require(module)
    clone.Producers:ClearAllChildren();clone.Minis:ClearAllChildren();clone.StackRows:ClearAllChildren()
    for _,item in clone:GetDescendants() do
        if item:IsA('SpawnLocation') or item:IsA('LuaSourceContainer') then item:Destroy() end
    end
    local lucky=clone:FindFirstChild('LuckyBlock')
    if lucky then lucky:Destroy() end
    clone:PivotTo(CFrame.new(0,2000,0))
    board=clone.ProcessorSign;display=board.Processor.ProcessorDisplay
    world={root=clone,frame=clone:GetPivot(),producers=clone.Producers,tokens=clone.Minis,
        rows=clone.StackRows,badgePart=clone.OwnerBadgeAnchor,ownerLabel=clone.OwnerSign.Label.Text,
        ownerName=clone.OwnerBadgeAnchor.OwnerBadge.Username,portrait=clone.OwnerBadgeAnchor.OwnerBadge.Portrait,
        pads={},saleLabel=clone.CoinPad.Label.Price,processorLabel=display.Queued,processorRate=display.Rate,
        upgradeLabel=clone.UpgradePad.Label.Text,upgradePrice=clone.UpgradePad.Label.Price}
    core=Core.new(Config,Catalog,function() return 1 end)
    session=core:newSession(900012,0,'processor-preview')
    api.setCount(0)
    boardInstanceCount=#board:GetDescendants()
    for _,item in board:GetDescendants() do
        if item:IsA('BasePart') then
            partBefore[item]={CFrame=item.CFrame,Size=item.Size,Color=item.Color,
                CanCollide=item.CanCollide,CanQuery=item.CanQuery,CanTouch=item.CanTouch}
        end
    end
    clone.Parent=workspace
    return api.inspect()
end)
_G.ProcessorBoardPreview=api
task.delay(300,api.destroy)
return result
