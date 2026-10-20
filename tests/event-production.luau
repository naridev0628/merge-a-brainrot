local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')
local c=Core.new(Config,Catalog,function()return 1 end)
local s=c:newSession(1,0,'event')
local function buy(id,q,now)
    return c:dispatch(s,'Buy',{id,q},{now=now or 0,alive=true,position={x=Config.BuyPads[q],y=0,z=Config.BuyZ}})
end
assert(buy('first','1').code=='OK')
c:setEvent(s,50)
c:step(s,1*Config.Interval);assert(#s.state.tokens==0 and s.state.producers[1].productionCredit==50)
c:step(s,2*Config.Interval);assert(#s.state.tokens==1 and s.state.producers[1].productionCredit==0)
c:setEvent(s,150);s.state.tokens={}
c:step(s,3*Config.Interval);assert(#s.state.tokens==1)
c:step(s,4*Config.Interval);assert(#s.state.tokens==3)
c:setPasses(s,{mini2=true});s.state.tokens={}
c:step(s,5*Config.Interval);assert(#s.state.tokens==3,'2x pass multiplies event without rounding loss')
s.state.coinUnits=1000000
assert(buy('five','5',31).code=='OK' and buy('ten','10',31).code=='OK','5 and10 never require rebirth')
assert(buy('locked','50',31).code=='Locked')
s.state.rebirths=2
local before=s.state.coinUnits;local purchased=s.state.purchased;local amount=50-#s.state.producers
assert(buy('tier2','50',31).code=='OK')
assert(s.state.coinUnits==before-Economy.buyCost(purchased,amount,2))
assert(s.state.producers[50].speciesId=='tier_02' and #s.state.producers==50)
assert(buy('tier2','50',31).replayed and #s.state.producers==50)
print('PASS fractional event production, pass stacking, unlocked Buy5/10 and rebirth-tier Buy50')
