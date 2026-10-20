local Economy=require('../src/shared/Economy')
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local c=Core.new(Config,Catalog,function() return 1 end)
local s=c:newSession(1,0,'seamless')
local function call(action,id,x,z,extra,now)
    return c:dispatch(s,action,{id,table.unpack(extra or {})},{now=now or 20,alive=true,position={x=x,y=0,z=z}})
end
assert(Config.ProcessorCosts[1]==40,'First processor upgrade should cost $10')
assert(call('Buy','first',Config.BuyPads['1'],Config.BuyZ,{'1'},0).code=='OK')
assert(s.state.purchased==1)
s.state.coinUnits=100000
assert(call('Buy','second',Config.BuyPads['1'],Config.BuyZ,{'1'},0).code=='OK')
assert(s.state.coinUnits==99980 and s.state.purchased==2)
assert(call('AutoMerge','far',999,999).code=='TooFar')
assert(call('AutoMerge','merge',Config.MergeX,Config.MergeZ).code=='OK')
assert(#s.state.producers==1 and s.state.producers[1].speciesId=='tier_02')
assert(s.state.purchased==2,'Merging must not reset purchase cost')
assert(call('AutoMerge','merge',Config.MergeX,Config.MergeZ).replayed)
assert(call('AutoMerge','none',Config.MergeX,Config.MergeZ).code=='NoPairs')
assert(call('Buy','third',Config.BuyPads['1'],Config.BuyZ,{'1'}).code=='OK')
assert(s.state.coinUnits==99956,'Third TungTung costs $6')
assert(call('Buy','third',Config.BuyPads['1'],Config.BuyZ,{'1'}).replayed and s.state.purchased==3)
s.state.rebirths=1
assert(call('Buy','five',Config.BuyPads['5'],Config.BuyZ,{'5'}).code=='OK')
assert(s.state.coinUnits==99956-4*(7+8+9+10+11))
assert(call('AutoMerge','cascade',Config.MergeX,Config.MergeZ).code=='OK')
assert(#s.state.producers==1 and s.state.producers[1].speciesId=='tier_04')
c:step(s,26)
assert(#s.state.tokens>0)
assert(call('CollectNearby','transit',0,Config.TrayZ,nil,26).code=='NothingNearby')
assert(call('CollectNearby','distant',100,Config.TrayZ,nil,31).code=='NothingNearby')
local count=#s.state.tokens
assert(call('CollectNearby','aura',6,Config.TrayZ,nil,31).code=='OK')
assert(Economy.count(s.state.bag)==count and #s.state.tokens==0)
assert(call('CollectNearby','aura',6,Config.TrayZ,nil,31).replayed and Economy.count(s.state.bag)==count)
-- The complete configured tray is collected in one request from its center.
s.state.bag={}; s.state.tokens={}; s.state.producers={}
for i=1,math.ceil(Config.GroundCap/Config.GroundPerProducer) do table.insert(s.state.producers,{id='p'..i,speciesId='tier_01',slot=i,due=0}) end
for i=1,8 do c:step(s,40+i*6) end
assert(#s.state.tokens==Config.GroundCap)
local collected=call('CollectNearby','full-pile',0,Config.TrayZ,nil,100)
assert(collected.code=='OK' and collected.count==Config.GroundCap)
assert(Economy.count(s.state.bag)==Config.GroundCap and #s.state.tokens==0)
c:step(s,106)
s.state.bag={{speciesId='tier_01',baseCoinValue=2,count=Config.BagCap}}
assert(call('CollectNearby','full-bag',0,Config.TrayZ,nil,111).code=='BagFull')
assert(#s.state.tokens>0)
s.state.bag={{speciesId='tier_01',baseCoinValue=2,count=1000000}}
local before=s.state.coinUnits
assert(call('Deposit','million',Config.SellX,Config.SellZ,nil,112).code=='OK')
assert(Economy.count(s.state.saleQueue)==1000000 and #s.state.saleQueue==1)
c:step(s,113)
assert(s.state.soldUnits==2*10 and Economy.count(s.state.saleQueue)==999998)
c:step(s,500112)
assert(Economy.count(s.state.saleQueue)==0 and s.state.soldUnits==10000000)
assert(call('Claim','million-cash',Config.ClaimX,Config.ClaimZ,nil,500112).code=='OK')
assert(s.state.coinUnits==before+10000000)
s.state.producers[1].speciesId='tier_06'; s.state.coinUnits=Config.RebirthBase+Config.RebirthStep
assert(call('Rebirth','rebirth',0,Config.MergeZ).code=='OK')
assert(s.state.purchased==0,'Rebirth resets purchase curve')
print('PASS rising prices, bulk sum, merge-all cascade/replay/distance, aura batch/transit/capacity and rebirth reset')
