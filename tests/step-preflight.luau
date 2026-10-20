local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')
local Scenario=require('./CapacityHarnessScenario')

-- Generalized iteration observes recursive state copying without replacing any
-- domain method. An idle tick must not enumerate/copy the state root at all.
local function observeCopies(session)
    local copies=0
    setmetatable(session.state,{__iter=function(value)
        copies+=1
        return next,value
    end})
    return function() return copies end
end
local function unchanged(core,session,now)
    local state,sequence,cursor=session.state,session.sequence,session.productionCursor
    local copies=observeCopies(session)
    assert(not core:step(session,now),'A quiet tick must report no change')
    assert(session.state==state and session.sequence==sequence and session.productionCursor==cursor,
        'A quiet tick must preserve state identity, IDs and production order')
    assert(copies()==0,'A quiet tick must return before copying the full farm state')
end
local function commit(core,session,edit)
    local state=core:snapshot(session)
    edit(state)
    assert(core:commit(session,state))
end

local full=Scenario.new(Core,Config,Catalog,96,100)
for _,session in full.sessions do
    for _,now in {100.25,100.5,100.75} do unchanged(full.core,session,now) end
end

-- Due production is real work even when either physical cap blocks every drop.
-- Raw production and Lucky rolls must retain their original due-time order.
for _,limit in {'global','origin'} do
    local config=table.clone(Config)
    config.GroundCap=if limit=='global' then 1 else 96
    config.GroundPerProducer=if limit=='origin' then 1 else 8
    config.LuckyChance=.5
    local rolls=0
    local core=Core.new(config,Catalog,function() rolls+=1;return if rolls==1 then 1 else 0 end)
    local session=core:newSession(1,0,'capped-'..limit)
    commit(core,session,function(state)
        state.starterClaimed=true
        state.producers={{id=core:id(session),speciesId='tier_01',slot=1,due=1}}
    end)
    unchanged(core,session,.75)
    assert(rolls==0,'Never touch RNG before a producer is due')
    assert(core:step(session,1) and #session.state.tokens==1 and rolls==1)
    commit(core,session,function(state) state.eventHundredths=50 end)
    unchanged(core,session,1.75)
    assert(rolls==1)
    assert(core:step(session,2),'A capped producer must still perform its raw-production Lucky roll')
    assert(session.state.producers[1].productionCredit==0 and session.state.producers[1].due==3 and rolls==2)
    unchanged(core,session,2.75)
    assert(core:step(session,3),'A capped drop must still perform its Lucky roll')
    assert(#session.state.tokens==1 and session.state.lucky and rolls==2)
    assert(session.state.producers[1].productionCredit==0 and session.state.producers[1].due==4)
    assert(core:step(session,100) and #session.state.tokens==1)
    assert(session.state.producers[1].due==101,'Late capped ticks must not queue hidden work')
end

local core=Core.new(Config,Catalog,function() error('Sales and pickups must not roll Lucky') end)
local sales=core:newSession(2,0,'sales')
commit(core,sales,function(state)
    state.saleQueue={{units=8,count=3,due=10,interval=.5}}
end)
unchanged(core,sales,9.999)
assert(core:step(sales,10) and sales.state.soldUnits==8)
assert(sales.state.saleQueue[1].count==2 and sales.state.saleQueue[1].due==10.5)
unchanged(core,sales,10.25)
assert(core:step(sales,10.5) and sales.state.soldUnits==16)
commit(core,sales,function(state) state.autoSell=true end)
local coins=sales.state.coinUnits
assert(core:step(sales,10.6),'An existing sold balance must wake Auto Sell before the next sale')
assert(sales.state.coinUnits==coins+16 and sales.state.soldUnits==0)
unchanged(core,sales,10.75)
assert(core:step(sales,11) and #sales.state.saleQueue==0 and sales.state.coinUnits==coins+24)
unchanged(core,sales,12)

-- Auto Collect also deposits an existing bag, independently of ready tokens.
local bag=core:newSession(3,0,'bag')
commit(core,bag,function(state)
    state.autoCollect=true
    state.bag={{speciesId='tier_01',baseCoinValue=2,count=2}}
end)
assert(core:step(bag,20) and #bag.state.bag==0 and Economy.count(bag.state.saleQueue)==2)
unchanged(core,bag,20.25)

local collect=full.sessions[1]
commit(full.core,collect,function(state)
    state.autoCollect=true
    for _,producer in state.producers do producer.due=200 end
    for _,token in state.tokens do token.readyAt=105 end
end)
local collectedQuantity=Economy.count(collect.state.tokens)
unchanged(full.core,collect,104.999)
assert(full.core:step(collect,105),'Ready tokens must wake Auto Collect without due production')
assert(#collect.state.tokens==0 and #collect.state.bag==0 and Economy.count(collect.state.saleQueue)==collectedQuantity)

-- A conservative guard may enter the old path for work that turns out blocked.
-- Once a later state/quote permits it, that work must be retried immediately.
local blockedConfig=table.clone(Config);blockedConfig.SaleCapacity=1
local blockedCore=Core.new(blockedConfig,Catalog,function() error('Unexpected RNG') end)
local blocked=blockedCore:newSession(4,0,'blocked')
commit(blockedCore,blocked,function(state)
    state.autoCollect=true
    state.bag={{speciesId='tier_01',baseCoinValue=2,count=1}}
    state.saleQueue={{units=8,count=1,due=30,interval=.5}}
end)
assert(not blockedCore:step(blocked,29) and Economy.count(blocked.state.bag)==1)
assert(blockedCore:step(blocked,30) and #blocked.state.bag==0 and Economy.count(blocked.state.saleQueue)==1)

local invalid=core:newSession(5,0,'invalid')
for _,now in {math.huge,-math.huge,0/0} do unchanged(core,invalid,now) end
invalid.phase='Closing'
unchanged(core,invalid,1)
print('PASS step preflight avoids idle copies and preserves sales, Auto Collect/Sell, capped production, Lucky RNG and due boundaries')
