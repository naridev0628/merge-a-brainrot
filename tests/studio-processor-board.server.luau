-- Native RED/GREEN against actual World.render/clear and committed Core states.
-- Uses an unparented plot and fresh module clone; no normal session or UI changes.
-- Returns passed/failures rather than throwing the final report (Studio truncates errors).
local RunService=game:GetService('RunService')
local Http=game:GetService('HttpService')
assert(RunService:IsStudio() and RunService:IsServer(),'Studio Server required')
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Core=require(game.ServerScriptService.Domain.FarmCore)
local original=game.ServerScriptService.Services.WorldBuilder
local module=original:Clone();module.Name='ProcessorBoardFixture_'..Http:GenerateGUID(false)
local fixture=workspace.MergeABrainrotGenerated.Plot2:Clone()
fixture.Name='ProcessorBoardFixture'
local failures,metrics={},{}
local function check(condition,message)
    if not condition then table.insert(failures,message) end
end
local ok,err=xpcall(function()
    module.Parent=original.Parent
    local World=require(module)
    fixture.Producers:ClearAllChildren();fixture.Minis:ClearAllChildren();fixture.StackRows:ClearAllChildren()
    local lucky=fixture:FindFirstChild('LuckyBlock')
    if lucky then lucky:Destroy() end
    local board=fixture.ProcessorSign
    local display=board.Processor.ProcessorDisplay
    local queued,rate,title=display.Queued,display.Rate,display.Title
    local beforeParts={}
    local boardInstances=#board:GetDescendants()
    for _,item in board:GetDescendants() do
        if item:IsA('BasePart') then
            beforeParts[item]={CFrame=item.CFrame,Size=item.Size,Color=item.Color,
                CanCollide=item.CanCollide,CanQuery=item.CanQuery,CanTouch=item.CanTouch}
        end
    end
    local world={root=fixture,frame=fixture:GetPivot(),producers=fixture.Producers,tokens=fixture.Minis,
        rows=fixture.StackRows,badgePart=fixture.OwnerBadgeAnchor,ownerLabel=fixture.OwnerSign.Label.Text,
        ownerName=fixture.OwnerBadgeAnchor.OwnerBadge.Username,portrait=fixture.OwnerBadgeAnchor.OwnerBadge.Portrait,
        pads={},saleLabel=fixture.CoinPad.Label.Price,processorLabel=queued,processorRate=rate,
        upgradeLabel=fixture.UpgradePad.Label.Text,upgradePrice=fixture.UpgradePad.Label.Price}
    local core=Core.new(Config,Catalog,function() return 1 end)
    local session=core:newSession(900011,0,'processor-board-fixture')
    local function render(count,level,coins,sold)
        -- An existing row avoids shelf construction yields. Keep one actual
        -- starter producer: Core correctly rejects starterClaimed with no producer.
        if not world.rows:FindFirstChild('1') then
            local row=Instance.new('Model');row.Name='1';row.Parent=world.rows
        end
        local state=core:snapshot(session)
        state.starterClaimed=true;state.processorLevel=level;state.coinUnits=coins;state.soldUnits=sold or 0
        state.producers={{id='processor-fixture-starter',speciesId='tier_01',slot=1,due=100000}}
        state.saleQueue=if count==0 then {} else {{units=4,count=count,due=100000,interval=1/Config.ProcessorRates[level+1]}}
        assert(core:commit(session,state),'Fixture must use a valid committed state')
        World.render(world,session.state)
        return {count=count,level=level,queued=queued.Text,rate=rate.Text,
            upgrade=world.upgradeLabel.Text,price=world.upgradePrice.Text,
            affordable=fixture.UpgradePad:GetAttribute('Affordable'),cash=world.saleLabel.Text}
    end
    for _,case in {{0,'0'},{1,'1'},{96,'96'},{1000,'1,000'},{Config.SaleCapacity,'2,147,483,647'}} do
        local sample=render(case[1],0,Config.StartingUnits)
        table.insert(metrics,sample)
        check(sample.queued==case[2],'Numeric queue text mismatch at '..case[1]..': '..sample.queued)
        check(sample.rate==Config.ProcessorRates[1]..' per second','Base rate text changed')
    end
    local rich=render(1234,2,40000,400)
    table.insert(metrics,rich)
    check(rich.upgrade=='+'..(Config.ProcessorRates[4]-Config.ProcessorRates[3])..' per second'
        and rich.price=='$'..Config.ProcessorCosts[3]/4 and rich.affordable==true,'Active upgrade quote/affordability changed')
    World.clear(world)
    local clear={phase='clear',queued=queued.Text,rate=rate.Text,upgrade=world.upgradeLabel.Text,
        price=world.upgradePrice.Text,affordable=fixture.UpgradePad:GetAttribute('Affordable'),cash=world.saleLabel.Text}
    table.insert(metrics,clear)
    check(clear.queued=='0','Clear retained a departed queue: '..clear.queued)
    check(clear.rate==Config.ProcessorRates[1]..' per second','Clear retained a departed rate: '..clear.rate)
    check(clear.upgrade=='+'..(Config.ProcessorRates[2]-Config.ProcessorRates[1])..' per second'
        and clear.price=='$'..Config.ProcessorCosts[1]/4,'Clear retained a departed upgrade quote')
    check(clear.affordable==false and clear.cash=='$0','Clear must reset upgrade affordability and claim value')
    local maxed=render(96,#Config.ProcessorRates-1,40000)
    table.insert(metrics,maxed)
    check(maxed.upgrade=='PROCESSOR MAXED' and maxed.price=='' and maxed.affordable==false,'Max-level quote changed')
    World.clear(world)
    check(queued.Text=='0' and rate.Text==Config.ProcessorRates[1]..' per second','Clear from max level failed')
    check(world.upgradeLabel.Text=='+'..(Config.ProcessorRates[2]-Config.ProcessorRates[1])..' per second'
        and world.upgradePrice.Text=='$'..Config.ProcessorCosts[1]/4,'Max-level clear failed to restore the base quote')
    local nextOwner=render(1,0,Config.StartingUnits)
    table.insert(metrics,nextOwner)
    check(nextOwner.queued=='1' and nextOwner.affordable==false,'Reused plot did not show fresh state')
    check(title.Text=='Processing Minis','Board needs the short mixed-case heading')
    check(queued.TextScaled and queued:FindFirstChildWhichIsA('UITextSizeConstraint').MaxTextSize>=90,
        'Count must retain scaling with a larger font cap')
    check(queued.Size.Y.Offset>=110,'Count needs the larger existing cell')
    check(title.Position.Y.Offset+title.Size.Y.Offset<=queued.Position.Y.Offset
        and queued.Position.Y.Offset+queued.Size.Y.Offset<=rate.Position.Y.Offset
        and rate.Position.Y.Offset+rate.Size.Y.Offset<=display.CanvasSize.Y,'Board rows overlap or exceed the canvas')
    check(display.Queued==queued and display.Rate==rate and display.Title==title,'Reuse the original text instances')
    check(#board:GetDescendants()==boardInstances,'Board update added or removed Instances')
    for part,properties in beforeParts do
        check(part:IsDescendantOf(board),'Board Part was replaced')
        for key,value in properties do check(part[key]==value,'Board geometry/appearance changed: '..part.Name..'.'..key) end
    end
    check(display.SizingMode==Enum.SurfaceGuiSizingMode.FixedSize and display.CanvasSize==Vector2.new(690,300)
        and not display.AlwaysOnTop,'Keep the existing canvas and scene occlusion')
end,debug.traceback)
fixture:Destroy();module:Destroy()
if not ok then error(err) end
local result={passed=#failures==0,failures=failures,samples=metrics,
    scope='Actual renderer and clear lifecycle; native client font bounds and matched screenshots remain separate'}
return result
