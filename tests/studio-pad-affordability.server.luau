-- Run after the generated world is ready. The fixture is unparented and destroyed.
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Economy=require(Shared.Economy)
local Catalog=require(Shared.CreatureCatalog)
local Core=require(game.ServerScriptService.Domain.FarmCore)
local World=require(game.ServerScriptService.Services.WorldBuilder)
local fixture=workspace.MergeABrainrotGenerated.Plot2:Clone()
local world={root=fixture,frame=fixture:GetPivot(),producers=fixture.Producers,tokens=fixture.Minis,rows=fixture.StackRows,
    badgePart=fixture.OwnerBadgeAnchor,pads={},saleLabel={},processorLabel={},processorRate={},
    upgradeLabel=fixture.UpgradePad.Label.Text,upgradePrice=fixture.UpgradePad.Label.Price}
for _,q in {'1','5','10','50'} do world.pads[q]=fixture['Buy'..q].Label.Text end
local state=Core.new(Config,Catalog):newSession(999,0,'pad-test').state
state.starterClaimed=true;state.purchased=58;state.rebirths=1
local function check(name,affordable)
    local part=fixture[name]
    assert(part:GetAttribute('Affordable')==affordable,name..' has stale affordability')
    local c=if affordable then Color3.fromRGB(96,238,43) else Color3.fromRGB(244,90,94)
    local function close(a,b) return math.abs(a.R-b.R)<=1/255 and math.abs(a.G-b.G)<=1/255 and math.abs(a.B-b.B)<=1/255 end
    assert(close(part.Color,c),name..' surface has stale color')
    for _,detail in fixture:GetChildren() do
        if detail.Name==name..'Stud' then assert(close(detail.Color,c:Lerp(Color3.new(1,1,1),.12)),name..' studs have stale color')
        elseif detail.Name==name..'Edge' then assert(close(detail.Color,c:Lerp(Color3.new(1,1,1),.3)),name..' trim has stale color') end
    end
end
local ok,err=pcall(function()
    for _,q in {'1','5','10','50'} do
        local cost=Economy.buyCost(state.purchased,tonumber(q),1)
        for _,balance in {cost-1,cost,cost+1,0,cost} do
            state.coinUnits=balance;World.render(world,state)
            check('Buy'..q,balance>=cost)
        end
    end
    state.coinUnits=400000;state.rebirths=0;World.render(world,state);check('Buy50',false)
    state.rebirths=1;World.render(world,state);check('Buy50',true)
    for _,balance in {Config.ProcessorCosts[1]-1,Config.ProcessorCosts[1],0} do
        state.coinUnits=balance;World.render(world,state);check('UpgradePad',balance>=Config.ProcessorCosts[1])
    end
    state.processorLevel=#Config.ProcessorCosts;World.render(world,state);check('UpgradePad',false)
end)
fixture:Destroy()
assert(ok,err)
print('PASS live renderer: Buy 1/5/10/50 threshold crossings, studs, trim, unlock and upgrade colors')
