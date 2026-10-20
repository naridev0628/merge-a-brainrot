local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')
local Info=require('../src/shared/ProductionInfo')
local Packet=require('../src/server/Domain/SnapshotPacket')

assert(Config.MaxTier==25,'All existing and newly requested characters must join the playable progression')
assert(Config.MergeCount==3)
assert(Config.BagCap*250+99<2^53,'Deposit scaling and fractional carry must remain exact integers')
assert(Config.SaleCapacity*24*8<=Config.CoinCap,'A full queue at maximum value must fit an empty wallet')
assert(Config.CoinCap<2^53,'Every accepted wallet or combined reserve must remain exact')
local precise=Economy.depositQuote(Config,{
    bag={{speciesId='tier_25',baseCoinValue=1,count=Config.BagCap-1}},
    saleQueue={},coinUnits=0,soldUnits=0,eventHundredths=150,obbyBonusHundredths=100,
    rebirths=20,cashMultiplier=8,depositCarry=99,
})
assert(precise.code=='OK' and precise.depositedCount==37499999999998 and precise.nextCarry==49,
    'Large odd quantities must preserve fractional Mini carry exactly')
assert(precise.creditUnits==7199999999999616)
local boundary={
    bag={{speciesId='tier_25',baseCoinValue=1,count=Config.BagCap}},
    saleQueue={},coinUnits=Config.CoinCap-Config.SaleCapacity*192,soldUnits=0,
    eventHundredths=150,obbyBonusHundredths=100,rebirths=20,cashMultiplier=8,depositCarry=0,
}
assert(Economy.depositQuote(Config,boundary).code=='OK','An exact wallet-cap reserve must fit')
boundary.coinUnits+=1
assert(Economy.depositQuote(Config,boundary).code=='WalletFull','One quarter-dollar beyond the cap must reject exactly')
boundary.coinUnits=Config.CoinCap
assert(Economy.depositQuote(Config,boundary).code=='WalletFull',
    'Oversized rejected sums beyond 2^53 must never be accepted or committed')
local config=table.clone(Config)
config.TransitSeconds=0; config.ProcessorRates=nil; config.SaleSeconds=0
local core=Core.new(config,Catalog,function() return 1 end)
local function session(tier)
    local s=core:newSession(1,0,'quantity-'..tier)
    s.state.starterClaimed=true
    s.state.producers={{id='producer',speciesId=string.format('tier_%02d',tier),slot=1,due=1}}
    return s
end
for tier=1,Config.MaxTier do
    local species=Catalog[string.format('tier_%02d',tier)]
    assert(species and species.tier==tier)
    local reference={1,5,25,90,300,1100,4000,15000,60000}
    if reference[tier] then
        assert(species.production==reference[tier],'Preserve every verified reference quantity')
    else
        local previous=Catalog[string.format('tier_%02d',tier-1)].production
        assert(species.production%1000==0 and species.production/previous>3.19 and species.production/previous<3.21,
            'Inferred later quantities should provide a modest gain over the three merged inputs')
    end
    assert(species.value==1,'Tier improves quantity, never multiplies the value of each Mini again')
    assert(Info.rate(Config,{},species)==species.production)
    if tier<Config.MaxTier then
        assert(Catalog[species.nextId].production>=Config.MergeCount*species.production,'Merging three producers must not reduce output')
    else assert(species.nextId==nil) end
    local s=session(tier)
    assert(core:step(s,1) and #s.state.tokens==1,'Each cycle creates one bounded visual bundle')
    local token=s.state.tokens[1]
    assert(token.count==species.production and token.baseCoinValue==1)
    assert(Packet.build(s,{id=1,frame=false},1,{}).tokens[1].count==species.production,'Transport preserves bundle quantity')
    local result=core:dispatch(s,'Collect',{token.id},{now=1,alive=true,position=token})
    assert(result.code=='OK' and result.count==species.production)
    assert(Economy.count(s.state.bag)==species.production)
    assert(core:dispatch(s,'Deposit',{'deposit'},{now=1,alive=true,position={x=config.SellX,y=0,z=config.SellZ}}).code=='OK')
    assert(Economy.count(s.state.saleQueue)==species.production and s.state.saleQueue[1].units==4)
    core:step(s,1)
    assert(s.state.soldUnits==4*species.production,'Deposit must preserve quantity without squaring tier value')
    local boosted=session(tier)
    boosted.state.miniMultiplier=2;boosted.state.eventHundredths=150;boosted.state.obbyBonusHundredths=100
    boosted.state.cashMultiplier=8;boosted.state.rebirths=20
    assert(core:step(boosted,1) and #boosted.state.tokens==2,'Mini2 keeps counted physical bundles bounded')
    while #boosted.state.tokens>0 do
        local item=boosted.state.tokens[1]
        assert(core:dispatch(boosted,'Collect',{item.id},{now=1,alive=true,position=item}).code=='OK',
            'Every boosted cycle must fit the bag')
    end
    assert(Economy.count(boosted.state.bag)==species.production*2)
    local deposited=core:dispatch(boosted,'Deposit',{'boosted'},{now=1,alive=true,position={x=config.SellX,y=0,z=config.SellZ}})
    assert(deposited.code=='OK' and deposited.depositedCount==species.production*5,'Maximum event/obby deposit must fit')
    assert(Economy.count(boosted.state.saleQueue)==species.production*5)
    assert(Packet.build(boosted,{id=1,frame=false},1,{}).saleQueue[1].count==species.production*5,
        'Counts beyond 32 bits must survive transport unchanged')
    core:step(boosted,1)
    assert(boosted.state.soldUnits==species.production*5*24*8,'Maximum cash/rebirth value must remain exact')
    assert(core:validate(boosted.state,boosted.owner))
end
local nearby=session(3)
core:step(nearby,1)
local token=nearby.state.tokens[1]
local picked=core:dispatch(nearby,'CollectNearby',{'nearby'},{now=1,alive=true,position=token,pickupPosition=token})
assert(picked.code=='OK' and picked.count==25 and picked.counts.tier_03==25)
assert(core:dispatch(nearby,'CollectNearby',{'nearby'},{now=1,alive=true,position=token,pickupPosition=token}).replayed)
assert(Economy.count(nearby.state.bag)==25,'Replay must not duplicate bundled Minis')
local auto=session(Config.MaxTier)
core:setPasses(auto,{autoCollect=true,cash2=true})
assert(core:step(auto,1) and #auto.state.tokens==0)
assert(Economy.count(auto.state.saleQueue)==Catalog[string.format('tier_%02d',Config.MaxTier)].production)
core:step(auto,1)
assert(auto.state.soldUnits==Catalog[string.format('tier_%02d',Config.MaxTier)].production*8,'AutoCollect preserves quantity and cash pass applies once')
local capConfig=table.clone(config); capConfig.BagCap=9
local capped=Core.new(capConfig,Catalog,function() return 1 end)
local full=session(3)
capped:step(full,1); local fullToken=full.state.tokens[1]
assert(capped:dispatch(full,'Collect',{fullToken.id},{now=1,alive=true,position=fullToken}).code=='BagFull')
assert(#full.state.tokens==1 and #full.state.bag==0,'Insufficient room must leave the whole bundle intact')
capped:setPasses(full,{autoCollect=true})
capped:step(full,1.25)
assert(#full.state.tokens==1 and #full.state.bag==0,'AutoCollect must also respect the whole-bundle capacity')
assert(Config.ProcessorRates[#Config.ProcessorRates]>=Catalog[string.format('tier_%02d',Config.MaxTier)].production*5,
    'Maximum processor must cover one top-tier producer with Mini2 and max deposit bonus')
assert(#Config.ProcessorRates==#Config.ProcessorCosts+1)
-- A full top-tier tray contains more logical Minis than the bag can hold.
-- Only complete bundles that fit may move; the rest must remain collectible.
local large=core:newSession(7,0,'large-quantity')
large.state.starterClaimed=true
local topId=string.format('tier_%02d',Config.MaxTier)
for slot=1,50 do
    large.state.producers[slot]={id='top'..slot,speciesId=topId,slot=slot,due=1}
end
core:step(large,1);core:step(large,2)
assert(#large.state.tokens==96)
local totalQuantity=Economy.count(large.state.tokens)
assert(totalQuantity>Config.BagCap)
local result=core:dispatch(large,'CollectNearby',{'bulk'},{now=2,alive=true,
    position={x=0,y=3,z=Config.TrayZ},pickupPosition={x=0,y=3,z=Config.TrayZ}})
assert(result.code=='OK' and result.count<=Config.BagCap)
assert(#large.state.tokens>0 and Economy.count(large.state.bag)+Economy.count(large.state.tokens)==totalQuantity,
    'High-tier capacity must preserve every remaining bundle and every collected Mini')
assert(core:dispatch(large,'Deposit',{'bulk-deposit'},{now=2,alive=true,
    position={x=Config.SellX,y=0,z=Config.SellZ}}).code=='OK')
assert(#large.state.saleQueue==1 and Economy.count(large.state.saleQueue)==result.count,
    'Billions of Minis must stay in a single counted sales batch')
assert(core:validate(large.state,large.owner))
print('PASS all 25 tier quantities, merge output, bounded drops, wire quantities, manual/aura/auto collection and exact sales')
