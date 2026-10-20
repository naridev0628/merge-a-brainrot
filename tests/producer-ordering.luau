local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')
local LuckyRewards=require('../src/shared/LuckyRewards')
local MiniMotion=require('../src/shared/MiniMotion')
local core=Core.new(Config,Catalog,function() return .5 end)
local function seed()
    local s=core:newSession(73,0,'ordered')
    local state=core:snapshot(s)
    state.starterClaimed=true;state.coinUnits=1000000000
    state.producers={
        {id='low-first',speciesId='tier_01',slot=1,due=100,productionCredit=17},
        {id='high-first',speciesId='tier_09',slot=2,due=101,productionCredit=29},
        {id='middle',speciesId='tier_07',slot=3,due=102,productionCredit=43},
        {id='high-second',speciesId='tier_09',slot=4,due=103,productionCredit=61},
        {id='low-second',speciesId='tier_01',slot=5,due=104,productionCredit=83},
        {id='low-third',speciesId='tier_01',slot=6,due=105,productionCredit=0},
        {id='high-third',speciesId='tier_09',slot=7,due=106,productionCredit=0},
    }
    for _,p in state.producers do state.discoveries[p.speciesId]=true end
    -- An already airborne bundle retains its source even when that producer moves.
    local source=core:slotPosition(1)
    state.tokens={{id='old-flight',owner=s.owner,origin='low-first',speciesId='tier_01',baseCoinValue=1,count=7,
        x=0,y=1,z=Config.TrayZ,startX=source.x,startY=source.y+1,startZ=source.z-2,spawnedAt=0,readyAt=4}}
    assert(core:commit(s,state),'Valid restored state should commit')
    return s
end
local function ordered(s)
    local bySlot={}
    for _,p in s.state.producers do assert(not bySlot[p.slot]);bySlot[p.slot]=p end
    local previous=math.huge
    for slot=1,#s.state.producers do
        local p=assert(bySlot[slot],'Slots must stay packed')
        local tier=Catalog[p.speciesId].tier
        assert(tier<=previous,'Every shelf must descend from highest tier on the left')
        previous=tier
        if slot%Config.Columns~=1 then
            assert(core:slotPosition(slot-1).x>core:slotPosition(slot).x,'Slot order must run viewer-left to viewer-right')
        end
    end
    return bySlot
end
local function same(a,b)
    for k,v in a do assert(b[k]==v,'Unrelated field changed: '..k) end
    for k in b do assert(a[k]~=nil,'Unexpected field appeared: '..k) end
end
local function weight(s)
    local total=0;for _,p in s.state.producers do total+=3^(Catalog[p.speciesId].tier-1) end
    return total
end
local function command(s,action,args,x,z,now)
    return core:dispatch(s,action,args,{now=now or 1,alive=true,position={x=x or Config.MergeX,y=0,z=z or Config.MergeZ}})
end
local s=seed()
local slots=ordered(s)
assert(slots[1].id=='high-first' and slots[2].id=='high-second','Equal tiers retain their previous relative slots')
assert(slots[5].id=='low-first' and slots[6].id=='low-second')
local ids,fields={},{}
for _,p in s.state.producers do ids[#ids+1]=p.id;fields[p.id]={due=p.due,productionCredit=p.productionCredit,speciesId=p.speciesId} end
s.productionCursor=3
local originalToken=table.clone(s.state.tokens[1])
for _=1,5 do
    local candidate=core:snapshot(s)
    assert(core:commit(s,candidate));ordered(s)
    assert(s.productionCursor==3,'Visual ordering must not move the production scheduler cursor')
    for i,p in s.state.producers do
        assert(p.id==ids[i],'Producer storage order must remain stable for scheduling')
        same(fields[p.id],{due=p.due,productionCredit=p.productionCredit,speciesId=p.speciesId})
    end
    same(originalToken,s.state.tokens[1])
end
-- Buying appends new lower tiers after existing matching tiers; no counts vanish.
local beforeCount,beforeWeight=#s.state.producers,weight(s)
local bought=command(s,'Buy',{'buy-five','5'},Config.BuyPads['5'],Config.BuyZ)
assert(bought.code=='OK' and #s.state.producers==beforeCount+5 and weight(s)==beforeWeight+5)
slots=ordered(s);assert(slots[5].id=='low-first' and slots[6].id=='low-second')
same(originalToken,s.state.tokens[1])
-- A direct merge moves its higher output left without altering surviving production.
local merged=command(s,'Merge',{'merge-three','low-first','low-second','low-third'})
assert(merged.code=='OK' and #s.state.producers==beforeCount+3 and weight(s)==beforeWeight+5)
slots=ordered(s);assert(slots[5].speciesId=='tier_02')
same(originalToken,s.state.tokens[1])
-- The consumed producer's Mini still follows its original flight and is collectible.
local point=MiniMotion.position(Config,s.state.tokens[1],5)
local collected=core:dispatch(s,'Collect',{'old-flight'},{now=5,alive=true,position=point})
assert(collected.code=='OK' and collected.count==7 and Economy.count(s.state.bag)==7 and #s.state.tokens==0)
ordered(s)
-- Automatic chain merges preserve represented Brainrots and leave sorted shelves.
local auto=seed();local mass=weight(auto)
local result=command(auto,'AutoMerge',{'merge-all'})
assert(result.code=='OK' and result.count==2 and #auto.state.producers==3 and weight(auto)==mass)
slots=ordered(auto);assert(slots[1].speciesId=='tier_10' and slots[3].speciesId=='tier_02')
same(originalToken,auto.state.tokens[1])
-- A Lucky reward sorts into the left edge, charging the same quote and preserving bag.
auto.state.lucky={id='reward',baseTier=12,held=true}
local coins=auto.state.coinUnits;local price=LuckyRewards.cost(Config,auto.state);local count=#auto.state.producers
local reward=command(auto,'OpenLucky',{'open','reward',tostring(price)})
assert(reward.code=='OK' and reward.speciesId=='tier_12' and auto.state.coinUnits==coins-price and #auto.state.producers==count+1)
assert(ordered(auto)[1].speciesId=='tier_12')
same(originalToken,auto.state.tokens[1])
-- Newly emitted bundles use the new producer slot; old bundles retain their source.
local production=seed()
assert(core:step(production,110))
ordered(production)
local producers={};for _,p in production.state.producers do producers[p.id]=p end
for _,token in production.state.tokens do
    if token.id=='old-flight' then same(originalToken,token)
    else
        local pos=core:slotPosition(producers[token.origin].slot)
        assert(token.startX==pos.x and token.startY==pos.y+1 and token.startZ==pos.z-2)
        assert(token.count==Catalog[token.speciesId].production)
    end
end
-- Invalid loads are rejected before normalization can hide duplicate slot errors.
local invalid=core:snapshot(production);invalid.producers[2].slot=invalid.producers[1].slot
local revision=production.state.revision
assert(not core:commit(production,invalid) and production.state.revision==revision)
print('PASS descending stable producer slots across restored states, purchases, manual/automatic merges, Lucky, production and old-source pickups')
