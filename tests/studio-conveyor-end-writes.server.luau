-- Run through a Studio Server executor with Source access, before/after the fix.
-- Instrument only a temporary module clone; the actual renderer, Core and Models run.
-- No normal farm, player, terrain or production module is changed.
local RunService=game:GetService('RunService')
local Collection=game:GetService('CollectionService')
local Http=game:GetService('HttpService')
assert(RunService:IsStudio() and RunService:IsServer(),'Studio Server required')
local Server=game:GetService('ServerScriptService')
local Shared=game:GetService('ReplicatedStorage').Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Map=require(Shared.MapSpec)
local Core=require(Server.Domain.FarmCore)
local original=Server.Services.WorldBuilder
local source=original.Source
local instrumented,callSites=source:gsub("mini:SetAttribute%('ConveyorEnd',","__fixtureSetEnd(mini,")
assert(callSites==2,'Expected the creation and existing-token endpoint call sites')
local helper=[[
local __fixtureWrites={}
local function __fixtureSetEnd(mini,value)
    table.insert(__fixtureWrites,{id=mini.Name,parent=mini.Parent and mini.Parent.Name,
        tagged=game:GetService('CollectionService'):HasTag(mini,'ConveyorMini'),value=value})
    mini:SetAttribute('ConveyorEnd',value)
end
]]
local exported
instrumented,exported=instrumented:gsub('return World%s*$','World.__fixtureWrites=__fixtureWrites\nreturn World')
assert(exported==1,'Expected one World export')
local module=original:Clone()
module.Name='ConveyorEndWriteFixture_'..Http:GenerateGUID(false)
local fixture=Instance.new('Model')
fixture.Name='ConveyorEndWriteFixture'
local metrics={}
local function make(class,name,parent)
    local item=Instance.new(class);item.Name=name;item.Parent=parent;return item
end
local ok,err=xpcall(function()
    -- Keep the directive first. This helper exists only in the disposable clone.
    module.Source='--!strict\n'..helper..instrumented
    module.Parent=original.Parent
    local World=require(module)
    local world={root=fixture,frame=CFrame.new(250,1000,-250)*CFrame.Angles(0,.37,0),
        producers=make('Folder','Producers',fixture),tokens=make('Folder','Minis',fixture),
        rows=make('Folder','StackRows',fixture),badgePart=make('Part','OwnerBadgeAnchor',fixture),pads={},
        saleLabel=make('TextLabel','Sale',fixture),processorLabel=make('TextLabel','Queue',fixture),
        processorRate=make('TextLabel','Rate',fixture)}
    make('Model','1',world.rows) -- Existing shelf avoids a construction yield.
    local ownerSign=make('Part','OwnerSign',fixture)
    local ownerGui=make('BillboardGui','Label',ownerSign)
    world.ownerLabel=make('TextLabel','Text',ownerGui)
    local upgrade=make('Part','UpgradePad',fixture)
    local label=make('BillboardGui','Label',upgrade)
    world.upgradeLabel=make('TextLabel','Text',label)
    world.upgradePrice=make('TextLabel','Price',label)
    local config=table.clone(Config);config.LuckyChance=0
    local core=Core.new(config,Catalog,function() return 1 end)
    local session=core:newSession(998,100,'conveyor-end-fixture')
    local seeded=core:snapshot(session);seeded.starterClaimed=true
    for slot=1,6 do
        local species=string.format('tier_%02d',slot)
        seeded.producers[slot]={id=core:id(session),speciesId=species,slot=slot,due=101}
        seeded.discoveries[species]=true
    end
    assert(core:commit(session,seeded))
    assert(core:step(session,101) and #session.state.tokens==6,'Seed six actual mixed-species Minis')
    local function render(phase,newTokens)
        table.clear(World.__fixtureWrites)
        World.render(world,session.state)
        metrics[phase]=#World.__fixtureWrites
        local first={}
        for _,write in World.__fixtureWrites do
            assert(write.parent=='Minis','Endpoint initialization must preserve parent timing')
            if not first[write.id] then
                first[write.id]=write
                assert(write.tagged~=newTokens,'New endpoints must precede tags; existing tokens stay tagged')
            end
        end
        for _,token in session.state.tokens do
            local mini=assert(world.tokens:FindFirstChild(token.id),'Missing rendered Mini')
            local expected=world.frame:PointToWorldSpace(Vector3.new(token.x,token.y,token.z)*Map.PlotScale)
            assert((mini:GetAttribute('ConveyorEnd')-expected).Magnitude<.0001,'Endpoint must follow scaled authoritative resting center')
            assert(Collection:HasTag(mini,'ConveyorMini'),'Rendered Mini must keep its tag')
            assert(mini:GetAttribute('PlotScale')==Map.PlotScale,'Creation scale must remain unchanged')
            assert(first[token.id] and (first[token.id].value-expected).Magnitude<.0001,'Every rendered token needs one authoritative endpoint update')
        end
    end
    render('create',true)
    local identities={}
    for _,mini in world.tokens:GetChildren() do identities[mini.Name]=mini end
    render('unchanged',false)
    for id,mini in identities do assert(world.tokens:FindFirstChild(id)==mini,'Unchanged render must retain identity') end

    local state=core:snapshot(session)
    local removed=table.remove(state.tokens,1)
    local survivor=identities[state.tokens[1].id]
    local previous=survivor:GetAttribute('ConveyorEnd')
    assert(core:commit(session,state),'Commit actual Core pile repack')
    render('repack',false)
    assert(identities[removed.id].Parent==nil and not world.tokens:FindFirstChild(removed.id),'Removed Mini must leave the rendered world')
    assert((survivor:GetAttribute('ConveyorEnd')-previous).Magnitude>.01,'Surviving Mini must move to its repacked center')
    for _,token in session.state.tokens do assert(world.tokens:FindFirstChild(token.id)==identities[token.id],'Repack must update existing models') end

    state=core:snapshot(session);state.tokens={}
    assert(core:commit(session,state))
    render('remove',false)
    assert(#world.tokens:GetChildren()==0,'Empty state must remove every Mini')
    assert(core:step(session,102) and #session.state.tokens==6,'Produce six replacement Minis')
    render('recreate',true)
    -- Baseline reaches every phase before the redundant-call assertion fails.
    assert(metrics.create==6 and metrics.recreate==6,'New Minis need one endpoint setter/point conversion each, not two: '..Http:JSONEncode(metrics))
    assert(metrics.unchanged==6 and metrics.repack==5 and metrics.remove==0,'Existing and removal write counts must be preserved')
end,debug.traceback)
fixture:Destroy()
module:Destroy()
print('ConveyorEndWriteRegression '..Http:JSONEncode(metrics))
assert(ok,err)
return {result='PASS endpoint call counts, before-tag/parent initialization, unchanged identity, Core repack, removal and recreation',writes=metrics}
