-- Run in a Studio Server executor with Source access. Only an unparented plot
-- and a temporary module clone are used; normal farms and production Source stay intact.
local RunService=game:GetService('RunService')
local Http=game:GetService('HttpService')
assert(RunService:IsStudio() and RunService:IsServer(),'Studio Server required')
local Server=game:GetService('ServerScriptService')
local Shared=game:GetService('ReplicatedStorage').Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Economy=require(Shared.Economy)
local Core=require(Server.Domain.FarmCore)
local original=Server.Services.WorldBuilder
local instrumented,sites=original.Source:gsub('([%w_%.]+):GetChildren%(%)','__fixtureGetChildren(%1)')
assert(sites>=4,'Expected actual renderer child enumerations')
local helper=[[
local __fixtureStats={root=nil,scans=0,visits=0}
local function __fixtureGetChildren(parent)
    local children=parent:GetChildren()
    if parent==__fixtureStats.root then
        __fixtureStats.scans+=1
        __fixtureStats.visits+=#children
    end
    return children
end
]]
local exports
instrumented,exports=instrumented:gsub('return World%s*$','World.__fixtureStats=__fixtureStats\nreturn World')
assert(exports==1,'Expected one World export')
local module=original:Clone()
module.Name='PadPieceIndexFixture_'..Http:GenerateGUID(false)
local fixture=workspace.MergeABrainrotGenerated.Plot2:Clone()
fixture.Name='PadPieceIndexFixture'
local metrics={}
local stats
local quantities={'1','5','10','50'}
local function close(a,b)
    return math.abs(a.R-b.R)<=1/255 and math.abs(a.G-b.G)<=1/255 and math.abs(a.B-b.B)<=1/255
end
local function makeRow(rows)
    local row=Instance.new('Model');row.Name='1';row.Parent=rows
end
local ok,err=xpcall(function()
    module.Source='--!strict\n'..helper..instrumented
    module.Parent=original.Parent
    local World=require(module)
    stats=World.__fixtureStats
    stats.root=fixture
    fixture.Producers:ClearAllChildren()
    fixture.Minis:ClearAllChildren()
    fixture.StackRows:ClearAllChildren()
    makeRow(fixture.StackRows) -- No render yields or producer/asset work in this fixture.
    local world={root=fixture,frame=fixture:GetPivot(),producers=fixture.Producers,tokens=fixture.Minis,
        rows=fixture.StackRows,badgePart=fixture.OwnerBadgeAnchor,ownerLabel=fixture.OwnerSign.Label.Text,
        ownerName=fixture.OwnerBadgeAnchor.OwnerBadge.Username,portrait=fixture.OwnerBadgeAnchor.OwnerBadge.Portrait,
        pads={},saleLabel={},processorLabel={},processorRate={},
        upgradeLabel=fixture.UpgradePad.Label.Text,upgradePrice=fixture.UpgradePad.Label.Price}
    for _,q in quantities do
        world.pads[q]=fixture['Buy'..q].Label.Text
        fixture['Buy'..q]:SetAttribute('Affordable',nil)
    end
    fixture.UpgradePad:SetAttribute('Affordable',nil)
    local unrelated=fixture.Buy1Base
    local unrelatedColor=unrelated.Color
    local core=Core.new(Config,Catalog)
    local state=core:newSession(999,0,'pad-index-test').state
    state.starterClaimed=true;state.purchased=58;state.rebirths=1
    local function expected()
        local result={}
        for _,q in quantities do
            result['Buy'..q]=state.rebirths>=Config.BuyUnlocks[q]
                and state.coinUnits>=Economy.buyCost(state.purchased,tonumber(q),1)
        end
        local cost=Config.ProcessorCosts[state.processorLevel+1]
        result.UpgradePad=cost~=nil and state.coinUnits>=cost
        return result
    end
    local function check(name,affordable)
        local part=fixture[name]
        assert(part:GetAttribute('Affordable')==affordable,name..' has stale affordability')
        local color=if affordable then Color3.fromRGB(96,238,43) else Color3.fromRGB(244,90,94)
        assert(close(part.Color,color),name..' surface has stale color')
        for _,detail in fixture:GetChildren() do
            if detail:IsA('BasePart') then
                if detail.Name==name..'Stud' then
                    assert(close(detail.Color,color:Lerp(Color3.new(1,1,1),.12)),name..' stud has stale color')
                elseif detail.Name==name..'Edge' then
                    assert(close(detail.Color,color:Lerp(Color3.new(1,1,1),.3)),name..' edge has stale color')
                end
            end
        end
    end
    local function render(phase,skipDetails)
        local record=metrics[phase]
        if not record then
            record={renders=0,changedRenders=0,changedPads=0,scans=0,visits=0,maxScans=0,expectedVisits=0}
            metrics[phase]=record
        end
        local wants=expected()
        local changed=0
        for name,affordable in wants do
            if fixture[name]:GetAttribute('Affordable')~=affordable then changed+=1 end
        end
        stats.scans=0;stats.visits=0
        World.render(world,state)
        record.renders+=1;record.scans+=stats.scans;record.visits+=stats.visits
        record.changedPads+=changed
        record.maxScans=math.max(record.maxScans,stats.scans)
        if changed>0 then
            record.changedRenders+=1
            record.expectedVisits+=#fixture:GetChildren()
        end
        for name,affordable in wants do
            if not skipDetails or not skipDetails[name] then check(name,affordable)
            else assert(fixture[name]:GetAttribute('Affordable')==affordable,'Skipped unchanged pad state') end
        end
        assert(unrelated.Color==unrelatedColor,'Unrelated pad base must not change')
    end
    -- Preserve the existing native affordability fixture's 26 threshold/unlock/upgrade renders.
    for _,q in quantities do
        local cost=Economy.buyCost(state.purchased,tonumber(q),1)
        for _,balance in {cost-1,cost,cost+1,0,cost} do
            state.coinUnits=balance;render('thresholds')
        end
    end
    state.coinUnits=400000;state.rebirths=0;render('thresholds')
    state.rebirths=1;render('thresholds')
    for _,balance in {Config.ProcessorCosts[1]-1,Config.ProcessorCosts[1],0} do
        state.coinUnits=balance;render('thresholds')
    end
    state.processorLevel=#Config.ProcessorCosts;render('thresholds')
    for _=1,100 do render('unchanged') end

    state.processorLevel=0;state.coinUnits=400000;render('rich')
    local sentinel=Color3.fromRGB(153,24,201)
    local oldStud=assert(fixture:FindFirstChild('Buy1Stud'))
    local replacement=oldStud:Clone();replacement.Color=sentinel;replacement.Parent=fixture;oldStud:Destroy()
    local added=fixture.Buy5Stud:Clone();added.Color=sentinel;added.Parent=fixture
    local renamed=fixture.Buy10Edge;renamed.Name='Buy50Edge';renamed.Color=sentinel
    local nonPart=Instance.new('Folder');nonPart.Name='Buy50Stud';nonPart.Parent=fixture
    state.coinUnits=Economy.buyCost(state.purchased,10,1)
    render('renamed',{Buy1=true,Buy5=true})
    assert(replacement.Color==sentinel and added.Color==sentinel,
        'Unchanged affordability must not recolor replaced or newly added pieces')
    state.coinUnits=0;render('replacedDetails')
    assert(replacement.Parent==fixture and added.Parent==fixture,'Current details must remain intact')

    local oldPad=fixture.Buy1
    local newPad=oldPad:Clone();newPad:SetAttribute('Affordable',nil);newPad.Color=sentinel
    newPad.Parent=fixture;oldPad:Destroy();world.pads['1']=newPad.Label.Text
    state.coinUnits=Economy.buyCost(state.purchased,1,1);render('replacedPad')
    World.clear(world)
    makeRow(world.rows)
    state=core:newSession(1000,0,'pad-index-new-owner').state
    state.starterClaimed=true;state.coinUnits=0
    local afterClear=fixture.Buy1Edge:Clone();afterClear.Color=sentinel;afterClear.Parent=fixture
    render('clearedNewState')
    assert(fixture.Buy1==newPad and close(afterClear.Color,Color3.fromRGB(244,90,94):Lerp(Color3.new(1,1,1),.3)),
        'Clear/new state must use current pad and detail identities')

    -- All real behavior checks run before the baseline's expected optimization failure.
    assert(metrics.thresholds.renders==26,'Expected complete threshold scenario')
    assert(metrics.unchanged.scans==0 and metrics.unchanged.visits==0,'Idle renders must never scan pad pieces')
    for phase,record in metrics do
        assert(record.scans==record.changedRenders and record.maxScans<=1 and record.visits==record.expectedVisits,
            phase..' needs at most one lazy root scan per changed render: '..Http:JSONEncode(metrics))
    end
end,debug.traceback)
if stats then stats.root=nil end
fixture:Destroy()
module:Destroy()
print('PadPieceIndexRegression '..Http:JSONEncode(metrics))
assert(ok,err)
return {result='PASS actual render thresholds, idle scans, renamed/replaced details and pads, clear/new state, colors and isolation',metrics=metrics}
