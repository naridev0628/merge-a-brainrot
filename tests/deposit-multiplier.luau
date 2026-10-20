local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')
local Info=require('../src/shared/ProductionInfo')
local Packet=require('../src/server/Domain/SnapshotPacket')
local function fixture(overrides)
    local config=table.clone(Config);for k,v in overrides or {} do config[k]=v end
    local core=Core.new(config,Catalog,function() return 1 end)
    local s=core:newSession(1,0,'deposit')
    assert(core:dispatch(s,'Buy',{'starter','1'},{now=0,alive=true,position={x=config.BuyPads['1'],y=0,z=config.BuyZ}}).code=='OK')
    return core,s,config
end
local function bag(s,count,value)
    s.state.bag={{speciesId='tier_01',baseCoinValue=value or 1,count=count}}
end
local function deposit(core,s,key,now)
    return core:dispatch(s,'Deposit',{key},{now=now or 0,alive=true,position={x=core.config.SellX,y=0,z=core.config.SellZ}})
end
local core,s=fixture();core:setEvent(s,106);bag(s,5280)
local original=s.state
local quote=Economy.depositQuote(Config,s.state)
assert(quote.code=='OK' and quote.inputCount==5280 and quote.depositedCount==5596 and quote.multiplierHundredths==106 and quote.nextCarry==80)
assert(s.state==original and s.state.bag[1].count==5280 and (s.state.depositCarry or 0)==0,'Quoting must not mutate input or carried fractions')
local result=deposit(core,s,'large')
assert(result.code=='OK' and result.inputCount==5280 and result.depositedCount==5596 and result.multiplierHundredths==106)
assert(Economy.count(s.state.bag)==0 and Economy.count(s.state.saleQueue)==5596 and s.state.depositCarry==80)
local revision=s.state.revision
local replay=deposit(core,s,'large')
assert(replay.replayed and replay.depositedCount==5596 and s.state.revision==revision and s.state.depositCarry==80)
assert(replay.inputCount==5280 and replay.multiplierHundredths==106,'Cached response preserves all authoritative deposit fields')
local saved=core:snapshot(s)
local packet=Packet.build(s,{id=1,frame='test'},0,nil)
assert(saved.depositCarry==80 and packet.depositCarry==80,'Transaction and wire snapshots preserve fractional carry')
packet.depositCarry=0
assert(s.state.depositCarry==80,'Outbound root edits must not alter authoritative carry')
local restored=core:newSession(s.owner,0,'restored')
assert(core:commit(restored,saved),'A saved state with fractional carry must load successfully')
bag(restored,1)
assert(deposit(core,restored,'after-load').depositedCount==1 and restored.state.depositCarry==86)
assert(saved.depositCarry==80 and s.state.depositCarry==80,'Restored transactions must not mutate previous snapshots')
-- Fractions survive deposits and multiplier changes rather than rounding away.
local half,hs=fixture();half:setEvent(hs,50)
bag(hs,1);assert(deposit(half,hs,'half-one').depositedCount==0 and hs.state.depositCarry==50 and #hs.state.saleQueue==0)
bag(hs,1);assert(deposit(half,hs,'half-two').depositedCount==1 and hs.state.depositCarry==0)
bag(hs,1);deposit(half,hs,'half-three');half:setEvent(hs,106)
bag(hs,9);assert(deposit(half,hs,'changed').depositedCount==10 and hs.state.depositCarry==4)
local maximum,ms=fixture();maximum:setEvent(ms,150);maximum:setObbyBonus(ms,100)
bag(ms,3);assert(deposit(maximum,ms,'max-one').depositedCount==7 and ms.state.depositCarry==50)
bag(ms,3);assert(deposit(maximum,ms,'max-two').depositedCount==8 and ms.state.depositCarry==0)
assert(Economy.count(ms.state.saleQueue)==15)
-- Each expanded species group keeps its own per-Mini cash value.
local mixed,mix=fixture();mixed:setEvent(mix,150);mix.state.rebirths=2;mixed:setPasses(mix,{cash4=true})
mix.state.bag={{speciesId='tier_01',baseCoinValue=2,count=3},{speciesId='tier_02',baseCoinValue=7,count=2}}
quote=Economy.depositQuote(Config,mix.state)
assert(quote.goods[1].speciesId=='tier_01' and quote.goods[1].baseCoinValue==2 and quote.goods[1].count==4)
assert(quote.goods[2].speciesId=='tier_02' and quote.goods[2].baseCoinValue==7 and quote.goods[2].count==3)
assert(deposit(mixed,mix,'mixed').depositedCount==7 and mix.state.depositCarry==50)
assert(mix.state.saleQueue[1].units==48 and mix.state.saleQueue[2].units==168)
-- Expanded capacity and wallet reservations are checked before bag/carry writes.
for _,case in {{config={SaleCapacity=5},count=4,code='QueueFull'},{config={CoinCap=100},count=20,code='WalletFull'}} do
    local c,st=fixture(case.config);c:setEvent(st,150);st.state.depositCarry=25;bag(st,case.count)
    local before=st.state
    assert(deposit(c,st,'reject').code==case.code and st.state==before and st.state.bag[1].count==case.count and st.state.depositCarry==25)
    c:setPasses(st,{autoCollect=true,autoSell=true});before=st.state
    assert(not c:step(st,0) and st.state==before,'Automatic deposit rejection must preserve the bag and carry too')
end
-- Auto Collect/Auto Sell use exactly the manual deposit/claim accounting.
local manual,manualState=fixture();local auto,autoState=fixture()
for _,pair in {{manual,manualState},{auto,autoState}} do pair[1]:setEvent(pair[2],106);bag(pair[2],5280) end
auto:setPasses(autoState,{autoCollect=true,autoSell=true})
assert(deposit(manual,manualState,'manual').code=='OK' and auto:step(autoState,0))
assert(Economy.count(autoState.state.saleQueue)==5596 and autoState.state.depositCarry==manualState.state.depositCarry)
assert(manual:step(manualState,10000) and auto:step(autoState,10000))
assert(manual:dispatch(manualState,'Claim',{'claim'},{now=10000,alive=true,position={x=Config.ClaimX,y=0,z=Config.ClaimZ}}).code=='OK')
assert(manualState.state.coinUnits==autoState.state.coinUnits and autoState.state.coinUnits==5596*4)
-- Boosts apply once: event/obby no longer alter raw production; mini2 still does.
for _,pass in {false,true} do
    local c,st=fixture();c:setEvent(st,150);c:setObbyBonus(st,100);if pass then c:setPasses(st,{mini2=true}) end
    assert(c:step(st,Config.Interval))
    assert(#st.state.tokens==(if pass then 2 else 1))
    assert(Info.rate(Config,st.state,Catalog.tier_01)==(if pass then 2 else 1)/Config.Interval)
end
-- Persisted carries stay bounded and rebirth clears the resettable inventory fraction.
local invalid=core:snapshot(s);invalid.depositCarry=100;assert(not core:validate(invalid,s.owner))
invalid.depositCarry=-1;assert(not core:validate(invalid,s.owner))
invalid.depositCarry=false;assert(not core:validate(invalid,s.owner))
s.state.producers[1].speciesId='tier_06';s.state.coinUnits=Config.RebirthBase
assert(core:dispatch(s,'Rebirth',{'reset'},{now=0,alive=true,position={x=0,y=0,z=0}}).code=='OK' and s.state.depositCarry==0)
print('PASS deposit 5280x1.06, half/max fractions, species values, replay, rollback, automation parity, raw production and carry validation/reset')
